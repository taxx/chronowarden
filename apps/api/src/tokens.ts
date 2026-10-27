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
