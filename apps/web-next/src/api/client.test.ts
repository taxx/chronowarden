import { afterEach, describe, expect, test, vi } from 'vitest';

import { ApiError, api } from './client';

describe('api client', () => {
  afterEach(() => {
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  });

  test('parses a successful response', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(async () => new Response(JSON.stringify({ ok: true }), { status: 200 })),
    );
    await expect(api.get('/health')).resolves.toEqual({ ok: true });
  });

  test('maps an API error body to ApiError', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(
        async () =>
          new Response(
            JSON.stringify({ error: { code: 'INVALID_CREDENTIALS', message: 'Invalid email or password' } }),
            { status: 400 },
          ),
      ),
    );

    const error = await api.post('/auth/login', {}).catch((e: unknown) => e);
    expect(error).toBeInstanceOf(ApiError);
    expect(error).toMatchObject({
      status: 400,
      code: 'INVALID_CREDENTIALS',
      message: 'Invalid email or password',
    });
  });

  test('turns a transport failure into a NETWORK error', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(async () => {
        throw new TypeError('failed to fetch');
      }),
    );

    const error = await api.get('/me').catch((e: unknown) => e);
    expect(error).toBeInstanceOf(ApiError);
    expect((error as ApiError).code).toBe('NETWORK');
  });

  test('sends credentials so the session cookie travels', async () => {
    const fetchMock = vi.fn(
      async (_input: RequestInfo | URL, _init?: RequestInit) => new Response('null', { status: 200 }),
    );
    vi.stubGlobal('fetch', fetchMock);

    await api.get('/me');

    const init = fetchMock.mock.calls[0]?.[1];
    expect(init?.credentials).toBe('include');
  });
});
