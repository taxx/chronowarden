import { describe, expect, test } from 'vitest';

import fixture from './__fixtures__/crypto-golden.json';
import {
  base64ToBytes,
  bytesToBase64,
  decryptString,
  dekToMnemonic,
  deriveMasterKey,
  encryptString,
  generateDek,
  hashRecoveryPhrase,
  mnemonicToDek,
  unwrapDek,
  wrapDek,
} from './crypto';

/**
 * The fixtures were produced by the existing Dart client, so these tests prove
 * the rewrite can read data written by the app that is live today.
 */
describe('envelope interop (golden fixtures from the Dart client)', () => {
  test('derives the KEK and unwraps the wrapped DEK', async () => {
    const salt = base64ToBytes(fixture.salt_b64);
    const kek = await deriveMasterKey(fixture.passphrase, salt);
    const dek = await unwrapDek(fixture.wrapped_dek_b64, kek);
    expect(bytesToBase64(dek)).toBe(fixture.dek_b64);
  });

  test('decrypts ciphertext produced by the Dart client', async () => {
    const dek = base64ToBytes(fixture.dek_b64);
    expect(await decryptString(fixture.ciphertext_b64, dek)).toBe(fixture.plaintext);
  });

  test('round-trips its own wrap and encrypt', async () => {
    const salt = base64ToBytes(fixture.salt_b64);
    const kek = await deriveMasterKey(fixture.passphrase, salt);

    const dek = generateDek();
    const wrapped = await wrapDek(dek, kek);
    expect(bytesToBase64(await unwrapDek(wrapped, kek))).toBe(bytesToBase64(dek));

    const ciphertext = await encryptString('round-trip', dek);
    expect(await decryptString(ciphertext, dek)).toBe('round-trip');
  });

  test('rejects a wrong passphrase', async () => {
    const salt = base64ToBytes(fixture.salt_b64);
    const kek = await deriveMasterKey('wrong-passphrase', salt);
    await expect(unwrapDek(fixture.wrapped_dek_b64, kek)).rejects.toThrow();
  });
});

describe('recovery phrase (official BIP39)', () => {
  test('encodes the fixture DEK and decodes it back', () => {
    const dek = base64ToBytes(fixture.dek_b64);
    const phrase = dekToMnemonic(dek);

    expect(phrase.split(' ')).toHaveLength(24);
    expect(bytesToBase64(mnemonicToDek(phrase))).toBe(fixture.dek_b64);
  });

  test('tolerates extra whitespace', () => {
    const dek = base64ToBytes(fixture.dek_b64);
    const phrase = dekToMnemonic(dek);
    const messy = `  ${phrase.replace(/ /g, '   ')}  `;
    expect(bytesToBase64(mnemonicToDek(messy))).toBe(fixture.dek_b64);
  });

  test('rejects an invalid phrase', () => {
    expect(() => mnemonicToDek('this is not a valid recovery phrase')).toThrow();
  });

  test('hashing is deterministic and is base64 SHA-256', async () => {
    const phrase = dekToMnemonic(base64ToBytes(fixture.dek_b64));
    const first = await hashRecoveryPhrase(phrase);
    expect(await hashRecoveryPhrase(phrase)).toBe(first);
    expect(base64ToBytes(first)).toHaveLength(32);
  });
});
