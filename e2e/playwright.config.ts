import { defineConfig } from '@playwright/test';

const port = Number(process.env.E2E_PORT ?? '8099');
const baseURL = process.env.E2E_BASE_URL ?? `http://127.0.0.1:${port}`;

export default defineConfig({
  testDir: './tests',
  timeout: 90_000,
  expect: { timeout: 20_000 },
  workers: 1,
  fullyParallel: false,
  reporter: [['list']],
  globalSetup: './global-setup.ts',
  use: {
    baseURL,
    headless: true,
    trace: 'retain-on-failure',
  },
});
