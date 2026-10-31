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
 */
export function generateTemporaryPassword(length = 14): string {
  const buffer = new Uint8Array(length);
  crypto.getRandomValues(buffer);
  return Array.from(buffer, (b) => PASSWORD_ALPHABET[b % PASSWORD_ALPHABET.length]).join('');
}
