import { test, expect, type Page } from '@playwright/test';

/**
 * End-to-end tests for the React client.
 *
 * The harness (`global-setup.ts`) builds `apps/web`, starts a throwaway
 * Postgres + the real API, and serves everything on one origin. As a DOM app,
 * Playwright drives it with ordinary role/label selectors.
 */
test.describe.serial('ChronoWarden web', () => {
  const EMAIL = 'e2e@example.com';
  const PASSWORD = 'supersecret1';
  const PASSPHRASE = 'e2e-encryption-passphrase';
  let recoveryPhrase = '';

  async function signIn(page: Page) {
    await page.getByLabel('Email').fill(EMAIL);
    await page.getByLabel('Password').fill(PASSWORD);
    await page.getByRole('button', { name: 'I have an encryption passphrase' }).click();
    await page.getByLabel('Encryption passphrase', { exact: true }).fill(PASSPHRASE);
    await page.getByRole('button', { name: 'Sign in' }).click();
    await expect(page.getByRole('link', { name: 'My Day' })).toBeVisible();
  }

  /** Settings and Admin now live under the account menu. */
  async function openAccountMenu(page: Page) {
    await page.getByRole('button', { name: 'Account' }).click();
  }

  test('loads under the Content-Security-Policy with no violations', async ({ page }) => {
    const violations: string[] = [];
    page.on('console', (message) => {
      if (message.type() === 'error' && /Content Security Policy/i.test(message.text())) {
        violations.push(message.text());
      }
    });

    const response = await page.goto('/');
    expect(response?.headers()['content-security-policy'] ?? '').toContain("default-src 'self'");
    await expect(page.getByRole('heading', { name: 'First-time setup' })).toBeVisible();
    // Let the app settle so any deferred CSP errors surface.
    await page.waitForTimeout(500);
    expect(violations).toEqual([]);
  });

  test('first run: setup creates the admin and shows the recovery phrase', async ({ page }) => {
    await page.goto('/');
    await expect(page.getByRole('heading', { name: 'First-time setup' })).toBeVisible();

    await page.getByLabel('Full name').fill('E2E Admin');
    await page.getByLabel('Email').fill(EMAIL);
    await page.getByLabel('Password').fill(PASSWORD);
    await page.getByLabel('Encryption passphrase', { exact: true }).fill(PASSPHRASE);
    await page.getByLabel('Confirm encryption passphrase').fill(PASSPHRASE);
    await page.getByRole('button', { name: 'Create admin account' }).click();

    await expect(page.getByRole('heading', { name: 'Your recovery phrase' })).toBeVisible();
    const phrase = await page.getByTestId('recovery-phrase').innerText();
    expect(phrase.trim().split(/\s+/)).toHaveLength(24);
    recoveryPhrase = phrase.trim();

    await page.getByRole('button', { name: 'I have saved my recovery phrase' }).click();
    await expect(page.getByRole('link', { name: 'My Day' })).toBeVisible();
  });

  test('start day dialog offers sliders for lunch, non-work and banked time', async ({ page }) => {
    await page.goto('/');
    await signIn(page);

    await page.getByRole('button', { name: 'Start Day' }).first().click();
    await expect(page.getByLabel('Lunch minutes')).toBeVisible();
    await expect(page.getByLabel('Non-work minutes')).toBeVisible();
    await expect(page.getByLabel('Banked time to withdraw')).toBeVisible();
    await page.getByRole('button', { name: 'Cancel' }).click();
  });

  test('dial time picker supports dragging to select the hour', async ({ page }) => {
    await page.goto('/');
    await signIn(page);

    await page.getByRole('button', { name: 'Start Day' }).first().click();
    await page.getByLabel('Start time').click();
    await page.getByRole('button', { name: 'Hours' }).click(); // ensure the hour step

    const box = await page.getByTestId('time-picker-face').boundingBox();
    const cx = box!.x + box!.width / 2;
    const cy = box!.y + box!.height / 2;
    // Drag on the outer ring from 3 o'clock (hour 15) to the bottom (hour 18).
    await page.mouse.move(cx + 92, cy);
    await page.mouse.down();
    await page.mouse.move(cx, cy + 92, { steps: 6 });
    await page.mouse.up();

    await expect(page.getByRole('button', { name: 'Hours' })).toHaveText('18');
    await page.getByRole('button', { name: 'Done' }).click();
    await expect(page.locator('[data-radix-popper-content-wrapper]')).toHaveCount(0);
    await expect(page.getByLabel('Start time')).toContainText('18:');
    await page.getByRole('button', { name: 'Cancel' }).click();
  });

  test('signs in and runs a day', async ({ page }) => {
    await page.goto('/');
    await signIn(page);

    await page.getByRole('button', { name: 'Start Day' }).click();
    // The start dialog opens with the same label; submit it.
    await page.getByRole('button', { name: 'Start Day' }).last().click();
    await expect(page.getByText('Leave time')).toBeVisible();

    await page.getByRole('button', { name: 'Stop Day' }).first().click();
    await page.getByRole('button', { name: 'Stop Day' }).last().click();
    await expect(page.getByText('Day completed')).toBeVisible();
  });

  test('adds a day in History which updates the time bank', async ({ page }) => {
    await page.goto('/');
    await signIn(page);

    await page.getByRole('link', { name: 'History' }).click();
    const rowsBefore = await page.locator('tbody tr').count();

    await page.getByRole('button', { name: 'Add day' }).click();

    // Pick a date through the calendar picker.
    await page.getByLabel('Date').click();
    await page.getByRole('button', { name: '15', exact: true }).first().click();

    await page.getByLabel('Start').click();
    await page.getByRole('button', { name: '08' }).click();
    await page.getByRole('button', { name: '00' }).click();
    await page.getByRole('button', { name: 'Done' }).click();
    // Wait for the first picker to finish closing so the next one is unambiguous.
    await expect(page.locator('[data-radix-popper-content-wrapper]')).toHaveCount(0);

    await page.getByLabel('Stop').click();
    await page.getByRole('button', { name: '16' }).click();
    await page.getByRole('button', { name: '30' }).click();
    await page.getByRole('button', { name: 'Done' }).click();
    await expect(page.locator('[data-radix-popper-content-wrapper]')).toHaveCount(0);

    await page.getByLabel('Expected minutes').fill('480');
    await page.getByRole('button', { name: 'Save' }).click();

    await expect.poll(() => page.locator('tbody tr').count()).toBeGreaterThan(rowsBefore);
  });

  test('shows validation errors from the zod resolver', async ({ page }) => {
    await page.goto('/');
    await signIn(page);

    await openAccountMenu(page);
    await page.getByRole('menuitem', { name: 'Settings' }).click();
    await page.getByLabel('New passphrase').fill('a-long-enough-passphrase');
    await page.getByLabel('Confirm passphrase').fill('a-different-passphrase');
    await page.getByRole('button', { name: 'Change passphrase' }).click();

    // The `.refine(..., { path: ['confirm'] })` error must map to the field.
    await expect(page.getByText('Passphrases do not match')).toBeVisible();
  });

  test('downloads a backup from Settings', async ({ page }) => {
    await page.goto('/');
    await signIn(page);

    await openAccountMenu(page);
    await page.getByRole('menuitem', { name: 'Settings' }).click();

    const downloadPromise = page.waitForEvent('download');
    await page.getByRole('button', { name: 'Download backup' }).click();
    const download = await downloadPromise;

    expect(download.suggestedFilename()).toMatch(/^chronowarden_backup_\d{4}-\d{2}-\d{2}\.json$/);

    const stream = await download.createReadStream();
    const chunks: Buffer[] = [];
    for await (const chunk of stream) chunks.push(chunk as Buffer);
    const bundle = JSON.parse(Buffer.concat(chunks).toString('utf8'));

    expect(bundle.format).toBe('chronowarden-backup');
    expect(bundle.envelope.encrypted_dek).toBeTruthy();
    expect(bundle.envelope.recovery_hash).toBeTruthy();
    expect(Array.isArray(bundle.time_logs)).toBe(true);
  });

  test('admin can create an invite', async ({ page }) => {
    await page.goto('/');
    await signIn(page);

    await openAccountMenu(page);
    await page.getByRole('menuitem', { name: 'Admin' }).click();
    await page.getByRole('tab', { name: 'Invites' }).click();

    await page.getByLabel('Email').fill('invitee@example.com');
    await page.getByRole('button', { name: 'Create invite' }).click();

    await expect(page.getByText('Copy this token and share it with the user:')).toBeVisible();
    await expect(page.getByText('invitee@example.com')).toBeVisible();
  });

  // Runs last: it sets a new passphrase, so earlier tests need the original one.
  test('recovers access with the recovery phrase and a new passphrase', async ({ page }) => {
    await page.goto('/');

    // Sign in without the passphrase to land on the unlock screen.
    await page.getByLabel('Email').fill(EMAIL);
    await page.getByLabel('Password').fill(PASSWORD);
    await page.getByRole('button', { name: 'Sign in' }).click();
    await expect(page.getByRole('heading', { name: 'Unlock' })).toBeVisible();

    await page.getByRole('link', { name: 'Forgot passphrase?' }).click();
    await page.getByLabel('Enter your recovery phrase').fill(recoveryPhrase);
    await page.getByLabel('New encryption passphrase').fill('a-new-encryption-passphrase');
    await page.getByLabel('Confirm encryption passphrase').fill('a-new-encryption-passphrase');
    await page.getByRole('button', { name: 'Recover access' }).click();

    await expect(page.getByRole('link', { name: 'My Day' })).toBeVisible();
  });
});
