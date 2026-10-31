import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';

import { describe, expect, test } from 'vitest';

import { svCatalog, translate } from './index';

/**
 * Mirrors the Flutter `app_strings_test.dart` guard: every `t('…')` key must
 * have a Swedish entry, and every Swedish entry must still be used.
 */
function walk(dir: string): string[] {
  return readdirSync(dir).flatMap((entry) => {
    const full = join(dir, entry);
    return statSync(full).isDirectory() ? walk(full) : [full];
  });
}

function extractKeys(): Set<string> {
  const keys = new Set<string>();
  for (const file of walk(join(process.cwd(), 'src'))) {
    if (!file.endsWith('.ts') && !file.endsWith('.tsx')) continue;
    if (file.includes(`${'/'}i18n/`)) continue;

    const source = readFileSync(file, 'utf8');
    const regex = /\bt\(\s*(['"])((?:(?!\1).)*)\1/g;
    let match: RegExpExecArray | null;
    while ((match = regex.exec(source)) !== null) keys.add(match[2]!);
  }
  return keys;
}

describe('Swedish catalog', () => {
  const keys = extractKeys();

  test('covers every t() key', () => {
    const missing = [...keys].filter((key) => !(key in svCatalog)).sort();
    expect(missing, `Missing Swedish translations: ${missing.join(', ')}`).toEqual([]);
  });

  test('has no unused entries', () => {
    const stale = Object.keys(svCatalog)
      .filter((key) => !keys.has(key))
      .sort();
    expect(stale, `Unused Swedish entries: ${stale.join(', ')}`).toEqual([]);
  });

  test('falls back to English for unknown keys', () => {
    expect(translate('sv', 'Some unknown string')).toBe('Some unknown string');
  });

  test('interpolates placeholders', () => {
    expect(translate('en', 'Hello {name}', { name: 'World' })).toBe('Hello World');
  });
});
