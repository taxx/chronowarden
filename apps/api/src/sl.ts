/**
 * SL Journey Planner proxy + response slimming.
 *
 * Served same-origin by the API, so no CORS handling is needed; only the
 * slimming and an optional API key remain. A small in-memory cache blunts
 * repeated identical queries.
 */
export interface SlimmedLeg {
  type: 'transport' | 'walk';
  duration_minutes: number;
  line?: string;
  destination?: string;
  transport_mode?: string;
  departure_platform?: string;
  occupancy?: string;
  delay_minutes?: number;
}

export interface SlimmedJourney {
  departure_time: string;
  departure_estimated: string;
  arrival_time: string;
  arrival_estimated: string;
  duration_minutes: number;
  rt_duration_minutes: number;
  legs: SlimmedLeg[];
}

const BASE_URL = 'https://journeyplanner.integration.sl.se';
const CACHE_TTL_MS = 30_000;

const cache = new Map<string, { at: number; body: string }>();

/** Fetches an SL path, returning the (slimmed, for /v2/trips) JSON text. */
export async function fetchSl(path: string, apiKey?: string): Promise<string> {
  const cached = cache.get(path);
  if (cached && Date.now() - cached.at < CACHE_TTL_MS) return cached.body;

  const headers: Record<string, string> = {
    Accept: 'application/json',
    'User-Agent': 'ChronoWarden/1.0 (self-hosted)',
  };
  if (apiKey) headers['X-Api-Key'] = apiKey;

  const response = await fetch(`${BASE_URL}${path}`, { method: 'GET', headers });
  const body = await response.text();

  if (!response.ok) {
    const error = new Error(`SL API returned ${response.status}: ${body.slice(0, 500)}`);
    (error as Error & { status?: number }).status = response.status;
    throw error;
  }

  let result = body;
  if (path.startsWith('/v2/trips')) {
    try {
      result = JSON.stringify(slimTripsResponse(body));
    } catch {
      result = body; // fall back to the raw response if slimming fails
    }
  }

  cache.set(path, { at: Date.now(), body: result });
  return result;
}

/** Slims a full /v2/trips response (~220 KB) down to essentials (~2 KB). */
export function slimTripsResponse(rawJson: string): object {
  const parsed = JSON.parse(rawJson);
  const journeys = parsed.journeys as any[] | undefined;

  if (!Array.isArray(journeys)) {
    return { systemMessages: parsed.systemMessages ?? [], journeys: [] };
  }

  const slimmed: SlimmedJourney[] = journeys.map((j: any) => {
    const legs = (j.legs as any[]) ?? [];
    const slimLegs: SlimmedLeg[] = legs.map((leg: any) => {
      const transport = leg.transportation ?? null;
      const origin = leg.origin ?? {};
      const destination = leg.destination ?? {};

      const isTransport = transport !== null;
      const type: SlimmedLeg['type'] = isTransport ? 'transport' : 'walk';

      let delayMinutes: number | undefined;
      if (isTransport && origin.departureTimePlanned && origin.departureTimeEstimated) {
        const planned = new Date(origin.departureTimePlanned).getTime();
        const estimated = new Date(origin.departureTimeEstimated).getTime();
        delayMinutes = Math.round((estimated - planned) / 60000);
        if (delayMinutes <= 0) delayMinutes = undefined;
      }

      let line: string | undefined;
      let destinationName: string | undefined;
      let transportMode: string | undefined;
      let occupancy: string | undefined;
      let departurePlatform: string | undefined;

      if (isTransport) {
        const name = (transport.name as string) ?? '';
        const match = name.match(/(\d+[A-Z]?)$/);
        line = match ? match[1] : ((transport.number as string) ?? '');

        const prod = transport.product ?? {};
        transportMode = mapProductClass((prod.class as number) ?? 0);

        const destObj = transport.destination ?? {};
        destinationName = (destObj.name as string) ?? '';

        const originProps = origin.properties ?? {};
        occupancy = (originProps.occupancy as string) ?? undefined;
        departurePlatform = (originProps.platformName as string) ?? undefined;
      }

      const durationSec = (leg.duration as number) ?? 0;

      return {
        type,
        duration_minutes: Math.round(durationSec / 60),
        ...(line ? { line } : {}),
        ...(destinationName ? { destination: destinationName } : {}),
        ...(transportMode ? { transport_mode: transportMode } : {}),
        ...(departurePlatform ? { departure_platform: departurePlatform } : {}),
        ...(occupancy ? { occupancy } : {}),
        ...(delayMinutes ? { delay_minutes: delayMinutes } : {}),
      };
    });

    const firstLeg = legs[0] ?? {};
    const lastLeg = legs[legs.length - 1] ?? {};
    const firstOrigin = firstLeg.origin ?? {};
    const lastDest = lastLeg.destination ?? {};

    const departurePlanned = firstOrigin.departureTimePlanned ?? '';
    const departureEstimated = firstOrigin.departureTimeEstimated ?? departurePlanned;
    const arrivalPlanned = lastDest.arrivalTimePlanned ?? '';
    const arrivalEstimated = lastDest.arrivalTimeEstimated ?? arrivalPlanned;

    const tripDuration = (j.tripDuration as number) ?? 0;
    const tripRtDuration = (j.tripRtDuration as number) ?? 0;

    return {
      departure_time: departurePlanned,
      departure_estimated: departureEstimated,
      arrival_time: arrivalPlanned,
      arrival_estimated: arrivalEstimated,
      duration_minutes: Math.round(tripDuration / 60),
      rt_duration_minutes: Math.round(tripRtDuration / 60),
      legs: slimLegs,
    };
  });

  return {
    systemMessages: parsed.systemMessages ?? [],
    journeys: slimmed,
  };
}

/** Maps an SL product class to a human-readable transport mode. */
export function mapProductClass(classId: number): string {
  switch (classId) {
    case 0:
      return 'TRAIN';
    case 2:
      return 'METRO';
    case 4:
      return 'TRAM';
    case 5:
      return 'BUS';
    case 9:
      return 'FERRY';
    case 10:
      return 'ON_DEMAND';
    default:
      return 'OTHER';
  }
}
