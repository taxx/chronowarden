import type { JourneyInfo } from './transit';

/**
 * Leave-time status for a journey, ported from the Flutter `journey_tile.dart`.
 *
 * The crucial bit for "when do I leave the office" is that a journey is only
 * catchable if you can still start walking now; the walk buffer is subtracted
 * from the scheduled departure.
 */

export type JourneyStatusKind = 'leave' | 'departs' | 'departed' | 'missed';

export interface JourneyStatus {
  kind: JourneyStatusKind;
  /** Still possible to catch this journey (with a one-minute grace). */
  catchable: boolean;
  /** When you must leave to make the scheduled departure. */
  leaveTime: Date;
  minutesUntilLeave: number;
  minutesUntilDeparture: number;
}

export function computeJourneyStatus(
  journey: JourneyInfo,
  now: Date,
  walkBufferMinutes: number,
  isPinned: boolean,
): JourneyStatus {
  const departure = journey.departureTime;
  const leaveTime = new Date(departure.getTime() - walkBufferMinutes * 60_000);
  const catchable = leaveTime.getTime() >= now.getTime() - 60_000;
  const minutesUntilLeave = Math.max(0, Math.round((leaveTime.getTime() - now.getTime()) / 60_000));
  const minutesUntilDeparture = Math.max(0, Math.round((departure.getTime() - now.getTime()) / 60_000));

  let kind: JourneyStatusKind;
  if (isPinned) {
    // A committed journey never shows "missed"; it counts down to departure,
    // then falls back to a neutral "departed".
    if (catchable) kind = 'leave';
    else if (minutesUntilDeparture > 0) kind = 'departs';
    else kind = 'departed';
  } else {
    kind = catchable ? 'leave' : 'missed';
  }

  return { kind, catchable, leaveTime, minutesUntilLeave, minutesUntilDeparture };
}

/**
 * Direction for the transit views. An active day always points home; before
 * 11:00 without an active day it points to work, after 11:00 to home.
 */
export function isMorningCommute(
  now: Date,
  log: { endTime?: string | null } | null | undefined,
): boolean {
  const active = log != null && log.endTime == null;
  if (active) return false;
  return now.getHours() < 11;
}
