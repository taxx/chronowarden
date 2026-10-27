// Edge Function: sl-proxy
// Proxies requests to SL Journey Planner API to avoid CORS issues from Flutter Web.
// Also slims down the verbose /v2/trips response to a minimal model.
//
// Supported paths:
//   /v2/stop-finder?name_sf=...    — SL Journey Planner: search stops
//   /v2/trips?name_origin=...      — SL Journey Planner: plan trips (slimmed)
//
// Usage:
//   POST /functions/v1/sl-proxy
//   Body: { "path": "/v2/trips?name_origin=...&name_destination=..." }
//
// Protections against hammering the upstream SL API:
//   1. Short in-memory cache per parsed path (CACHE_TTL_MS) — identical requests
//      from multiple tabs/devices within the window hit SL once.
//   2. A token bucket rate limit on /v2/trips. Exceeding it returns 429 with a
//      `Retry-After` (seconds), which the Flutter client honors.
//   3. Upstream 429/503 `Retry-After` is forwarded to the client both as a
//      header and as `retry_after` in the JSON body.
//
// The cache and rate limiter are per-isolate and therefore best-effort: a cold
// isolate starts with a full bucket and an empty cache. The client-side
// exponential back-off in `TransitService` is the primary protection.

interface SlimmedJourney {
  departure_time: string;
  departure_estimated: string;
  arrival_time: string;
  arrival_estimated: string;
  duration_minutes: number;
  rt_duration_minutes: number;
  legs: SlimmedLeg[];
}

interface SlimmedLeg {
  type: "transport" | "walk";
  duration_minutes: number;
  line?: string;
  destination?: string;
  transport_mode?: string;
  departure_platform?: string;
  occupancy?: string;
  delay_minutes?: number;
}

interface CacheEntry {
  body: string;
  expires: number;
}

const CACHE_TTL_MS = 30_000;
const CACHE_MAX_ENTRIES = 50;
const cache = new Map<string, CacheEntry>();

// Token bucket for /v2/trips: up to MAX_TOKENS burst, refilling one token per
// REFILL_MS. This caps sustained upstream traffic regardless of client bugs.
const MAX_TOKENS = 10;
const REFILL_MS = 1_000;
let tokens = MAX_TOKENS;
let lastRefill = Date.now();

function cacheGet(key: string): string | null {
  const entry = cache.get(key);
  if (!entry) return null;
  if (Date.now() >= entry.expires) {
    cache.delete(key);
    return null;
  }
  return entry.body;
}

function cacheSet(key: string, body: string, ttlMs: number): void {
  if (cache.size >= CACHE_MAX_ENTRIES) {
    // Evict the oldest entry (Map preserves insertion order).
    const oldest = cache.keys().next().value;
    if (oldest !== undefined) cache.delete(oldest);
  }
  cache.set(key, { body, expires: Date.now() + ttlMs });
}

function takeToken(): { ok: boolean; retryAfterSeconds: number } {
  const now = Date.now();
  const elapsed = now - lastRefill;
  if (elapsed > 0) {
    tokens = Math.min(MAX_TOKENS, tokens + elapsed / REFILL_MS);
    lastRefill = now;
  }
  if (tokens >= 1) {
    tokens -= 1;
    return { ok: true, retryAfterSeconds: 0 };
  }
  const waitMs = (1 - tokens) * REFILL_MS;
  return { ok: false, retryAfterSeconds: Math.max(1, Math.ceil(waitMs / 1000)) };
}

/// Parse a `Retry-After` header (delta-seconds form) into seconds.
function parseRetryAfter(header: string | null): number | null {
  if (!header) return null;
  const seconds = Number.parseInt(header.trim(), 10);
  if (Number.isFinite(seconds) && seconds > 0) return seconds;
  return null;
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight (OPTIONS)
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: corsHeaders(),
    });
  }

  // Only accept POST
  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed' }),
      {
        status: 405,
        headers: { ...corsHeaders(), 'Content-Type': 'application/json' },
      },
    );
  }

  try {
    const body = await req.json();
    const path = body.path as string | undefined;

    if (!path || typeof path !== 'string') {
      return new Response(
        JSON.stringify({ error: 'Missing or invalid "path" in request body' }),
        {
          status: 400,
          headers: { ...corsHeaders(), 'Content-Type': 'application/json' },
        },
      );
    }

    // Serve from cache before touching the upstream API.
    const cached = cacheGet(path);
    if (cached !== null) {
      return new Response(cached, {
        status: 200,
        headers: {
          ...corsHeaders(),
          'Content-Type': 'application/json',
          'Cache-Control': 'no-cache',
          'X-Cache': 'HIT',
        },
      });
    }

    // Rate-limit the journey planner (the endpoint that gets polled). The
    // stop-finder is user-driven and debounced on the client.
    if (path.startsWith('/v2/trips')) {
      const token = takeToken();
      if (!token.ok) {
        return new Response(
          JSON.stringify({
            error: 'Transit rate limit reached',
            status: 429,
            retry_after: token.retryAfterSeconds,
          }),
          {
            status: 429,
            headers: {
              ...corsHeaders(),
              'Content-Type': 'application/json',
              'Retry-After': String(token.retryAfterSeconds),
            },
          },
        );
      }
    }

    // All paths go to the SL Journey Planner API
    const baseUrl = 'https://journeyplanner.integration.sl.se';
    let targetUrl = `${baseUrl}${path}`;

    // Optional subscription key (SL/Trafiklab). Only appended when configured,
    // so self-hosted instances without one keep working.
    const apiKey = Deno.env.get('SL_API_KEY');
    if (apiKey && !/[?&]key=/.test(targetUrl)) {
      targetUrl += `${targetUrl.includes('?') ? '&' : '?'}key=${apiKey}`;
    }

    // Forward the request to SL API
    const slResponse = await fetch(targetUrl, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'ChronoWarden/1.0 (+https://chronowarden.slumpen.com)',
      },
    });

    if (!slResponse.ok) {
      const slBody = await slResponse.text();
      const retryAfter = parseRetryAfter(slResponse.headers.get('retry-after'));
      const headers: Record<string, string> = {
        ...corsHeaders(),
        'Content-Type': 'application/json',
      };
      if (retryAfter !== null) headers['Retry-After'] = String(retryAfter);

      return new Response(
        JSON.stringify({
          error: `SL API returned ${slResponse.status}`,
          status: slResponse.status,
          ...(retryAfter !== null ? { retry_after: retryAfter } : {}),
          detail: slBody.substring(0, 500),
        }),
        {
          status: slResponse.status,
          headers,
        },
      );
    }

    const slBody = await slResponse.text();

    // For /v2/trips, slim down the response
    if (path.startsWith('/v2/trips')) {
      try {
        const slimmed = slimTripsResponse(slBody);
        const result = JSON.stringify(slimmed);
        cacheSet(path, result, CACHE_TTL_MS);
        return new Response(result, {
          status: 200,
          headers: {
            ...corsHeaders(),
            'Content-Type': 'application/json',
            'Cache-Control': 'no-cache',
          },
        });
      } catch (_) {
        // If slimming fails, return raw response
      }
    }

    // For stop-finder and other endpoints, return as-is
    cacheSet(path, slBody, CACHE_TTL_MS);
    return new Response(slBody, {
      status: 200,
      headers: {
        ...corsHeaders(),
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache',
      },
    });
  } catch (err) {
    return new Response(
      JSON.stringify({ error: 'Internal error', detail: String(err) }),
      {
        status: 500,
        headers: { ...corsHeaders(), 'Content-Type': 'application/json' },
      },
    );
  }
});

function corsHeaders(): Record<string, string> {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers':
      'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  };
}

/// Slim a full /v2/trips response down to essential journey data.
function slimTripsResponse(rawJson: string): object {
  const parsed = JSON.parse(rawJson);
  const journeys = parsed.journeys as any[] | undefined;

  if (!Array.isArray(journeys)) {
    return { systemMessages: parsed.systemMessages ?? [], journeys: [] };
  }

  const slimmed: SlimmedJourney[] = journeys.map((j: any) => {
    const legs = j.legs as any[] | undefined ?? [];
    const slimLegs: SlimmedLeg[] = legs.map((leg: any) => {
      const transport = leg.transportation ?? null;
      const origin = leg.origin ?? {};
      const destination = leg.destination ?? {};

      // Determine leg type
      const isTransport = transport !== null;
      const type = isTransport ? 'transport' : 'walk';

      // Calculate delay in minutes
      let delayMinutes: number | undefined;
      if (isTransport && origin.departureTimePlanned && origin.departureTimeEstimated) {
        const planned = new Date(origin.departureTimePlanned).getTime();
        const estimated = new Date(origin.departureTimeEstimated).getTime();
        delayMinutes = Math.round((estimated - planned) / 60000);
        if (delayMinutes <= 0) delayMinutes = undefined;
      }

      // Line info from transportation
      let line: string | undefined;
      let destinationName: string | undefined;
      let transportMode: string | undefined;
      let occupancy: string | undefined;
      let departurePlatform: string | undefined;

      if (isTransport) {
        // Extract line number from e.g. "Spårvagn Roslagsbanan 28" -> "28"
        const name = transport.name as string ?? '';
        const match = name.match(/(\d+[A-Z]?)$/);
        line = match ? match[1] : (transport.number as string ?? '');

        const prod = transport.product ?? {};
        const modeClass = prod.class as number ?? 0;
        transportMode = mapProductClass(modeClass);

        const destObj = transport.destination ?? {};
        destinationName = destObj.name as string ?? '';

        // Occupancy is on origin.properties
        const originProps = origin.properties ?? {};
        occupancy = originProps.occupancy as string ?? undefined;

        // Platform from origin
        const platformName = originProps.platformName as string ?? undefined;
        departurePlatform = platformName ?? undefined;
      }

      const durationSec = leg.duration as number ?? 0;

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

    // Journey-level times: first leg departure, last leg arrival
    const firstLeg = legs[0] ?? {};
    const lastLeg = legs[legs.length - 1] ?? {};
    const firstOrigin = firstLeg.origin ?? {};
    const lastDest = lastLeg.destination ?? {};

    const departurePlanned = firstOrigin.departureTimePlanned ?? '';
    const departureEstimated = firstOrigin.departureTimeEstimated ?? departurePlanned;
    const arrivalPlanned = lastDest.arrivalTimePlanned ?? '';
    const arrivalEstimated = lastDest.arrivalTimeEstimated ?? arrivalPlanned;

    const tripDuration = j.tripDuration as number ?? 0;
    const tripRtDuration = j.tripRtDuration as number ?? 0;

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

/// Map SL product class to human-readable transport mode.
function mapProductClass(classId: number): string {
  // 0 = train (pendeltåg), 2 = metro, 4 = tram/local train, 5 = bus,
  // 9 = ferry, 10 = on-demand
  switch (classId) {
    case 0: return 'TRAIN';
    case 2: return 'METRO';
    case 4: return 'TRAM';
    case 5: return 'BUS';
    case 9: return 'FERRY';
    case 10: return 'ON_DEMAND';
    default: return 'OTHER';
  }
}
