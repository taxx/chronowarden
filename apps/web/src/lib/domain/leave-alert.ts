/**
 * Pure leave-time alert evaluation.
 *
 * Ported from `apps/web/lib/services/notification_service.dart`
 * (`evaluateLeaveAlert`). Timing decisions live here so they are unit-tested
 * independently of timers and the browser APIs.
 *
 * There are two independent phases per day: a wrap-up alert while approaching
 * leave time, then an overtime alert once leave time has passed. Each phase
 * fires once; `snooze` re-arms them.
 */
export type LeaveAlertKind = 'wrapUp' | 'overtime';

/** How long past leave time the overtime alert keeps firing. */
export const OVERTIME_WINDOW_MINUTES = 60;

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
  /** The wrap-up alert already fired today. */
  wrapUpAlreadyAlerted: boolean;
  /** The overtime alert already fired today. */
  overtimeAlreadyAlerted: boolean;
}

export function evaluateLeaveAlert(input: LeaveAlertInput): LeaveAlert | null {
  const {
    remainingMinutes,
    thresholdMinutes,
    dismissed,
    snoozed,
    wrapUpAlreadyAlerted,
    overtimeAlreadyAlerted,
  } = input;
  if (dismissed || snoozed) return null;

  // Phase 1 — wrap-up alert (within the configured threshold before leave).
  if (remainingMinutes >= 0 && remainingMinutes <= thresholdMinutes) {
    return wrapUpAlreadyAlerted ? null : { kind: 'wrapUp', remainingMinutes };
  }

  // Phase 2 — overtime alert (up to OVERTIME_WINDOW_MINUTES past leave).
  if (remainingMinutes < 0 && remainingMinutes >= -OVERTIME_WINDOW_MINUTES) {
    return overtimeAlreadyAlerted ? null : { kind: 'overtime', remainingMinutes };
  }

  return null;
}
