/**
 * Password hashing with argon2id via Bun's built-in implementation.
 *
 * Parameters follow the OWASP minimum (19 MiB memory, 2 iterations).
 */
const ARGON2_ARGS = {
  algorithm: 'argon2id',
  memoryCost: 19456,
  timeCost: 2,
} as const;

export async function hashPassword(password: string): Promise<string> {
  return Bun.password.hash(password, ARGON2_ARGS);
}

export async function verifyPassword(hash: string, password: string): Promise<boolean> {
  try {
    return await Bun.password.verify(password, hash);
  } catch {
    return false;
  }
}

/** Returns a validation error message, or `null` when the password is acceptable. */
export function validatePasswordStrength(password: unknown): string | null {
  if (typeof password !== 'string' || password.length < 10) {
    return 'Password must be at least 10 characters long';
  }
  return null;
}
