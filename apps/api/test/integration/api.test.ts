/**
 * End-to-end API integration tests.
 *
 * Starts a throwaway Postgres (or uses TEST_DATABASE_URL), runs the real
 * migrations, then drives the real Hono app in-process. Covers bootstrap/auth,
 * invites, admin operations, cross-user isolation, CRUD, export/import and SSE.
 */
import { afterAll, beforeAll, describe, expect, test } from 'bun:test';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { findPgBin, pgEnv, startTestPostgres, type TestPostgres } from '../helpers/postgres.ts';
import { generateToken, hashToken } from '../../src/tokens.ts';

let db: TestPostgres;
let app: any;
let sql: any;

interface Res<T = any> {
  status: number;
  body: T;
}

async function call<T = any>(
  method: string,
  path: string,
  opts: { token?: string; body?: unknown } = {},
): Promise<Res<T>> {
  const headers: Record<string, string> = { accept: 'application/json' };
  if (opts.token) headers.authorization = `Bearer ${opts.token}`;
  if (opts.body !== undefined) headers['content-type'] = 'application/json';
  const res = await app.request(path, {
    method,
    headers,
    body: opts.body === undefined ? undefined : JSON.stringify(opts.body),
  });
  const text = await res.text();
  let body: any = null;
  if (text) {
    try {
      body = JSON.parse(text);
    } catch {
      body = text;
    }
  }
  return { status: res.status, body };
}

let adminToken = '';
let adminId = '';
let initialState: boolean | null = null;
let initialStatus: number = 0;
const PASSWORD = 'supersecret1';

async function makeUser(
  email: string,
  opts: { role?: string; password?: string } = {},
): Promise<{ token: string; id: string; password: string }> {
  const invite = await call<{ token: string }>('POST', '/api/v1/admin/invites', {
    token: adminToken,
    body: { email, role: opts.role },
  });
  expect(invite.status).toBe(201);
  const password = opts.password ?? PASSWORD;
  const reg = await call<{ token: string; user: { id: string } }>('POST', '/api/v1/auth/register', {
    body: { email, password, fullName: 'Test User', inviteToken: invite.body.token },
  });
  expect(reg.status).toBe(201);
  return { token: reg.body.token, id: reg.body.user.id, password };
}

beforeAll(async () => {
  db = await startTestPostgres();
  process.env['DATABASE_URL'] = db.url;
  process.env['SESSION_TTL_DAYS'] = '30';

  const dbModule = await import('../../src/db.ts');
  const migrateModule = await import('../../src/migrate.ts');
  const appModule = await import('../../src/app.ts');
  sql = dbModule.sql;
  app = appModule.app;

  await migrateModule.migrate(sql);

  // Probe first-run state before bootstrap.
  const state = await call('GET', '/api/v1/state');
  initialStatus = state.status;
  initialState = state.body.has_users;

  const setup = await call<{ token: string; user: { id: string } }>('POST', '/api/v1/auth/setup', {
    body: { email: 'admin@example.com', password: PASSWORD, fullName: 'Admin' },
  });
  expect(setup.status).toBe(201);
  adminToken = setup.body.token;
  adminId = setup.body.user.id;
});

afterAll(async () => {
  try {
    await sql?.end({ timeout: 5 });
  } catch {}
  await db?.stop();
});

describe('bootstrap & authentication', () => {
  test('reports no users before setup', () => {
    expect(initialStatus).toBe(200);
    expect(initialState).toBe(false);
  });

  test('reports users exist after setup', async () => {
    const res = await call<{ has_users: boolean }>('GET', '/api/v1/state');
    expect(res.body.has_users).toBe(true);
  });

  test('second setup is rejected', async () => {
    const res = await call('POST', '/api/v1/auth/setup', {
      body: { email: 'other@example.com', password: PASSWORD, fullName: 'Other' },
    });
    expect(res.status).toBe(409);
  });

  test('login with a wrong password and an unknown email give the same error', async () => {
    const wrong = await call('POST', '/api/v1/auth/login', {
      body: { email: 'admin@example.com', password: 'wrong-password' },
    });
    const unknown = await call('POST', '/api/v1/auth/login', {
      body: { email: 'nobody@example.com', password: 'wrong-password' },
    });
    expect(wrong.status).toBe(400);
    expect(unknown.status).toBe(400);
    expect(wrong.body.error.code).toBe('INVALID_CREDENTIALS');
    expect(unknown.body.error.code).toBe('INVALID_CREDENTIALS');
    expect(wrong.body.error.message).toBe(unknown.body.error.message);
  });

  test('login returns a session; /me works and requires auth', async () => {
    const login = await call<{ token: string; user: { role: string } }>('POST', '/api/v1/auth/login', {
      body: { email: 'admin@example.com', password: PASSWORD },
    });
    expect(login.status).toBe(200);
    expect(login.body.user.role).toBe('admin');

    const me = await call<{ email: string }>('GET', '/api/v1/me', { token: login.body.token });
    expect(me.status).toBe(200);
    expect(me.body.email).toBe('admin@example.com');

    const anon = await call('GET', '/api/v1/me');
    expect(anon.status).toBe(401);
  });

  test('logout revokes the session', async () => {
    const login = await call<{ token: string }>('POST', '/api/v1/auth/login', {
      body: { email: 'admin@example.com', password: PASSWORD },
    });
    const token = login.body.token;
    expect((await call('GET', '/api/v1/me', { token })).status).toBe(200);

    const logout = await call('POST', '/api/v1/auth/logout', { token });
    expect(logout.status).toBe(200);
    expect((await call('GET', '/api/v1/me', { token })).status).toBe(401);
  });

  test('password change verifies the current password and then takes effect', async () => {
    const user = await makeUser('pw@example.com');

    const wrong = await call('PATCH', '/api/v1/me/password', {
      token: user.token,
      body: { currentPassword: 'not-it', newPassword: 'brandnewpass1' },
    });
    expect(wrong.status).toBe(400);

    const weak = await call('PATCH', '/api/v1/me/password', {
      token: user.token,
      body: { currentPassword: user.password, newPassword: 'short' },
    });
    expect(weak.status).toBe(400);

    const ok = await call('PATCH', '/api/v1/me/password', {
      token: user.token,
      body: { currentPassword: user.password, newPassword: 'brandnewpass1' },
    });
    expect(ok.status).toBe(200);

    const oldLogin = await call('POST', '/api/v1/auth/login', {
      body: { email: 'pw@example.com', password: user.password },
    });
    expect(oldLogin.status).toBe(400);
    const newLogin = await call('POST', '/api/v1/auth/login', {
      body: { email: 'pw@example.com', password: 'brandnewpass1' },
    });
    expect(newLogin.status).toBe(200);
  });
});

describe('invites', () => {
  test('invite can be validated and used once', async () => {
    const invite = await call<{ token: string }>('POST', '/api/v1/admin/invites', {
      token: adminToken,
      body: { email: 'invitee@example.com' },
    });
    expect(invite.status).toBe(201);

    const check = await call<{ valid: boolean; email: string }>('POST', '/api/v1/invites/validate', {
      body: { token: invite.body.token },
    });
    expect(check.body.valid).toBe(true);
    expect(check.body.email).toBe('invitee@example.com');

    const reg = await call('POST', '/api/v1/auth/register', {
      body: {
        email: 'invitee@example.com',
        password: PASSWORD,
        fullName: 'Invitee',
        inviteToken: invite.body.token,
      },
    });
    expect(reg.status).toBe(201);

    const reuse = await call<{ error: { code: string } }>('POST', '/api/v1/auth/register', {
      body: {
        email: 'invitee@example.com',
        password: PASSWORD,
        fullName: 'Invitee',
        inviteToken: invite.body.token,
      },
    });
    expect(reuse.status).toBe(400);
    expect(reuse.body.error.code).toBe('INVITE_USED');
  });

  test('invite is bound to its email', async () => {
    const invite = await call<{ token: string }>('POST', '/api/v1/admin/invites', {
      token: adminToken,
      body: { email: 'bound@example.com' },
    });
    const res = await call<{ error: { code: string } }>('POST', '/api/v1/auth/register', {
      body: {
        email: 'someone-else@example.com',
        password: PASSWORD,
        fullName: 'Nope',
        inviteToken: invite.body.token,
      },
    });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('INVITE_EMAIL_MISMATCH');
  });

  test('expired invites are rejected', async () => {
    const email = 'expired@example.com';
    const token = generateToken();
    await sql`
      insert into invites (email, token_hash, role, expires_at)
      values (${email}, ${hashToken(token)}, 'user', now() - interval '1 day')
    `;
    const res = await call<{ error: { code: string } }>('POST', '/api/v1/auth/register', {
      body: { email, password: PASSWORD, fullName: 'Expired', inviteToken: token },
    });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('INVITE_EXPIRED');
  });

  test('a new invite replaces the previous unused one', async () => {
    const first = await call<{ token: string }>('POST', '/api/v1/admin/invites', {
      token: adminToken,
      body: { email: 'replace@example.com' },
    });
    const second = await call<{ token: string }>('POST', '/api/v1/admin/invites', {
      token: adminToken,
      body: { email: 'replace@example.com' },
    });

    const old = await call<{ valid: boolean }>('POST', '/api/v1/invites/validate', {
      body: { token: first.body.token },
    });
    const fresh = await call<{ valid: boolean }>('POST', '/api/v1/invites/validate', {
      body: { token: second.body.token },
    });
    expect(old.body.valid).toBe(false);
    expect(fresh.body.valid).toBe(true);
  });

  test('invites can be listed and deleted by an admin', async () => {
    const invite = await call<{ id: string; token: string }>('POST', '/api/v1/admin/invites', {
      token: adminToken,
      body: { email: 'delete-me@example.com' },
    });
    const list = await call<Array<{ id: string; email: string; token?: string }>>(
      'GET',
      '/api/v1/admin/invites',
      { token: adminToken },
    );
    expect(list.status).toBe(200);
    const entry = list.body.find((i) => i.email === 'delete-me@example.com');
    expect(entry).toBeDefined();
    expect(entry!.token).toBeUndefined(); // raw token is only returned on create

    const del = await call('DELETE', `/api/v1/admin/invites/${invite.body.id}`, { token: adminToken });
    expect(del.status).toBe(204);
    const after = await call<{ valid: boolean }>('POST', '/api/v1/invites/validate', {
      body: { token: invite.body.token },
    });
    expect(after.body.valid).toBe(false);
  });
});

describe('admin user management', () => {
  test('lists users and manages roles/status', async () => {
    const user = await makeUser('managed@example.com');

    const list = await call<Array<{ id: string; role: string; status: string }>>(
      'GET',
      '/api/v1/admin/users',
      { token: adminToken },
    );
    expect(list.body.some((u) => u.id === user.id)).toBe(true);

    const reject = await call('PATCH', `/api/v1/admin/users/${user.id}`, {
      token: adminToken,
      body: { status: 'rejected' },
    });
    expect(reject.status).toBe(200);

    const rejectedLogin = await call<{ error: { code: string } }>('POST', '/api/v1/auth/login', {
      body: { email: 'managed@example.com', password: user.password },
    });
    expect(rejectedLogin.status).toBe(400);
    expect(rejectedLogin.body.error.code).toBe('ACCOUNT_DISABLED');

    await call('PATCH', `/api/v1/admin/users/${user.id}`, {
      token: adminToken,
      body: { status: 'approved' },
    });
    const okLogin = await call('POST', '/api/v1/auth/login', {
      body: { email: 'managed@example.com', password: user.password },
    });
    expect(okLogin.status).toBe(200);
  });

  test('admin cannot delete their own account', async () => {
    const res = await call('DELETE', `/api/v1/admin/users/${adminId}`, { token: adminToken });
    expect(res.status).toBe(400);
  });

  test('deleting a user cascades to their data and sessions', async () => {
    const user = await makeUser('cascade@example.com');
    await call('POST', '/api/v1/time-logs', {
      token: user.token,
      body: { date: '2026-02-02', encrypted_data: 'X' },
    });

    const del = await call('DELETE', `/api/v1/admin/users/${user.id}`, { token: adminToken });
    expect(del.status).toBe(204);

    const logs = await sql`select count(*)::int as n from time_logs where user_id = ${user.id}`;
    const sessions = await sql`select count(*)::int as n from sessions where user_id = ${user.id}`;
    expect(logs[0].n).toBe(0);
    expect(sessions[0].n).toBe(0);

    const login = await call('POST', '/api/v1/auth/login', {
      body: { email: 'cascade@example.com', password: user.password },
    });
    expect(login.status).toBe(400);
  });

  test('non-admins cannot reach admin routes', async () => {
    const user = await makeUser('plain@example.com');
    const res = await call('GET', '/api/v1/admin/users', { token: user.token });
    expect(res.status).toBe(403);
  });
});

describe('cross-user isolation', () => {
  test('a user cannot read, change or delete another user\'s rows', async () => {
    const alice = await makeUser('alice@example.com');
    const bob = await makeUser('bob@example.com');

    const log = await call<{ id: string }>('POST', '/api/v1/time-logs', {
      token: alice.token,
      body: { date: '2026-03-03', encrypted_data: 'alice-secret' },
    });
    expect(log.status).toBe(201);
    const logId = log.body.id;

    const preset = await call<{ id: string }>('POST', '/api/v1/travel-presets', {
      token: alice.token,
      body: { name: 'Alice Commute', encrypted_data: 'alice-preset' },
    });
    const presetId = preset.body.id;

    // Direct id access → 404 (not 403), so ids can't be probed.
    expect((await call('GET', `/api/v1/time-logs/${logId}`, { token: bob.token })).status).toBe(404);
    expect(
      (await call('PATCH', `/api/v1/time-logs/${logId}`, {
        token: bob.token,
        body: { encrypted_data: 'hijack' },
      })).status,
    ).toBe(404);
    expect((await call('DELETE', `/api/v1/time-logs/${logId}`, { token: bob.token })).status).toBe(404);
    expect((await call('GET', `/api/v1/travel-presets/${presetId}`, { token: bob.token })).status).toBe(404);

    // Even an admin cannot read another user's row.
    expect((await call('GET', `/api/v1/time-logs/${logId}`, { token: adminToken })).status).toBe(404);

    // Lists are scoped.
    const bobLogs = await call<Array<{ id: string }>>('GET', '/api/v1/time-logs', { token: bob.token });
    expect(bobLogs.body.some((l) => l.id === logId)).toBe(false);

    // Bob's export contains none of Alice's data.
    const bobExport = await call<{ time_logs: Array<{ encrypted_data: string }> }>('GET', '/api/v1/export', {
      token: bob.token,
    });
    expect(bobExport.body.time_logs).toHaveLength(0);
  });

  test('unauthenticated data requests are rejected', async () => {
    for (const path of ['/api/v1/time-logs', '/api/v1/travel-presets', '/api/v1/settings', '/api/v1/export']) {
      expect((await call('GET', path)).status).toBe(401);
    }
  });
});

describe('data CRUD & settings', () => {
  test('time logs round-trip with a YYYY-MM-DD date', async () => {
    const user = await makeUser('crud-log@example.com');

    const created = await call<{ id: string; date: string }>('POST', '/api/v1/time-logs', {
      token: user.token,
      body: { date: '2026-01-05', encrypted_data: 'cipher' },
    });
    expect(created.status).toBe(201);
    expect(created.body.date).toBe('2026-01-05');

    const byDate = await call<Array<{ id: string }>>('GET', '/api/v1/time-logs?date=2026-01-05', {
      token: user.token,
    });
    expect(byDate.body).toHaveLength(1);
    expect(byDate.body[0]!.id).toBe(created.body.id);

    const patched = await call<{ encrypted_data: string }>('PATCH', `/api/v1/time-logs/${created.body.id}`, {
      token: user.token,
      body: { encrypted_data: 'updated' },
    });
    expect(patched.body.encrypted_data).toBe('updated');

    const del = await call('DELETE', `/api/v1/time-logs/${created.body.id}`, { token: user.token });
    expect(del.status).toBe(204);
    const empty = await call<Array<unknown>>('GET', '/api/v1/time-logs', { token: user.token });
    expect(empty.body).toHaveLength(0);
  });

  test('travel presets keep their plaintext name', async () => {
    const user = await makeUser('crud-preset@example.com');
    const created = await call<{ id: string; name: string }>('POST', '/api/v1/travel-presets', {
      token: user.token,
      body: { name: 'Bike', encrypted_data: 'p1' },
    });
    expect(created.status).toBe(201);
    expect(created.body.name).toBe('Bike');

    const patched = await call<{ name: string; encrypted_data: string }>(
      'PATCH',
      `/api/v1/travel-presets/${created.body.id}`,
      { token: user.token, body: { name: 'Bike v2', encrypted_data: 'p2' } },
    );
    expect(patched.body.name).toBe('Bike v2');
    expect(patched.body.encrypted_data).toBe('p2');
  });

  test('settings PATCH merges envelope and payload fields', async () => {
    const user = await makeUser('settings@example.com');

    await call('PATCH', '/api/v1/settings', {
      token: user.token,
      body: {
        encrypted_dek: 'DEK',
        kek_salt: 'SALT',
        kek_iterations: 310000,
        recovery_hash: 'HASH',
      },
    });
    await call('PATCH', '/api/v1/settings', { token: user.token, body: { encrypted_data: 'PAYLOAD' } });

    const res = await call<Record<string, unknown>>('GET', '/api/v1/settings', { token: user.token });
    expect(res.body['encrypted_dek']).toBe('DEK');
    expect(res.body['kek_salt']).toBe('SALT');
    expect(res.body['recovery_hash']).toBe('HASH');
    expect(res.body['encrypted_data']).toBe('PAYLOAD');
  });
});

describe('export & import', () => {
  test('a bundle restores fully into another account', async () => {
    const source = await makeUser('source@example.com');
    const target = await makeUser('target@example.com');

    await call('PATCH', '/api/v1/settings', {
      token: source.token,
      body: { encrypted_dek: 'DEK', kek_salt: 'SALT', kek_iterations: 310000, recovery_hash: 'H' },
    });
    await call('PATCH', '/api/v1/settings', { token: source.token, body: { encrypted_data: 'SETTINGS' } });
    await call('POST', '/api/v1/time-logs', {
      token: source.token,
      body: { date: '2026-04-04', encrypted_data: 'LOG' },
    });
    await call('POST', '/api/v1/travel-presets', {
      token: source.token,
      body: { name: 'Office', encrypted_data: 'PRESET' },
    });

    const exported = await call<any>('GET', '/api/v1/export', { token: source.token });
    expect(exported.body.format).toBe('chronowarden-backup');
    expect(exported.body.envelope.encrypted_dek).toBe('DEK');
    expect(exported.body.time_logs).toHaveLength(1);
    expect(exported.body.travel_presets).toHaveLength(1);

    const imported = await call('POST', '/api/v1/import', { token: target.token, body: exported.body });
    expect(imported.status).toBe(200);

    const targetExport = await call<any>('GET', '/api/v1/export', { token: target.token });
    expect(targetExport.body.envelope.encrypted_dek).toBe('DEK');
    expect(targetExport.body.settings.encrypted_data).toBe('SETTINGS');
    expect(targetExport.body.time_logs).toHaveLength(1);
    expect(targetExport.body.time_logs[0].encrypted_data).toBe('LOG');
    expect(targetExport.body.travel_presets[0].name).toBe('Office');
  });

  test('malformed and future-version bundles are rejected', async () => {
    const user = await makeUser('badimport@example.com');
    const notABundle = await call<{ error: { code: string } }>('POST', '/api/v1/import', {
      token: user.token,
      body: { hello: 'world' },
    });
    expect(notABundle.status).toBe(400);
    expect(notABundle.body.error.code).toBe('INVALID_BUNDLE');

    const future = await call<{ error: { code: string } }>('POST', '/api/v1/import', {
      token: user.token,
      body: { format: 'chronowarden-backup', version: 999 },
    });
    expect(future.status).toBe(400);
    expect(future.body.error.code).toBe('UNSUPPORTED_BUNDLE');
  });
});

describe('realtime (SSE)', () => {
  test('a write publishes an event to the owner\'s stream', async () => {
    const user = await makeUser('sse@example.com');

    const res = await app.request(`/api/v1/events?token=${user.token}`);
    expect(res.status).toBe(200);
    expect(res.headers.get('content-type')).toContain('text/event-stream');

    const reader = res.body!.getReader();
    const decoder = new TextDecoder();
    let received = '';

    const readUntilEvent = (async () => {
      const deadline = Date.now() + 5000;
      while (Date.now() < deadline) {
        const { value, done } = await reader.read();
        if (done) break;
        received += decoder.decode(value, { stream: true });
        if (received.includes('"type":"INSERT"')) break;
      }
    })();

    await new Promise((r) => setTimeout(r, 150));
    await call('POST', '/api/v1/time-logs', {
      token: user.token,
      body: { date: '2026-05-05', encrypted_data: 'SSE' },
    });

    await readUntilEvent;
    await reader.cancel().catch(() => {});

    expect(received).toContain('event: ready');
    expect(received).toContain('"table":"time_logs"');
    expect(received).toContain('"type":"INSERT"');
  });
});

describe('cookie sessions', () => {
  async function loginCookie(): Promise<{ cookie: string; setCookie: string }> {
    const login = await app.request('/api/v1/auth/login', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ email: 'admin@example.com', password: PASSWORD }),
    });
    const setCookie = login.headers.get('set-cookie') ?? '';
    return { cookie: setCookie.split(';')[0] ?? '', setCookie };
  }

  test('login sets an httpOnly session cookie that authenticates requests', async () => {
    const { cookie, setCookie } = await loginCookie();
    expect(setCookie).toContain('cw_session=');
    expect(setCookie.toLowerCase()).toContain('httponly');

    const me = await app.request('/api/v1/me', { headers: { cookie } });
    expect(me.status).toBe(200);
    expect(((await me.json()) as { email: string }).email).toBe('admin@example.com');
  });

  test('cookie sessions can reach admin routes', async () => {
    const { cookie } = await loginCookie();
    const users = await app.request('/api/v1/admin/users', { headers: { cookie } });
    expect(users.status).toBe(200);
  });

  test('logout revokes the session and clears the cookie', async () => {
    const { cookie } = await loginCookie();

    const logout = await app.request('/api/v1/auth/logout', { method: 'POST', headers: { cookie } });
    expect(logout.status).toBe(200);
    expect(logout.headers.get('set-cookie') ?? '').toContain('cw_session=');

    const me = await app.request('/api/v1/me', { headers: { cookie } });
    expect(me.status).toBe(401);
  });

  test('bearer tokens still authenticate (Flutter compatibility)', async () => {
    const login = await call<{ token: string }>('POST', '/api/v1/auth/login', {
      body: { email: 'admin@example.com', password: PASSWORD },
    });
    expect((await call('GET', '/api/v1/me', { token: login.body.token })).status).toBe(200);
  });
});

describe('backup pipeline', () => {
  const hasPgDump = findPgBin() !== null || Bun.which('pg_dump') !== null;

  test.skipIf(!hasPgDump)('pg_dump archive can be restored into a fresh database', async () => {
    const bin = db.binDir || dirname(Bun.which('pg_dump')!);
    const env = pgEnv(db.url);
    const root = mkdtempSync(join(tmpdir(), 'cwdump-'));
    const archive = join(root, 'backup.tar');

    const mustRun = (cmd: string, args: string[], runEnv = env) => {
      const result = spawnSync(join(bin, cmd), args, { env: runEnv, encoding: 'utf8' });
      expect({ cmd, status: result.status, stderr: result.stderr }).toMatchObject({ cmd, status: 0 });
      return result;
    };

    try {
      mustRun('pg_dump', ['--format=tar', '--file', archive, '--no-owner']);

      // Restore into a second database on the same server.
      const parsed = new URL(db.url);
      const restoreDb = 'chronowarden_restore';
      mustRun('createdb', ['-h', parsed.hostname, '-p', parsed.port, '-U', parsed.username, restoreDb]);

      mustRun('pg_restore', ['--format=tar', '--no-owner', '-d', restoreDb, archive], env);

      const count = mustRun('psql', ['-tA', '-d', restoreDb, '-c', 'select count(*) from users']);
      expect(Number(count.stdout.trim())).toBeGreaterThan(0);
    } finally {
      rmSync(root, { recursive: true, force: true });
    }
  });
});
