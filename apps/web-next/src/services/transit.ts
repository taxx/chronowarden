import { slApi } from '../api/sl';
import { ApiError } from '../api/client';
import {
  journeyFromJson,
  stationFromStopFinder,
  type JourneyInfo,
  type StationInfo,
} from '../lib/domain/transit';
import {
  TransitFetchGuard,
  TRANSIT_NETWORK_ERROR_STATUS,
} from '../lib/domain/transit-guard';

/**
 * SL Journey Planner access: stops, journeys, caching and failure back-off.
 *
 * The requests go through the API's `/sl/proxy` route (same origin), which
 * slims the responses. Ported from the Flutter `TransitService`.
 */
const journeysCacheTtlMs = 60_000;

const guard = new TransitFetchGuard();

let cachedJourneys: JourneyInfo[] | null = null;
let cachedAt = 0;
let cachedKey: string | null = null;
let pending: Promise<JourneyInfo[] | null> | null = null;

export function transitAvailability(nowMs = Date.now()) {
  return guard.availability(nowMs);
}

export function transitBackoffRemainingMs(nowMs = Date.now()): number {
  return guard.remainingMs(nowMs);
}

export function transitLastError(): string | null {
  return guard.lastErrorMessage;
}

/** Explicit user retry: clear the back-off and the journey cache. */
export function transitRetryNow(): void {
  guard.reset();
  cachedJourneys = null;
  cachedAt = 0;
  cachedKey = null;
  pending = null;
}

export async function fetchStops(query: string): Promise<StationInfo[]> {
  const trimmed = query.trim();
  if (!trimmed) return [];

  const path = `/v2/stop-finder?name_sf=${encodeURIComponent(trimmed)}&type_sf=any&any_obj_filter_sf=2`;
  const data = await slApi.proxy<{ locations?: Record<string, any>[] }>(path);
  const locations = data?.locations ?? [];
  return locations
    .map(stationFromStopFinder)
    .filter((station) => station.id !== '')
    .sort((a, b) => a.name.localeCompare(b.name));
}

function toTransitError(error: unknown): { status: number; message: string; retryAfterMs: number | null } {
  if (error instanceof ApiError) {
    return { status: error.status, message: error.message, retryAfterMs: null };
  }
  return {
    status: TRANSIT_NETWORK_ERROR_STATUS,
    message: error instanceof Error ? error.message : String(error),
    retryAfterMs: null,
  };
}

/** Fetch 3 journeys between two stops, with coalescing, caching and back-off. */
export async function fetchJourneys(options: {
  originId: string;
  destId: string;
  walkOffsetMinutes?: number;
}): Promise<JourneyInfo[] | null> {
  const walkOffset = options.walkOffsetMinutes ?? 0;
  const key = `${options.originId}:${options.destId}:${walkOffset}`;

  if (cachedJourneys && cachedKey === key && Date.now() - cachedAt < journeysCacheTtlMs) {
    return cachedJourneys;
  }

  if (pending && cachedKey === key) return pending;

  if (!guard.canAttempt(Date.now())) {
    return cachedKey === key ? cachedJourneys : null;
  }

  const now = new Date();
  const queryTime = new Date(now.getTime() + walkOffset * 60_000);
  const itdTime = `${String(queryTime.getHours()).padStart(2, '0')}${String(queryTime.getMinutes()).padStart(2, '0')}`;
  const itdDate = `${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}${String(now.getDate()).padStart(2, '0')}`;

  const path =
    `/v2/trips?type_origin=any&name_origin=${options.originId}` +
    `&type_destination=any&name_destination=${options.destId}` +
    `&itd_date=${itdDate}&itd_time=${itdTime}` +
    `&calc_number_of_trips=3&calc_one_direction=true`;

  cachedKey = key;
  const run = (async () => {
    try {
      const data = await slApi.proxy<{ journeys?: Record<string, any>[] }>(path);
      const journeys = (data?.journeys ?? [])
        .map(journeyFromJson)
        .sort((a, b) => a.departureTime.getTime() - b.departureTime.getTime());
      cachedJourneys = journeys;
      cachedAt = Date.now();
      guard.recordSuccess();
      return journeys;
    } catch (error) {
      const info = toTransitError(error);
      guard.recordFailure(Date.now(), info);
      return cachedKey === key ? cachedJourneys : null;
    } finally {
      pending = null;
    }
  })();

  pending = run;
  return run;
}
