import { overheadMinutes, productiveCommuteMinutes, type TimeLog } from './time-log';

/**
 * CSV export / import for time logs.
 *
 * Ported from the Flutter client (`csv_export.dart` / `csv_import.dart`) so the
 * format stays compatible: `non_work_minutes` is the last column, so older CSVs
 * (without it) still import.
 */

export function timeLogsToCsv(logs: TimeLog[]): string {
  const lines = [
    'date,start_time,end_time,expected_minutes,overhead_minutes,lunch_minutes,productive_commute_minutes,note,non_work_minutes',
  ];
  for (const log of logs) {
    lines.push(
      [
        log.date,
        log.startTime,
        log.endTime ?? '',
        log.expectedMinutes,
        overheadMinutes(log),
        log.lunchMinutes,
        productiveCommuteMinutes(log),
        csvEscape(log.note ?? ''),
        log.nonWorkMinutes,
      ].join(','),
    );
  }
  return `${lines.join('\n')}\n`;
}

function csvEscape(value: string): string {
  if (value.includes(',') || value.includes('\n') || value.includes('"')) {
    return `"${value.replaceAll('"', '""')}"`;
  }
  return value;
}

export interface ImportResult {
  imported: TimeLog[];
  errors: string[];
  skipped: number;
}

const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;
const TIME_RE = /^\d{2}:\d{2}:\d{2}$/;

function parseIntOrNull(value: string): number | null {
  const trimmed = value.trim();
  if (!trimmed) return null;
  const parsed = Number(trimmed);
  if (!Number.isInteger(parsed) || parsed < 0) return null;
  return parsed;
}

/** Split a CSV line on commas, honouring quoted fields. */
function splitFields(line: string): string[] {
  const fields: string[] = [];
  let current = '';
  let inQuotes = false;
  for (const ch of line) {
    if (ch === '"') {
      inQuotes = !inQuotes;
    } else if (ch === ',' && !inQuotes) {
      fields.push(current);
      current = '';
    } else {
      current += ch;
    }
  }
  fields.push(current);
  return fields;
}

export function parseCsvTimeLogs(csv: string, existingDates: Set<string> = new Set()): ImportResult {
  const lines = csv.split('\n');
  const imported: TimeLog[] = [];
  const errors: string[] = [];
  let skipped = 0;

  const headerIndex = lines.findIndex((line) => line.trim().startsWith('date'));
  if (headerIndex === -1) {
    return { imported: [], errors: ['Missing header row — first line must start with "date"'], skipped: 0 };
  }

  for (let i = headerIndex + 1; i < lines.length; i++) {
    const raw = lines[i]!.trim();
    if (!raw) continue;

    const fields = splitFields(raw);
    if (fields.length < 5) {
      errors.push(`Line ${i + 1}: Expected at least 5 fields, got ${fields.length}`);
      continue;
    }

    const date = fields[0]!.trim();
    const startTime = fields[1]!.trim();
    const endTime = (fields[2] ?? '').trim();
    const expectedStr = (fields[3] ?? '').trim();
    const overheadStr = (fields[4] ?? '').trim();
    const lunchStr = (fields[5] ?? '').trim();
    const commuteStr = (fields[6] ?? '').trim();
    const note = (fields[7] ?? '').trim();
    const nonWorkStr = (fields[8] ?? '').trim();

    if (!DATE_RE.test(date)) {
      errors.push(`Line ${i + 1}: Invalid date format "${date}" — expected YYYY-MM-DD`);
      continue;
    }
    if (!TIME_RE.test(startTime)) {
      errors.push(`Line ${i + 1}: Invalid start_time "${startTime}" — expected HH:MM:SS`);
      continue;
    }
    if (endTime && !TIME_RE.test(endTime)) {
      errors.push(`Line ${i + 1}: Invalid end_time "${endTime}" — expected HH:MM:SS`);
      continue;
    }

    const expected = parseIntOrNull(expectedStr);
    if (expected === null) {
      errors.push(`Line ${i + 1}: Invalid expected_minutes "${expectedStr}"`);
      continue;
    }
    const overhead = parseIntOrNull(overheadStr);
    if (overhead === null) {
      errors.push(`Line ${i + 1}: Invalid overhead_minutes "${overheadStr}"`);
      continue;
    }

    if (existingDates.has(date)) {
      skipped++;
      continue;
    }

    const lunch = parseIntOrNull(lunchStr) ?? 0;
    const nonWork = parseIntOrNull(nonWorkStr) ?? 0;
    const totalProductive = parseIntOrNull(commuteStr) ?? 0;

    // Legacy CSV carries totals; split them 50/50 per direction.
    const morningOverhead = Math.trunc(overhead / 2);
    const morningProductive = Math.trunc(totalProductive / 2);

    imported.push({
      date,
      startTime,
      endTime: endTime || null,
      expectedMinutes: expected,
      lunchMinutes: lunch,
      nonWorkMinutes: nonWork,
      flexMinutes: 0,
      morningOverheadMinutes: morningOverhead,
      morningProductiveCommuteMinutes: morningProductive,
      eveningOverheadMinutes: overhead - morningOverhead,
      eveningProductiveCommuteMinutes: totalProductive - morningProductive,
      overtimeMinutes: 0,
      note: note || null,
    });
  }

  return { imported, errors, skipped };
}
