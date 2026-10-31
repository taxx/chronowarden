import { entropyToMnemonic, mnemonicToEntropy } from '@scure/bip39';
import { wordlist } from '@scure/bip39/wordlists/english';

/**
 * Client-side envelope encryption.
 *
 * A byte-for-byte port of the Dart client's `CryptoService` — existing
 * envelopes, ciphertext and recovery phrases must keep working. Verified
 * against `__fixtures__/crypto-golden.json`, which the Dart implementation
 * produced (see `apps/web/test/crypto_golden_test.dart`).
 *
 *   Passphrase → PBKDF2(310k) → Master Key (KEK)
 *     └─ AES-GCM wrap ──→ Data Encryption Key (DEK)
 *           └─ AES-GCM encrypt ──→ Encrypted data
 *
 * The recovery phrase uses the **official BIP39 English wordlist** (via the
 * audited `@scure/bip39`), replacing the Dart client's bespoke wordlist. The
 * DEK/envelope/passphrase are unaffected by that switch — only the words differ.
 */

/** OWASP 2025 minimum for PBKDF2-HMAC-SHA256. */
export const KEK_ITERATIONS = 310_000;
export const KEK_KEY_LENGTH_BYTES = 32;
export const SALT_LENGTH = 16;
export const NONCE_LENGTH = 12;
export const MAC_LENGTH = 16;

const subtle = globalThis.crypto.subtle;
const encoder = new TextEncoder();
const decoder = new TextDecoder();

// ---------------------------------------------------------------------------
// Encoding helpers
// ---------------------------------------------------------------------------

export function bytesToBase64(bytes: Uint8Array): string {
  let binary = '';
  for (let i = 0; i < bytes.length; i++) binary += String.fromCharCode(bytes[i]!);
  return btoa(binary);
}

export function base64ToBytes(value: string): Uint8Array {
  const binary = atob(value);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

function concat(a: Uint8Array, b: Uint8Array): Uint8Array {
  const out = new Uint8Array(a.length + b.length);
  out.set(a, 0);
  out.set(b, a.length);
  return out;
}

/**
 * Copy a view into a plain `ArrayBuffer` for WebCrypto.
 *
 * TypeScript 5.7+ types `Uint8Array` as `Uint8Array<ArrayBufferLike>`, which is
 * not assignable to WebCrypto's `BufferSource`; a real `ArrayBuffer` is.
 */
function toSource(view: Uint8Array): ArrayBuffer {
  return view.buffer.slice(view.byteOffset, view.byteOffset + view.byteLength) as ArrayBuffer;
}

// ---------------------------------------------------------------------------
// Key lifecycle
// ---------------------------------------------------------------------------

/** Random 128-bit salt. */
export function generateSalt(): Uint8Array {
  return crypto.getRandomValues(new Uint8Array(SALT_LENGTH));
}

/** Random 256-bit Data Encryption Key. */
export function generateDek(): Uint8Array {
  return crypto.getRandomValues(new Uint8Array(KEK_KEY_LENGTH_BYTES));
}

/** Derive the 256-bit Master Key (KEK) from a passphrase + salt. */
export async function deriveMasterKey(passphrase: string, salt: Uint8Array): Promise<CryptoKey> {
  const baseKey = await subtle.importKey(
    'raw',
    toSource(encoder.encode(passphrase)),
    'PBKDF2',
    false,
    ['deriveKey'],
  );
  return subtle.deriveKey(
    { name: 'PBKDF2', salt: toSource(salt), iterations: KEK_ITERATIONS, hash: 'SHA-256' },
    baseKey,
    { name: 'AES-GCM', length: 256 },
    false,
    ['encrypt', 'decrypt'],
  );
}

/** Wrap a DEK with the KEK. Returns base64(nonce ‖ ciphertext ‖ tag). */
export async function wrapDek(dek: Uint8Array, kek: CryptoKey): Promise<string> {
  const nonce = crypto.getRandomValues(new Uint8Array(NONCE_LENGTH));
  const cipher = new Uint8Array(
    await subtle.encrypt({ name: 'AES-GCM', iv: toSource(nonce), tagLength: 128 }, kek, toSource(dek)),
  );
  return bytesToBase64(concat(nonce, cipher));
}

/** Unwrap a DEK with the KEK. */
export async function unwrapDek(wrappedB64: string, kek: CryptoKey): Promise<Uint8Array> {
  const combined = base64ToBytes(wrappedB64);
  const nonce = combined.slice(0, NONCE_LENGTH);
  const cipher = combined.slice(NONCE_LENGTH);
  const plain = await subtle.decrypt(
    { name: 'AES-GCM', iv: toSource(nonce), tagLength: 128 },
    kek,
    toSource(cipher),
  );
  return new Uint8Array(plain);
}

/** Wrap a DEK under a new passphrase (generate salt, derive KEK, wrap). */
export async function wrapDekWithPassphrase(
  dek: Uint8Array,
  passphrase: string,
): Promise<{ wrapped_b64: string; salt_b64: string; iterations: number }> {
  const salt = generateSalt();
  const kek = await deriveMasterKey(passphrase, salt);
  return {
    wrapped_b64: await wrapDek(dek, kek),
    salt_b64: bytesToBase64(salt),
    iterations: KEK_ITERATIONS,
  };
}

// ---------------------------------------------------------------------------
// Data encryption
// ---------------------------------------------------------------------------

async function importDek(dek: Uint8Array): Promise<CryptoKey> {
  return subtle.importKey('raw', toSource(dek), { name: 'AES-GCM' }, false, ['encrypt', 'decrypt']);
}

/** Encrypt a string with the DEK. Returns base64(nonce ‖ ciphertext ‖ tag). */
export async function encryptString(plaintext: string, dek: Uint8Array): Promise<string> {
  const key = await importDek(dek);
  const nonce = crypto.getRandomValues(new Uint8Array(NONCE_LENGTH));
  const cipher = new Uint8Array(
    await subtle.encrypt(
      { name: 'AES-GCM', iv: toSource(nonce), tagLength: 128 },
      key,
      toSource(encoder.encode(plaintext)),
    ),
  );
  return bytesToBase64(concat(nonce, cipher));
}

/** Decrypt base64(nonce ‖ ciphertext ‖ tag) with the DEK. */
export async function decryptString(ciphertextB64: string, dek: Uint8Array): Promise<string> {
  const key = await importDek(dek);
  const combined = base64ToBytes(ciphertextB64);
  const nonce = combined.slice(0, NONCE_LENGTH);
  const cipher = combined.slice(NONCE_LENGTH);
  const plain = await subtle.decrypt(
    { name: 'AES-GCM', iv: toSource(nonce), tagLength: 128 },
    key,
    toSource(cipher),
  );
  return decoder.decode(plain);
}

// ---------------------------------------------------------------------------
// Recovery phrase (official BIP39)
// ---------------------------------------------------------------------------

/** Encode a 32-byte DEK as a 24-word BIP39 mnemonic. */
export function dekToMnemonic(dek: Uint8Array): string {
  if (dek.length !== KEK_KEY_LENGTH_BYTES) throw new Error('DEK must be 32 bytes');
  return entropyToMnemonic(dek, wordlist);
}

/** Decode a BIP39 mnemonic back to the 32-byte DEK, verifying the checksum. */
export function mnemonicToDek(phrase: string): Uint8Array {
  // BIP39 words are lowercase and single-space separated; NFKD is a no-op for
  // the English wordlist, so a simple normalisation is enough.
  const normalized = phrase.trim().toLowerCase().split(/\s+/).join(' ');
  try {
    return mnemonicToEntropy(normalized, wordlist);
  } catch {
    throw new Error('Recovery phrase is invalid — check the words and try again.');
  }
}

/** SHA-256 of a recovery phrase (base64), stored for verification. */
export async function hashRecoveryPhrase(phrase: string): Promise<string> {
  const digest = new Uint8Array(
    await subtle.digest('SHA-256', toSource(encoder.encode(phrase))),
  );
  return bytesToBase64(digest);
}
