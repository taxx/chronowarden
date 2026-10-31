/**
 * Pure leave-time alert evaluation.
 *
 * Ported from `apps/web/lib/services/notification_service.dart`
 * (`evaluateLeaveAlert`). Timing decisions live here so they are unit-tested
 * independently of timers and the browser APIs.
 */
export type LeaveAlertKind = 'wrapUp' | 'overtime';

export interface LeaveAlert {
  kind: LeaveAlertKind;
  /** Minutes until leave (positive) or past leave (negative). */
  remainingMinutes: number;
}

export interface LeaveAlertInput {
  remainingMinutes: number;
  thresholdMinutes: number;
  dismissed: boolean;
  snoozed: boolean;
  alreadyAlerted: boolean;
}

export function evaluateLeaveAlert(input: LeaveAlertInput): LeaveAlert | null {
  const { remainingMinutes, thresholdMinutes, dismissed, snoozed, alreadyAlerted } = input;
  if (dismissed || snoozed || alreadyAlerted) return null;

  // Phase 1 — wrap-up alert (within the configured threshold before leave).
  if (remainingMinutes >= 0 && remainingMinutes <= thresholdMinutes) {
    return { kind: 'wrapUp', remainingMinutes };
  }

  // Phase 2 — overtime alert (up to 60 min past leave).
  if (remainingMinutes < 0 && remainingMinutes >= -60) {
    return { kind: 'overtime', remainingMinutes };
  }

  return null;
}
