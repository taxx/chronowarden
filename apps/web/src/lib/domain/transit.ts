/**
 * SL Journey Planner models (from the slimmed `sl/proxy` response).
 * Ported from `apps/web/lib/models/{station_info,journey_info}.dart`.
 */

export interface StationInfo {
  id: string;
  name: string;
  siteId: number | null;
}

export function stationFromStopFinder(json: Record<string, any>): StationInfo {
  const props = json['properties'] as Record<string, unknown> | undefined;
  const stopIdRaw = props?.['stopId'];
  const parsed = typeof stopIdRaw === 'string' ? Number.parseInt(stopIdRaw, 10) : NaN;
  return {
    id: (json['id'] as string | null) ?? '',
    name: (json['name'] as string | null) ?? (json['disassembledName'] as string | null) ?? 'Unknown',
    siteId: Number.isFinite(parsed) && parsed > 0 ? parsed : null,
  };
}

export type LegType = 'transport' | 'walk';

export interface LegInfo {
  type: LegType;
  durationMinutes: number;
  line?: string;
  destination?: string;
  transportMode?: string;
  departurePlatform?: string;
  occupancy?: string;
  delayMinutes?: number;
}

export interface JourneyInfo {
  departureTime: Date;
  departureEstimated: Date;
  arrivalTime: Date;
  arrivalEstimated: Date;
  durationMinutes: number;
  rtDurationMinutes: number;
  legs: LegInfo[];
}

function legFromJson(json: Record<string, any>): LegInfo {
  return {
    type: json['type'] === 'transport' ? 'transport' : 'walk',
    durationMinutes: (json['duration_minutes'] as number | null) ?? 0,
    line: (json['line'] as string | undefined) ?? undefined,
    destination: (json['destination'] as string | undefined) ?? undefined,
    transportMode: (json['transport_mode'] as string | undefined) ?? undefined,
    departurePlatform: (json['departure_platform'] as string | undefined) ?? undefined,
    occupancy: (json['occupancy'] as string | undefined) ?? undefined,
    delayMinutes: (json['delay_minutes'] as number | undefined) ?? undefined,
  };
}

export function journeyFromJson(json: Record<string, any>): JourneyInfo {
  const departureTime = new Date(json['departure_time'] as string);
  const arrivalTime = new Date(json['arrival_time'] as string);
  return {
    departureTime,
    departureEstimated: new Date((json['departure_estimated'] as string) ?? json['departure_time']),
    arrivalTime,
    arrivalEstimated: new Date((json['arrival_estimated'] as string) ?? json['arrival_time']),
    durationMinutes: (json['duration_minutes'] as number | null) ?? 0,
    rtDurationMinutes: (json['rt_duration_minutes'] as number | null) ?? 0,
    legs: ((json['legs'] as Record<string, any>[] | undefined) ?? []).map(legFromJson),
  };
}

export function departureDelayMinutes(journey: JourneyInfo): number {
  const diff = Math.round(
    (journey.departureEstimated.getTime() - journey.departureTime.getTime()) / 60_000,
  );
  return diff > 0 ? diff : 0;
}

export function journeyDelayLabel(journey: JourneyInfo): string {
  const delay = departureDelayMinutes(journey);
  return delay <= 0 ? 'On time' : `+${delay} min`;
}

function firstTransportLeg(journey: JourneyInfo): LegInfo | null {
  return journey.legs.find((leg) => leg.type === 'transport') ?? null;
}

export function journeyMainLine(journey: JourneyInfo): string | null {
  return firstTransportLeg(journey)?.line ?? null;
}

export function journeyMainDestination(journey: JourneyInfo): string | null {
  return firstTransportLeg(journey)?.destination ?? null;
}

export function journeyDeparturePlatform(journey: JourneyInfo): string | null {
  return firstTransportLeg(journey)?.departurePlatform ?? null;
}

export function journeyOccupancy(journey: JourneyInfo): string | null {
  return firstTransportLeg(journey)?.occupancy ?? null;
}

export function journeyTransportMode(journey: JourneyInfo): string | null {
  return firstTransportLeg(journey)?.transportMode ?? null;
}

/** Number of changes (transport legs − 1). */
export function journeyTransferCount(journey: JourneyInfo): number {
  const transportLegs = journey.legs.filter((leg) => leg.type === 'transport').length;
  return Math.max(0, transportLegs - 1);
}

/** Morning before 11:00 → home → work; otherwise work → home. */
export function isMorning(date: Date): boolean {
  return date.getHours() < 11;
}
