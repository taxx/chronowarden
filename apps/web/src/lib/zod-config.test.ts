import { describe, expect, test } from 'vitest';
import { z } from 'zod';

import './zod-config';

describe('zod CSP configuration', () => {
  test('runs jitless so the `new Function` eval probe never fires', () => {
    expect(z.core.globalConfig.jitless).toBe(true);
    // Reading `.value` would run Zod's `new Function("")` probe without
    // jitless; with it set, the probe is skipped and eval is reported as
    // unavailable.
    expect(z.core.util.allowsEval.value).toBe(false);
  });
});
