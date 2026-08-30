// Edge Function: sl-proxy
// Proxies requests to SL Transport API (transport.integration.sl.se)
// to avoid CORS issues when calling from Flutter Web.
//
// Usage:
//   POST /functions/v1/sl-proxy
//   Body: { "path": "/v1/sites" }
//   Body: { "path": "/v1/sites/9600/departures" }
//
// The function forwards the request to:
//   https://transport.integration.sl.se{path}
// and returns the JSON response with proper CORS headers.

interface Env {
  // No auth key needed for SL Transport API.
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

    // Construct the downstream URL
    const baseUrl = 'https://transport.integration.sl.se';
    const targetUrl = `${baseUrl}${path}`;

    // Forward the request to SL API
    const slResponse = await fetch(targetUrl, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
      },
    });

    if (!slResponse.ok) {
      return new Response(
        JSON.stringify({
          error: `SL API returned ${slResponse.status}`,
          status: slResponse.status,
        }),
        {
          status: slResponse.status,
          headers: { ...corsHeaders(), 'Content-Type': 'application/json' },
        },
      );
    }

    const slBody = await slResponse.text();

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
