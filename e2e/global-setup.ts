import { spawn, spawnSync, type ChildProcess } from 'node:child_process';
import { existsSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';

const ROOT = join(import.meta.dirname, '..');
const WEB_DIR = join(ROOT, 'apps', 'web');
const DIST = join(WEB_DIR, 'dist');
const PORT = Number(process.env.E2E_PORT ?? '8098');

function nodeBinDir(): string {
  const local = join(process.env.HOME ?? '', '.nodejs', 'v26.13.0', 'bin');
  return existsSync(local) ? local : '';
}

function buildClient(): void {
  if (existsSync(join(DIST, 'index.html')) && !process.env.E2E_FORCE_BUILD) return;
  console.log('[e2e-next] building the React client…');
  const path = nodeBinDir();
  const result = spawnSync('npm', ['run', 'build'], {
    cwd: WEB_DIR,
    stdio: 'inherit',
    env: { ...process.env, PATH: path ? `${path}:${process.env.PATH}` : process.env.PATH },
  });
  if (result.status !== 0) throw new Error('npm run build failed');
}

async function waitForHealth(timeoutMs = 30_000): Promise<void> {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    try {
      const res = await fetch(`http://127.0.0.1:${PORT}/api/health`);
      if (res.ok) return;
    } catch {
      // not up yet
    }
    await new Promise((r) => setTimeout(r, 250));
  }
  throw new Error(`E2E server did not become healthy on port ${PORT}`);
}

export default async function globalSetup(): Promise<() => Promise<void>> {
  buildClient();
  mkdirSync(DIST, { recursive: true });

  const path = nodeBinDir();
  const bunPath = existsSync(join(process.env.HOME ?? '', '.bun', 'bin'))
    ? join(process.env.HOME ?? '', '.bun', 'bin')
    : '';
  const env = {
    ...process.env,
    E2E_PORT: String(PORT),
    PATH: [path, bunPath, process.env.PATH].filter(Boolean).join(':'),
  };

  const child: ChildProcess = spawn('bun', ['run', join(import.meta.dirname, 'server.ts')], {
    env,
    stdio: 'inherit',
  });

  await waitForHealth();

  return async () => {
    child.kill('SIGTERM');
    await new Promise((r) => setTimeout(r, 500));
  };
}
