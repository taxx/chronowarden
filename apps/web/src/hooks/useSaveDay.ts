import type { DayFormValues } from '../components/DayDialog';
import { calculateOvertimeMinutes, copyWithTimeLog, type TimeLog } from '../lib/domain/time-log';
import { useCreateTimeLog, useUpdateTimeLog } from '../queries/time-logs';

/**
 * Create or update a day from the shared day dialog, recomputing overtime.
 * Used by History and the Overview calendar.
 */
export function useSaveDay() {
  const createLog = useCreateTimeLog();
  const updateLog = useUpdateTimeLog();

  async function saveDay(values: DayFormValues, existing: TimeLog | null): Promise<void> {
    const commute = {
      morningOverheadMinutes: values.morningOverheadMinutes,
      morningProductiveCommuteMinutes: values.morningProductiveCommuteMinutes,
      eveningOverheadMinutes: values.eveningOverheadMinutes,
      eveningProductiveCommuteMinutes: values.eveningProductiveCommuteMinutes,
    };

    if (existing?.id) {
      const endTime = values.endTime || null;
      const next = copyWithTimeLog(existing, {
        startTime: values.startTime,
        endTime,
        expectedMinutes: values.expectedMinutes,
        lunchMinutes: values.lunchMinutes,
        nonWorkMinutes: values.nonWorkMinutes,
        note: values.note,
        ...commute,
      });
      await updateLog.mutateAsync({
        id: existing.id,
        fields: {
          start_time: values.startTime,
          end_time: endTime,
          expected_minutes: values.expectedMinutes,
          lunch_minutes: values.lunchMinutes,
          non_work_minutes: values.nonWorkMinutes,
          note: values.note,
          morning_overhead_minutes: values.morningOverheadMinutes,
          morning_productive_commute_minutes: values.morningProductiveCommuteMinutes,
          evening_overhead_minutes: values.eveningOverheadMinutes,
          evening_productive_commute_minutes: values.eveningProductiveCommuteMinutes,
          overtime_minutes: calculateOvertimeMinutes(next),
        },
      });
      return;
    }

    const log: TimeLog = {
      date: values.date,
      startTime: values.startTime,
      endTime: values.endTime || null,
      expectedMinutes: values.expectedMinutes,
      lunchMinutes: values.lunchMinutes,
      nonWorkMinutes: values.nonWorkMinutes,
      flexMinutes: 0,
      ...commute,
      overtimeMinutes: 0,
      note: values.note,
    };
    await createLog.mutateAsync({ ...log, overtimeMinutes: calculateOvertimeMinutes(log) });
  }

  return { saveDay, isPending: createLog.isPending || updateLog.isPending };
}
