import { useEffect, useState } from 'react';

import { useT } from '../i18n';
import type { StationInfo } from '../lib/domain/transit';
import { useStopSearch } from '../queries/transit';
import { Input, Label } from './ui';

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
      <Label>{label}</Label>
      <Input
        aria-label={label}
        value={query}
        placeholder={selected?.name ?? t('Search station')}
        onChange={(event) => setQuery(event.target.value)}
      />
      {showResults ? (
        <ul className="max-h-48 overflow-auto rounded-lg border border-input bg-background">
          {stops.data!.map((station) => (
            <li key={station.id}>
              <button
                type="button"
                className="w-full px-3 py-2 text-left text-sm text-foreground hover:bg-accent"
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
      {selected ? <p className="text-xs text-muted-foreground">{selected.name}</p> : null}
    </div>
  );
}
