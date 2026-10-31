import { describe, expect, test } from 'bun:test';
import { hashPassword, validatePasswordStrength, verifyPassword } from '../../src/password.ts';
import { generateToken, hashToken } from '../../src/tokens.ts';

describe('password', () => {
  test('hashes and verifies argon2id', async () => {
    const hash = await hashPassword('correct horse battery staple');
    expect(hash.startsWith('$argon2id$')).toBe(true);
    expect(await verifyPassword(hash, 'correct horse battery staple')).toBe(true);
    expect(await verifyPassword(hash, 'wrong password')).toBe(false);
  });

  test('rejects short passwords', () => {
    expect(validatePasswordStrength('short')).toBeTruthy();
    expect(validatePasswordStrength('long enough password')).toBeNull();
    expect(validatePasswordStrength(undefined)).toBeTruthy();
  });

  test('never throws on a malformed hash', async () => {
    expect(await verifyPassword('not-a-hash', 'whatever')).toBe(false);
  });
});

describe('tokens', () => {
  test('generates distinct tokens', () => {
    const a = generateToken();
    const b = generateToken();
    expect(a).toHaveLength(64);
    expect(a).not.toBe(b);
  });

  test('hashes deterministically', () => {
    expect(hashToken('abc')).toBe(hashToken('abc'));
    expect(hashToken('abc')).not.toBe(hashToken('abd'));
    expect(hashToken('abc')).toHaveLength(64);
  });
});
