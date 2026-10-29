/**
 * Thin fetch wrapper for the ChronoWarden API.
 *
 * Same-origin by default (`/api/v1`), so the session cookie travels
 * automatically — in production behind the nginx proxy, and in development via
 * the Vite proxy. Sentinels and errors match the Flutter client's `ApiClient`.
 */

export class ApiError extends Error {
  readonly status: number;
  readonly code: string;

  constructor(status: number, code: string, message: string) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.code = code;
  }
}

const BASE_URL = (import.meta.env.VITE_API_URL as string | undefined) ?? '/api/v1';

function url(path: string, query?: Record<string, string | number | undefined>): string {
  const normalized = path.startsWith('/') ? path : `/${path}`;
  const base = `${BASE_URL.replace(/\/$/, '')}${normalized}`;
  if (!query) return base;
  const params = new URLSearchParams();
  for (const [key, value] of Object.entries(query)) {
    if (value !== undefined) params.set(key, String(value));
  }
  const qs = params.toString();
  return qs ? `${base}?${qs}` : base;
}

async function request<T>(
  method: string,
  path: string,
  options: { query?: Record<string, string | number | undefined>; body?: unknown } = {},
): Promise<T> {
  let response: Response;
  try {
    response = await fetch(url(path, options.query), {
      method,
      credentials: 'include',
      headers: {
        accept: 'application/json',
        ...(options.body !== undefined ? { 'content-type': 'application/json' } : {}),
      },
      body: options.body === undefined ? undefined : JSON.stringify(options.body),
    });
  } catch {
    throw new ApiError(0, 'NETWORK', 'Could not reach the server. Check your connection.');
  }

  const text = await response.text();
  let parsed: unknown = null;
  if (text) {
    try {
      parsed = JSON.parse(text);
    } catch {
      parsed = null;
    }
  }

  if (response.ok) return parsed as T;

  const error = (parsed as { error?: { code?: string; message?: string } } | null)?.error;
  throw new ApiError(
    response.status,
    error?.code ?? 'ERROR',
    error?.message ?? `Request failed (HTTP ${response.status})`,
  );
}

export const api = {
  get: <T>(path: string, query?: Record<string, string | number | undefined>) =>
    request<T>('GET', path, { query }),
  post: <T>(path: string, body?: unknown) => request<T>('POST', path, { body }),
  patch: <T>(path: string, body?: unknown) => request<T>('PATCH', path, { body }),
  delete: <T>(path: string) => request<T>('DELETE', path),
};
