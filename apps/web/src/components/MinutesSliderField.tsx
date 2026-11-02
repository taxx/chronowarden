import type { Control, FieldPath, FieldValues } from 'react-hook-form';

import { formatDurationMinutes } from '../lib/format';
import { FormControl, FormField, FormItem, FormLabel, FormMessage, Slider } from './ui';

/**
 * A labelled minute slider wired into react-hook-form.
 *
 * Kept visually consistent with the active-day adjustment sliders: label on the
 * left, formatted duration on the right, slider underneath. Sliders always span
 * both columns so they stay easy to grab on desktop and mobile.
 */
export function MinutesSliderField<T extends FieldValues>({
  control,
  name,
  label,
  min = 0,
  max = 240,
  step = 5,
}: {
  control: Control<T>;
  name: FieldPath<T>;
  label: string;
  min?: number;
  max?: number;
  step?: number;
}) {
  return (
    <FormField
      control={control}
      name={name}
      render={({ field }) => {
        const value = Number(field.value) || 0;
        return (
          <FormItem className="sm:col-span-2">
            <div className="flex items-baseline justify-between gap-3">
              <FormLabel>{label}</FormLabel>
              <span className="text-sm font-medium tabular-nums text-muted-foreground">
                {formatDurationMinutes(value)}
              </span>
            </div>
            <FormControl>
              <Slider
                value={value}
                min={min}
                max={max}
                step={step}
                onChange={(next) => field.onChange(String(next))}
              />
            </FormControl>
            <FormMessage />
          </FormItem>
        );
      }}
    />
  );
}
