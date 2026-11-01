/**
 * Random token generation and hashing.
 *
 * Invite tokens and session tokens are only ever stored as SHA-256 hashes;
 * the raw value is returned to the client once.
 */
export function generateToken(bytes = 32): string {
  const buffer = new Uint8Array(bytes);
  crypto.getRandomValues(buffer);
  return Array.from(buffer, (b) => b.toString(16).padStart(2, '0')).join('');
}

export function hashToken(token: string): string {
  return new Bun.CryptoHasher('sha256').update(token).digest('hex');
}

// Unambiguous alphabet (no 0/O, 1/I/l) for passwords read aloud or typed.
const PASSWORD_ALPHABET = 'abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';

/**
 * A human-copyable temporary password for admin-assisted resets
 * (always longer than the 10-character minimum).
 *
 * Uses rejection sampling so every character is uniformly distributed.
 */
export function generateTemporaryPassword(length = 14): string {
  const chars: string[] = [];
  const limit = 256 - (256 % PASSWORD_ALPHABET.length);
  while (chars.length < length) {
    const buffer = new Uint8Array(Math.max(16, length - chars.length));
    crypto.getRandomValues(buffer);
    for (const byte of buffer) {
      if (chars.length === length) break;
      if (byte < limit) chars.push(PASSWORD_ALPHABET[byte % PASSWORD_ALPHABET.length]!);
    }
  }
  return chars.join('');
}
