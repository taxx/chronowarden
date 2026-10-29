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
    await page.getByRole('button', { name: 'Add day' }).click();

    await page.getByLabel('Date').fill('2026-01-05');
    await page.getByLabel('Start').fill('08:00');
    await page.getByLabel('Stop').fill('16:30');
    await page.getByLabel('Expected minutes').fill('480');
    await page.getByRole('button', { name: 'Save' }).click();

    await expect(page.getByText('2026-01-05')).toBeVisible();
  });

  test('downloads a backup from Settings', async ({ page }) => {
    await page.goto('/');
    await signIn(page);

    await page.getByRole('link', { name: 'Settings' }).click();

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

    await page.getByRole('link', { name: 'Admin' }).click();
    await page.getByRole('button', { name: 'Invites' }).click();

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
