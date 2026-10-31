import { CalendarIcon } from 'lucide-react';
import { useState } from 'react';

import { cn } from '@/lib/utils';
import { Button } from './button';
import { Calendar } from './calendar';
import { Popover, PopoverContent, PopoverTrigger } from './popover';

/** A themed date picker button (Popover + Calendar). */
export function DatePicker({
  id,
  value,
  onChange,
  className,
}: {
  id?: string;
  value: string;
  onChange: (date: string) => void;
  className?: string;
}) {
  const [open, setOpen] = useState(false);
  const label = value
    ? new Intl.DateTimeFormat(undefined, { dateStyle: 'medium' }).format(new Date(`${value}T00:00:00`))
    : '';

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button
          id={id}
          type="button"
          variant="outline"
          className={cn('w-full justify-start text-left font-normal', className)}
        >
          <CalendarIcon className="h-4 w-4 opacity-70" />
          {label || <span className="text-muted-foreground">—</span>}
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-auto">
        <Calendar
          value={value}
          onChange={(date) => {
            onChange(date);
            setOpen(false);
          }}
        />
      </PopoverContent>
    </Popover>
  );
}
