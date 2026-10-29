import type { JourneyInfo } from './transit';
import { journeyMainDestination, journeyMainLine } from './transit';

/**
 * A journey the user committed to, kept visible even when the SL API's 3-trip
 * window slides past it. Stored per-device (not encrypted).
 */
export interface PinnedJourney {
  originId: string;
  destId: string;
  /** Scheduled departure time-of-day, "HH:MM". */
  timeOfDay: string;
  line: string | null;
  destination: string | null;
  durationMinutes: number;
  /** Local date the pin belongs to; auto-expires the next day. */
  pinnedDate: string;
}

export function timeOfDay(date: Date): string {
  return `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`;
}

export function pinFromJourney(
  journey: JourneyInfo,
  originId: string,
  destId: string,
  pinnedDate: string,
): PinnedJourney {
  return {
    originId,
    destId,
    timeOfDay: timeOfDay(journey.departureTime),
    line: journeyMainLine(journey),
    destination: journeyMainDestination(journey),
    durationMinutes: journey.durationMinutes,
    pinnedDate,
  };
}

/** A live journey matches the pin on scheduled departure time and line. */
export function journeyMatchesPin(journey: JourneyInfo, pin: PinnedJourney): boolean {
  return timeOfDay(journey.departureTime) === pin.timeOfDay && journeyMainLine(journey) === pin.line;
}

export function pinIsExpired(pin: PinnedJourney, today: string): boolean {
  return pin.pinnedDate !== today;
}

export function pinBelongsToRoute(pin: PinnedJourney, originId: string, destId: string): boolean {
  return pin.originId === originId && pin.destId === destId;
}
