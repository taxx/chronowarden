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
// The function forwards the request and returns JSON with CORS headers.
// For /v2/trips, the response is slimmed down to essential fields.

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

    // All paths go to the SL Journey Planner API
    const baseUrl = 'https://journeyplanner.integration.sl.se';
    const targetUrl = `${baseUrl}${path}`;

    // Forward the request to SL API
    const slResponse = await fetch(targetUrl, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
      },
    });

    if (!slResponse.ok) {
      const slBody = await slResponse.text();
      return new Response(
        JSON.stringify({
          error: `SL API returned ${slResponse.status}`,
          status: slResponse.status,
          detail: slBody.substring(0, 500),
        }),
        {
          status: slResponse.status,
          headers: { ...corsHeaders(), 'Content-Type': 'application/json' },
        },
      );
    }

    const slBody = await slResponse.text();

    // For /v2/trips, slim down the response
    if (path.startsWith('/v2/trips')) {
      try {
        const slimmed = slimTripsResponse(slBody);
        return new Response(JSON.stringify(slimmed), {
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
