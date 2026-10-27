/**
 * Error type serialised as `{ error: { code, message } }` with an HTTP status.
 *
 * Messages are plain English and are surfaced directly in the UI; the client
 * maps a few known messages to friendlier copy.
 */
export class ApiError extends Error {
  readonly status: number;
  readonly code: string;

  constructor(status: number, code: string, message: string) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.code = code;
  }

  static badRequest(code: string, message: string): ApiError {
    return new ApiError(400, code, message);
  }

  static unauthorized(message = 'Not authenticated'): ApiError {
    return new ApiError(401, 'UNAUTHENTICATED', message);
  }

  static forbidden(message = 'Admin privileges required'): ApiError {
    return new ApiError(403, 'FORBIDDEN', message);
  }

  static notFound(message = 'Not found'): ApiError {
    return new ApiError(404, 'NOT_FOUND', message);
  }

  static conflict(code: string, message: string): ApiError {
    return new ApiError(409, code, message);
  }
}
