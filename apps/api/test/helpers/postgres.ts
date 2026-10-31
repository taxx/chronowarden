import { spawnSync } from 'node:child_process';
import { existsSync, mkdtempSync, rmSync } from 'node:fs';
import { createServer } from 'node:net';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';

export interface TestPostgres {
  url: string;
  /** Directory containing initdb/pg_dump/etc. (empty when a URL was supplied). */
  binDir: string;
  stop: () => Promise<void>;
}

/** Locate the Postgres server binaries (initdb, pg_ctl, pg_dump, …). */
export function findPgBin(): string | null {
  const initdb = Bun.which('initdb');
  if (initdb) return dirname(initdb);

  const pgConfig = Bun.which('pg_config');
  if (pgConfig) {
    const result = spawnSync(pgConfig, ['--bindir'], { encoding: 'utf8' });
    const dir = result.stdout.trim();
    if (result.status === 0 && dir && existsSync(join(dir, 'initdb'))) return dir;
  }

  const candidates = [
    '/opt/homebrew/opt/postgresql@18/bin',
    '/opt/homebrew/opt/postgresql@17/bin',
    '/usr/local/opt/postgresql@18/bin',
    '/usr/lib/postgresql/18/bin',
    '/usr/lib/postgresql/17/bin',
    '/usr/local/pgsql/bin',
  ];
  for (const candidate of candidates) {
    if (existsSync(join(candidate, 'initdb'))) return candidate;
  }
  return null;
}

async function freePort(): Promise<number> {
  return new Promise((resolve, reject) => {
    const server = createServer();
    server.on('error', reject);
    server.listen(0, '127.0.0.1', () => {
      const port = (server.address() as { port: number }).port;
      server.close(() => resolve(port));
    });
  });
}

function run(bin: string, args: string[], env?: NodeJS.ProcessEnv): void {
  const result = spawnSync(join(bin, args[0]!), args.slice(1), { encoding: 'utf8', env });
  if (result.status !== 0) {
    throw new Error(`${args[0]} failed (${result.status}):\n${result.stdout}\n${result.stderr}`);
  }
}

/**
 * Starts a throwaway Postgres for integration tests.
 *
 * - If `TEST_DATABASE_URL` is set, that database is used as-is (CI/service).
 * - Otherwise an ephemeral cluster is started in a temp dir (local dev).
 */
export async function startTestPostgres(): Promise<TestPostgres> {
  const explicit = Bun.env['TEST_DATABASE_URL'];
  if (explicit) {
    return { url: explicit, binDir: findPgBin() ?? '', stop: async () => {} };
  }

  const bin = findPgBin();
  if (!bin) {
    throw new Error(
      'Postgres binaries not found. Install Postgres, or set TEST_DATABASE_URL to a throwaway database.',
    );
  }

  const root = mkdtempSync(join(tmpdir(), 'cwpg-'));
  const dataDir = join(root, 'data');

  run(bin, ['initdb', '-D', dataDir, '--auth=trust', '-U', 'postgres', '-E', 'UTF8', '--no-locale']);
  const port = await freePort();
  run(bin, [
    'pg_ctl',
    '-D',
    dataDir,
    '-o',
    `-p ${port} -k ${root} -h 127.0.0.1`,
    '-l',
    join(root, 'pg.log'),
    '-w',
    'start',
  ]);
  run(bin, ['createdb', '-h', '127.0.0.1', '-p', String(port), '-U', 'postgres', 'chronowarden_test']);

  return {
    url: `postgres://postgres@127.0.0.1:${port}/chronowarden_test`,
    binDir: bin,
    stop: async () => {
      try {
        spawnSync(join(bin, 'pg_ctl'), ['-D', dataDir, '-m', 'fast', 'stop'], { encoding: 'utf8' });
      } catch {
        // best effort
      }
      rmSync(root, { recursive: true, force: true });
    },
  };
}

/** PG* environment for the given connection URL (for pg_dump/pg_restore). */
export function pgEnv(url: string): NodeJS.ProcessEnv {
  const parsed = new URL(url);
  return {
    ...process.env,
    PGHOST: parsed.hostname,
    PGPORT: parsed.port,
    PGUSER: parsed.username,
    PGPASSWORD: parsed.password || undefined,
    PGDATABASE: parsed.pathname.replace(/^\//, ''),
  };
}
