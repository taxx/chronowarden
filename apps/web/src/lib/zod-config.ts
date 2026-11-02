import { z } from 'zod';

/**
 * Run Zod in `jitless` mode.
 *
 * Zod 4 probes `new Function("")` on the first parse to decide whether it can
 * use its eval-based fast path. Under ChronoWarden's strict CSP that probe is
 * blocked and logged as a `script-src` violation (even though Zod swallows the
 * throw), and `unsafe-eval` must not be enabled. `jitless` skips the probe and
 * the fast path entirely.
 *
 * Imported first from `main.tsx` so it is configured before any schema parses.
 */
z.config({ jitless: true });
