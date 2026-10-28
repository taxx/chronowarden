import { spawn, spawnSync, type ChildProcess } from 'node:child_process';
import { existsSync } from 'node:fs';
import { join } from 'node:path';

const ROOT = join(import.meta.dirname, '..');
const WEB_DIR = join(ROOT, 'apps', 'web');
const BUILD_DIR = join(WEB_DIR, 'build', 'web');
const PORT = Number(process.env.E2E_PORT ?? '8099');

function ensureBunOnPath(): string {
  if (spawnSync('bun', ['--version']).status === 0) return process.env.PATH ?? '';
  const home = process.env.HOME ?? '';
  return `${join(home, '.bun', 'bin')}:${process.env.PATH ?? ''}`;
}

/** Builds the Flutter web bundle with semantics enabled (needed by Playwright). */
function buildWebApp(): void {
  if (existsSync(join(BUILD_DIR, 'main.dart.js')) && !process.env.E2E_FORCE_BUILD) return;
  console.log('[e2e] building the Flutter web bundle (semantics enabled)…');
  const result = spawnSync(
    'flutter',
    [
      'build',
      'web',
      '--release',
      '--dart-define=API_URL=',
      '--dart-define=ENABLE_SEMANTICS=true',
    ],
    { cwd: WEB_DIR, stdio: 'inherit', env: process.env },
  );
  if (result.status !== 0) throw new Error('flutter build web failed');
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
  buildWebApp();

  const env = { ...process.env, PATH: ensureBunOnPath(), E2E_PORT: String(PORT) };
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
