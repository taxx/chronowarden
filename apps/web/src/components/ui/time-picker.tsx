import { Clock } from 'lucide-react';
import { useEffect, useRef, useState, type PointerEvent as ReactPointerEvent } from 'react';

import { useT } from '@/i18n';
import { cn } from '@/lib/utils';
import { Button } from './button';
import { Popover, PopoverContent, PopoverTrigger } from './popover';

/**
 * A 24-hour clock-dial time picker (Material/Android style).
 *
 * Two dial steps: pick the hour from a double ring (0–11 inner, 12–23 outer),
 * then the minute from a five-minute ring with free dragging for exact minutes.
 * Always 24-hour, themed with the app tokens, and no third-party dependency.
 */

const DIAL_SIZE = 224;
const OUTER_RADIUS = 92;
const INNER_RADIUS = 60;
const HOURS = Array.from({ length: 24 }, (_, i) => i);
const MINUTE_MARKS = Array.from({ length: 12 }, (_, i) => i * 5);

function pad(value: number): string {
  return String(value).padStart(2, '0');
}

/** Parse `HH:MM` (tolerating seconds); falls back to 08:00. */
function parseTime(value: string): { hour: number; minute: number } {
  const match = /^(\d{1,2}):(\d{2})/.exec(value ?? '');
  if (!match) return { hour: 8, minute: 0 };
  return {
    hour: Math.min(23, Math.max(0, Number(match[1]))),
    minute: Math.min(59, Math.max(0, Number(match[2]))),
  };
}

/** Coordinates on the dial, with 0° pointing up and increasing clockwise. */
function pointAt(radius: number, angleDeg: number): { x: number; y: number } {
  const rad = (angleDeg * Math.PI) / 180;
  return { x: Math.round(radius * Math.sin(rad)), y: Math.round(-radius * Math.cos(rad)) };
}

function offsetPx(value: number): string {
  return `${value >= 0 ? '+' : '-'} ${Math.abs(value)}px`;
}

export function TimePicker({
  id,
  value,
  onChange,
  placeholder = '--:--',
  className,
}: {
  id?: string;
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  className?: string;
}) {
  const t = useT();
  const [open, setOpen] = useState(false);
  const [mode, setMode] = useState<'hour' | 'minute'>('hour');
  const [hour, setHour] = useState(() => parseTime(value).hour);
  const [minute, setMinute] = useState(() => parseTime(value).minute);
  const faceRef = useRef<HTMLDivElement>(null);
  const dragging = useRef(false);

  useEffect(() => {
    if (!open) return;
    const parsed = parseTime(value);
    setHour(parsed.hour);
    setMinute(parsed.minute);
    setMode('hour');
  }, [open, value]);

  function commit() {
    onChange(`${pad(hour)}:${pad(minute)}`);
    setOpen(false);
  }

  function pickFromPointer(event: ReactPointerEvent<HTMLDivElement>) {
    const face = faceRef.current;
    if (!face) return;
    const rect = face.getBoundingClientRect();
    const dx = event.clientX - (rect.left + rect.width / 2);
    const dy = event.clientY - (rect.top + rect.height / 2);
    const distance = Math.hypot(dx, dy);
    let angle = (Math.atan2(dy, dx) * 180) / Math.PI + 90;
    if (angle < 0) angle += 360;
    if (mode === 'hour') {
      const index = Math.round(angle / 30) % 12;
      // Inner ring (0–11) vs outer ring (12–23), split between the two radii.
      const outer = distance > (INNER_RADIUS + OUTER_RADIUS) / 2;
      setHour(outer ? index + 12 : index);
    } else {
      setMinute(Math.round(angle / 6) % 60);
    }
  }

  const handAngle = mode === 'hour' ? (hour % 12) * 30 : minute * 6;
  // Stop short of the number badges so the hand never covers the selection.
  const handLength = (mode === 'hour' && hour < 12 ? INNER_RADIUS : OUTER_RADIUS) - 18;
  // A dragged minute between the five-minute marks has no badge of its own, so
  // we render a marker for it at the exact angle (keeping it visible/clickable
  // like a normal selected mark).
  const minuteOffMark = minute % 5 !== 0;
  const minutePoint = pointAt(OUTER_RADIUS, minute * 6);

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button
          id={id}
          type="button"
          variant="outline"
          className={cn('w-full justify-start text-left font-normal', className)}
        >
          <Clock className="h-4 w-4 opacity-70" />
          {value ? value.slice(0, 5) : <span className="text-muted-foreground">{placeholder}</span>}
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-auto p-4" align="start">
        <div className="flex flex-col items-center gap-4">
          {/* Digital display doubles as the hour/minute mode switch. */}
          <div className="flex items-baseline gap-1 font-mono text-3xl font-semibold tabular-nums">
            <button
              type="button"
              onClick={() => setMode('hour')}
              aria-label={t('Hours')}
              className={cn(
                'rounded-md px-2 py-0.5 transition',
                mode === 'hour' ? 'bg-primary/10 text-primary' : 'hover:bg-accent',
              )}
            >
              {pad(hour)}
            </button>
            <span className="text-muted-foreground">:</span>
            <button
              type="button"
              onClick={() => setMode('minute')}
              aria-label={t('Minutes')}
              className={cn(
                'rounded-md px-2 py-0.5 transition',
                mode === 'minute' ? 'bg-primary/10 text-primary' : 'hover:bg-accent',
              )}
            >
              {pad(minute)}
            </button>
          </div>

          {/* Clock face */}
          <div
            ref={faceRef}
            data-testid="time-picker-face"
            className="relative touch-none select-none rounded-full bg-muted"
            style={{ width: DIAL_SIZE, height: DIAL_SIZE }}
            onPointerDown={(event) => {
              dragging.current = true;
              event.currentTarget.setPointerCapture(event.pointerId);
              pickFromPointer(event);
            }}
            onPointerMove={(event) => {
              if (dragging.current) pickFromPointer(event);
            }}
            onPointerUp={() => {
              dragging.current = false;
              // Like Android: picking the hour advances to the minute step.
              if (mode === 'hour') setMode('minute');
            }}
            onPointerCancel={() => {
              dragging.current = false;
            }}
          >
            {/* Hand */}
            <div
              className="pointer-events-none absolute z-10 w-0.5 bg-primary"
              style={{
                left: '50%',
                bottom: '50%',
                height: handLength,
                marginLeft: '-1px',
                transformOrigin: '50% 100%',
                transform: `rotate(${handAngle}deg)`,
              }}
            />
            <div className="pointer-events-none absolute left-1/2 top-1/2 z-10 h-2 w-2 -translate-x-1/2 -translate-y-1/2 rounded-full bg-primary" />

            {mode === 'minute' && minuteOffMark ? (
              <button
                type="button"
                onClick={() => setMinute(minute)}
                aria-label={pad(minute)}
                className="absolute z-20 flex h-7 w-7 -translate-x-1/2 -translate-y-1/2 items-center justify-center rounded-full bg-primary text-xs font-semibold text-primary-foreground transition"
                style={{
                  left: `calc(50% ${offsetPx(minutePoint.x)})`,
                  top: `calc(50% ${offsetPx(minutePoint.y)})`,
                }}
              >
                {pad(minute)}
              </button>
            ) : null}

            {mode === 'hour'
              ? HOURS.map((h) => {
                  const inner = h < 12;
                  const { x, y } = pointAt(
                    inner ? INNER_RADIUS : OUTER_RADIUS,
                    (inner ? h : h - 12) * 30,
                  );
                  const selected = h === hour;
                  return (
                    <button
                      key={h}
                      type="button"
                      onClick={() => {
                        setHour(h);
                        setMode('minute');
                      }}
                      aria-label={pad(h)}
                      className={cn(
                        'absolute flex h-7 w-7 -translate-x-1/2 -translate-y-1/2 items-center justify-center rounded-full text-xs font-semibold transition',
                        selected ? 'bg-primary text-primary-foreground' : 'hover:bg-accent',
                      )}
                      style={{ left: `calc(50% ${offsetPx(x)})`, top: `calc(50% ${offsetPx(y)})` }}
                    >
                      {h}
                    </button>
                  );
                })
              : MINUTE_MARKS.map((m) => {
                  const { x, y } = pointAt(OUTER_RADIUS, (m / 5) * 30);
                  const selected = m === minute;
                  return (
                    <button
                      key={m}
                      type="button"
                      onClick={() => setMinute(m)}
                      aria-label={pad(m)}
                      className={cn(
                        'absolute flex h-7 w-7 -translate-x-1/2 -translate-y-1/2 items-center justify-center rounded-full text-xs font-semibold transition',
                        selected ? 'bg-primary text-primary-foreground' : 'hover:bg-accent',
                      )}
                      style={{ left: `calc(50% ${offsetPx(x)})`, top: `calc(50% ${offsetPx(y)})` }}
                    >
                      {pad(m)}
                    </button>
                  );
                })}
          </div>

          <div className="flex w-full justify-end gap-2">
            <Button type="button" variant="ghost" size="sm" onClick={() => setOpen(false)}>
              {t('Cancel')}
            </Button>
            <Button type="button" size="sm" onClick={commit}>
              {t('Done')}
            </Button>
          </div>
        </div>
      </PopoverContent>
    </Popover>
  );
}
