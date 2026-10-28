import { test, expect, type Page } from '@playwright/test';

/**
 * End-to-end browser tests.
 *
 * The harness (global-setup.ts) starts a throwaway Postgres + the real API and
 * serves the built Flutter web app on one origin, so these exercise the actual
 * UI against the actual backend. Flutter renders to canvas, so the tests drive
 * the accessibility semantics tree (built with ENABLE_SEMANTICS=true).
 *
 * Tests are serial because they share one database: the first creates the admin
 * that the others sign in with.
 */
test.describe.serial('ChronoWarden end-to-end', () => {
  const ADMIN_EMAIL = 'e2e-admin@example.com';
  const ADMIN_PASSWORD = 'supersecret1';
  const ENCRYPTION_PASSPHRASE = 'e2e-encryption-passphrase';

  /**
   * Flutter web commits a field's value on focus change, so `fill()` can drop
   * values. Click the field and actually type instead.
   */
  async function typeInto(page: Page, name: string, text: string, exact = false): Promise<void> {
    const field = page.getByRole('textbox', { name, exact });
    await field.click();
    // Flutter web attaches its input element asynchronously and can swallow
    // the first keystroke, so settle, then type (and verify) deliberately.
    await page.waitForTimeout(250);

    for (let attempt = 0; attempt < 2; attempt++) {
      await page.keyboard.press('ControlOrMeta+A');
      await page.keyboard.press('Backspace');
      await page.keyboard.type(text, { delay: 30 });
      await page.waitForTimeout(150);
      if ((await field.inputValue().catch(() => '')) === text) return;
    }
  }

  async function signIn(page: Page): Promise<void> {
    await typeInto(page, 'Email', ADMIN_EMAIL);
    await typeInto(page, 'Password', ADMIN_PASSWORD);
    await expect(page.getByRole('textbox', { name: 'Email' })).toHaveValue(ADMIN_EMAIL);
    await expect(page.getByRole('textbox', { name: 'Password' })).toHaveValue(ADMIN_PASSWORD);

    await page.getByText('I have an encryption passphrase').click();
    await typeInto(page, 'Encryption passphrase', ENCRYPTION_PASSPHRASE, true);
    await expect(
      page.getByRole('textbox', { name: 'Encryption passphrase', exact: true }),
    ).toHaveValue(ENCRYPTION_PASSPHRASE);

    await page.getByRole('button', { name: 'Sign In' }).click();
    await expect(page.getByRole('button', { name: 'Sign out' })).toBeVisible();
  }

  test('first run: creates the admin through the UI', async ({ page }) => {
    await page.goto('/');

    // Empty database → first-run admin screen.
    const createAdmin = page.getByRole('button', { name: 'Create Admin Account' });
    await expect(createAdmin).toBeVisible();

    await typeInto(page, 'Full name', 'E2E Admin');
    await typeInto(page, 'Email', ADMIN_EMAIL);
    await typeInto(page, 'Password (min 10 characters)', ADMIN_PASSWORD);
    await typeInto(page, 'Encryption passphrase', ENCRYPTION_PASSPHRASE, true);
    await typeInto(page, 'Confirm encryption passphrase', ENCRYPTION_PASSPHRASE);

    await createAdmin.click();

    // Recovery phrase onboarding is shown when the flow manages to push it;
    // the app shell is the other possible landing spot. Accept either.
    await page.waitForTimeout(1500);
    const continueToApp = page.getByRole('button', { name: 'Continue to App' });
    if (await continueToApp.isVisible().catch(() => false)) {
      await continueToApp.click();
    }

    await expect(page.getByRole('button', { name: 'Sign out' })).toBeVisible({ timeout: 30_000 });
  });

  test('returns login after the first run and signs in', async ({ page }) => {
    await page.goto('/');
    await expect(page.getByRole('button', { name: 'Sign In' })).toBeVisible();
    await signIn(page);
  });

  test('downloads a full backup from Settings', async ({ page }) => {
    await page.goto('/');
    await signIn(page);

    // Open Settings from the app bar and scroll to the backup card.
    await page.getByRole('button', { name: 'Settings' }).click({ force: true });
    await expect(page.getByRole('heading', { name: 'Settings' })).toBeVisible();

    await page.mouse.move(400, 400);
    const downloadButton = page.getByRole('button', { name: 'Download backup' });
    for (let i = 0; i < 15; i++) {
      if (await downloadButton.isVisible().catch(() => false)) break;
      await page.mouse.wheel(0, 800);
      await page.waitForTimeout(150);
    }
    await expect(downloadButton).toBeVisible();

    // Flutter's semantics overlay sits above the glass pane, so hit-tested
    // clicks can miss. Dispatching the click directly on the semantics node
    // activates the widget's handler.
    const downloadPromise = page.waitForEvent('download');
    await downloadButton.dispatchEvent('click');
    const download = await downloadPromise;

    expect(download.suggestedFilename()).toMatch(/^chronowarden_backup_\d{4}-\d{2}-\d{2}\.json$/);

    const stream = await download.createReadStream();
    const chunks: Buffer[] = [];
    for await (const chunk of stream) chunks.push(chunk as Buffer);
    const bundle = JSON.parse(Buffer.concat(chunks).toString('utf8'));

    expect(bundle.format).toBe('chronowarden-backup');
    expect(bundle.version).toBe(1);
    expect(bundle.envelope.encrypted_dek).toBeTruthy();
    expect(bundle.envelope.kek_salt).toBeTruthy();
    expect(bundle.envelope.recovery_hash).toBeTruthy();
    expect(bundle.settings).toBeDefined();
    expect(Array.isArray(bundle.time_logs)).toBe(true);
    expect(Array.isArray(bundle.travel_presets)).toBe(true);
  });
});
