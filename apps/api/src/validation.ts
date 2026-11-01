import { ApiError } from './errors.ts';

/**
 * Shared request-field validation.
 *
 * The API accepts only opaque ciphertext plus a few plaintext fields, so the
 * rules are small and deliberate: every string has a maximum length and every
 * structured field a strict shape. This keeps a malicious/buggy client from
 * pushing unbounded values into the database or memory.
 */

export const MAX_EMAIL = 320;
export const MAX_NAME = 200;
export const MAX_DATE = 10;
export const MAX_TOKEN = 256;
/** Ciphertext for a single day's log or the whole settings payload. */
export const MAX_ENCRYPTED = 512_000;
/** Envelope fields (wrapped DEK, salt, recovery-hash base64). */
export const MAX_ENVELOPE_FIELD = 4_096;
export const MIN_KEK_ITERATIONS = 100_000;
export const MAX_KEK_ITERATIONS = 10_000_000;

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

export function normalizeEmail(email: unknown): string {
  if (typeof email !== 'string') throw ApiError.badRequest('INVALID_EMAIL', 'Email is required');
  const value = email.trim().toLowerCase();
  if (value.length > MAX_EMAIL || !EMAIL_RE.test(value)) {
    throw ApiError.badRequest('INVALID_EMAIL', 'Enter a valid email address');
  }
  return value;
}

/** Required string with a hard maximum length. */
export function requireString(value: unknown, field: string, maxLength = 100_000): string {
  if (typeof value !== 'string') throw ApiError.badRequest('INVALID_BODY', `${field} is required`);
  if (value.length > maxLength) {
    throw ApiError.badRequest('INVALID_BODY', `${field} exceeds the maximum length`);
  }
  return value;
}

/** Required `YYYY-MM-DD` date string (also rejects impossible calendars). */
export function requireDate(value: unknown): string {
  const date = requireString(value, 'date', MAX_DATE);
  if (!DATE_RE.test(date)) {
    throw ApiError.badRequest('INVALID_DATE', 'date must be YYYY-MM-DD');
  }
  const [year, month, day] = date.split('-').map(Number) as [number, number, number];
  const parsed = new Date(Date.UTC(year, month - 1, day));
  if (
    parsed.getUTCFullYear() !== year ||
    parsed.getUTCMonth() !== month - 1 ||
    parsed.getUTCDate() !== day
  ) {
    throw ApiError.badRequest('INVALID_DATE', 'date must be a real calendar date');
  }
  return date;
}

/** Optional free-text field (e.g. `fullName`); `undefined`/`null` → `null`. */
export function optionalText(value: unknown, field: string, maxLength: number): string | null {
  if (value === undefined || value === null) return null;
  if (typeof value !== 'string') throw ApiError.badRequest('INVALID_BODY', `${field} is invalid`);
  if (value.length > maxLength) {
    throw ApiError.badRequest('INVALID_BODY', `${field} exceeds the maximum length`);
  }
  const trimmed = value.trim();
  return trimmed.length === 0 ? null : trimmed;
}

/** Optional bounded integer (e.g. `kek_iterations`). */
export function optionalInteger(value: unknown, field: string, min: number, max: number): number | null {
  if (value === undefined || value === null) return null;
  if (typeof value !== 'number' || !Number.isInteger(value) || value < min || value > max) {
    throw ApiError.badRequest('INVALID_BODY', `${field} must be an integer between ${min} and ${max}`);
  }
  return value;
}
