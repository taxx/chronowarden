import { ChevronLeft, ChevronRight } from 'lucide-react';
import { useState } from 'react';

import { cn } from '@/lib/utils';
import { Button } from './button';

const WEEKDAYS = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

function toDateStr(date: Date): string {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
}

/** Small themed month calendar (Monday-first) used by the date picker. */
export function Calendar({
  value,
  onChange,
  className,
}: {
  value: string;
  onChange: (date: string) => void;
  className?: string;
}) {
  const selected = value ? new Date(`${value}T00:00:00`) : new Date();
  const [cursor, setCursor] = useState(() => new Date(selected.getFullYear(), selected.getMonth(), 1));

  const first = new Date(cursor.getFullYear(), cursor.getMonth(), 1);
  const offset = (first.getDay() + 6) % 7; // Monday = 0
  const today = toDateStr(new Date());

  const cells: Array<{ date: string; day: number; inMonth: boolean }> = [];
  for (let i = 0; i < 42; i += 1) {
    const date = new Date(cursor.getFullYear(), cursor.getMonth(), i - offset + 1);
    cells.push({
      date: toDateStr(date),
      day: date.getDate(),
      inMonth: date.getMonth() === cursor.getMonth(),
    });
  }

  const label = new Intl.DateTimeFormat(undefined, { month: 'long', year: 'numeric' }).format(cursor);

  return (
    <div className={cn('w-64 p-3', className)}>
      <div className="mb-2 flex items-center justify-between">
        <Button
          type="button"
          variant="ghost"
          size="icon"
          aria-label="Previous month"
          className="h-7 w-7"
          onClick={() => setCursor(new Date(cursor.getFullYear(), cursor.getMonth() - 1, 1))}
        >
          <ChevronLeft className="h-4 w-4" />
        </Button>
        <span className="text-sm font-medium capitalize">{label}</span>
        <Button
          type="button"
          variant="ghost"
          size="icon"
          aria-label="Next month"
          className="h-7 w-7"
          onClick={() => setCursor(new Date(cursor.getFullYear(), cursor.getMonth() + 1, 1))}
        >
          <ChevronRight className="h-4 w-4" />
        </Button>
      </div>

      <div className="grid grid-cols-7 gap-0.5 text-center">
        {WEEKDAYS.map((day) => (
          <span key={day} className="py-1 text-[11px] uppercase text-muted-foreground">
            {day}
          </span>
        ))}
        {cells.map((cell) => {
          const isSelected = cell.date === value;
          const isToday = cell.date === today;
          return (
            <button
              key={cell.date}
              type="button"
              onClick={() => onChange(cell.date)}
              className={cn(
                'grid h-8 w-8 place-items-center rounded-md text-sm transition',
                cell.inMonth ? 'text-foreground' : 'text-muted-foreground/50',
                isSelected
                  ? 'bg-primary text-primary-foreground'
                  : 'hover:bg-accent',
                !isSelected && isToday && 'ring-1 ring-inset ring-primary/50',
              )}
            >
              {cell.day}
            </button>
          );
        })}
      </div>
    </div>
  );
}
