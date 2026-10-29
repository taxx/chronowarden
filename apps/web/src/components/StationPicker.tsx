import { useEffect, useState } from 'react';

import { useT } from '../i18n';
import type { StationInfo } from '../lib/domain/transit';
import { useStopSearch } from '../queries/transit';
import { Input } from './ui';

/** Debounced SL stop-finder autocomplete. */
export function StationPicker({
  label,
  selected,
  onSelect,
}: {
  label: string;
  selected: StationInfo | null;
  onSelect: (station: StationInfo) => void;
}) {
  const t = useT();
  const [query, setQuery] = useState('');
  const [debounced, setDebounced] = useState('');

  useEffect(() => {
    const id = setTimeout(() => setDebounced(query), 300);
    return () => clearTimeout(id);
  }, [query]);

  const stops = useStopSearch(debounced);
  const showResults = query.trim().length >= 2 && (stops.data?.length ?? 0) > 0;

  return (
    <div className="space-y-1.5">
      <span className="block text-sm font-medium text-slate-300">{label}</span>
      <Input
        aria-label={label}
        value={query}
        placeholder={selected?.name ?? t('Search station')}
        onChange={(event) => setQuery(event.target.value)}
      />
      {showResults ? (
        <ul className="max-h-48 overflow-auto rounded-lg border border-slate-700 bg-slate-950">
          {stops.data!.map((station) => (
            <li key={station.id}>
              <button
                type="button"
                className="w-full px-3 py-2 text-left text-sm text-slate-200 hover:bg-slate-800"
                onClick={() => {
                  onSelect(station);
                  setQuery('');
                }}
              >
                {station.name}
              </button>
            </li>
          ))}
        </ul>
      ) : null}
      {selected ? <p className="text-xs text-slate-500">{selected.name}</p> : null}
    </div>
  );
}
