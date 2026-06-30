/// CSV import utilities for bulk-loading TimeLog entries.
///
/// ## Expected CSV format (header row required)
library;
///
/// ```
/// date,start_time,end_time,expected_minutes,overhead_minutes,lunch_minutes,note
/// ```
///
/// ### Column reference
///
/// | Column             | Type     | Required | Description                                      |
/// |--------------------|----------|----------|--------------------------------------------------|
/// | `date`             | `YYYY-MM-DD` | ✅  | Calendar date of the workday                   |
/// | `start_time`       | `HH:MM:SS`   | ✅  | Clock-in time (24-hour format)                 |
/// | `end_time`         | `HH:MM:SS`   | —  | Clock-out time. Leave empty for active days    |
/// | `expected_minutes` | integer  | ✅       | Contractual work minutes (e.g. 480 for 8h)      |
/// | `overhead_minutes` | integer  | ✅       | Commute / prep overhead minutes                 |
/// | `lunch_minutes`    | integer  | —       | Unpaid lunch break duration (default = 0)       |
/// | `note`             | string   | —       | Optional free-text note                         |
///
/// ### Example
///
/// ```csv
/// date,start_time,end_time,expected_minutes,overhead_minutes,lunch_minutes,note
/// 2026-01-15,08:00:00,16:30:00,480,60,30,Office day
/// 2026-01-16,09:00:00,,480,45,0,
/// ```
///
/// Rows that fail validation are collected and reported; valid rows are
/// imported. Existing logs with the same `(user_id, date)` are **not**
/// overwritten — they are skipped to prevent accidental data loss.
///
/// ---
///
/// ## Format reference (also shown in the import dialog)
///
/// Each row must have **exactly 7 comma-separated fields** (trailing
/// commas allowed for empty optional fields). Whitespace is stripped.
///
/// ```
/// date,start,end,expected_min,overhead_min,lunch_min,note
/// ```
///
/// **Rules:**
///   - `date`         — `YYYY-MM-DD`
///   - `start_time`   — `HH:MM:SS` (24h)
///   - `end_time`     — `HH:MM:SS` or empty
///   - `expected_min` — integer ≥ 0
///   - `overhead_min` — integer ≥ 0
///   - `lunch_min`    — integer ≥ 0 (omit or 0 = no lunch)
///   - `note`         — any text (use quotes if it contains commas)
///
import '../models/time_log.dart';

/// Result of a CSV import operation.
class ImportResult {
  final List<TimeLog> imported;
  final List<String> errors;
  final int skipped; // rows skipped because log already exists for that date

  const ImportResult({
    required this.imported,
    required this.errors,
    this.skipped = 0,
  });

  int get totalRows => imported.length + errors.length + skipped;

  bool get hasErrors => errors.isNotEmpty;
}

/// Parse a CSV string (with header) into a list of [TimeLog] objects.
///
/// Returns an [ImportResult] with imported logs, parse errors, and skip
/// count. The [existingDates] set lets the caller supply already-logged
/// dates to avoid duplicates.
ImportResult parseCsvTimeLogs(
  String csv, {
  String? userId,
  Set<String>? existingDates,
}) {
  final lines = csv.split('\n');
  final imported = <TimeLog>[];
  final errors = <String>[];
  var skipped = 0;

  if (lines.isEmpty) {
    return const ImportResult(imported: [], errors: ['CSV is empty']);
  }

  // Find header row (first non-empty line that starts with 'date')
  int headerIndex = -1;
  for (var i = 0; i < lines.length; i++) {
    final trimmed = lines[i].trim();
    if (trimmed.isEmpty) continue;
    if (trimmed.startsWith('date')) {
      headerIndex = i;
      break;
    }
  }

  if (headerIndex == -1) {
    return const ImportResult(
      imported: [],
      errors: ['Missing header row — first line must start with "date"'],
    );
  }

  for (var i = headerIndex + 1; i < lines.length; i++) {
    final raw = lines[i].trim();
    if (raw.isEmpty) continue;

    final result = _parseRow(raw, userId, existingDates ?? {});
    if (result.error != null) {
      errors.add('Line ${i + 1}: ${result.error}');
    } else if (result.skipped) {
      skipped++;
    } else if (result.log != null) {
      imported.add(result.log!);
    }
  }

  return ImportResult(imported: imported, errors: errors, skipped: skipped);
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

/// Parsed result for a single CSV row.
class _RowResult {
  final TimeLog? log;
  final String? error;
  final bool skipped;

  const _RowResult({this.log, this.error, this.skipped = false});
}

_RowResult _parseRow(String line, String? userId, Set<String> existingDates) {
  // Split on commas, respecting basic quoted strings.
  final fields = _csvSplit(line);
  if (fields.length < 5) {
    return _RowResult(error: 'Expected at least 5 fields, got ${fields.length}');
  }

  final date = fields[0].trim();
  final startTime = fields[1].trim();
  final endTime = fields.length > 2 ? fields[2].trim() : '';
  final expectedStr = fields.length > 3 ? fields[3].trim() : '';
  final overheadStr = fields.length > 4 ? fields[4].trim() : '';
  final lunchStr = fields.length > 5 ? fields[5].trim() : '';
  final note = fields.length > 6 ? fields[6].trim() : '';

  // Validate date format
  if (date.isEmpty) return _RowResult(error: 'Date is empty');
  final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  if (!dateRegex.hasMatch(date)) {
    return _RowResult(error: 'Invalid date format "$date" — expected YYYY-MM-DD');
  }

  // Validate start_time format
  final timeRegex = RegExp(r'^\d{2}:\d{2}:\d{2}$');
  if (startTime.isEmpty) return _RowResult(error: 'Start time is empty');
  if (!timeRegex.hasMatch(startTime)) {
    return _RowResult(error: 'Invalid start_time "$startTime" — expected HH:MM:SS');
  }

  // Validate end_time (if provided)
  if (endTime.isNotEmpty && !timeRegex.hasMatch(endTime)) {
    return _RowResult(error: 'Invalid end_time "$endTime" — expected HH:MM:SS');
  }

  // Parse integers
  final expected = _parseInt(expectedStr, 'expected_minutes');
  if (expected == null) return _RowResult(error: 'Invalid expected_minutes "$expectedStr"');

  final overhead = _parseInt(overheadStr, 'overhead_minutes');
  if (overhead == null) return _RowResult(error: 'Invalid overhead_minutes "$overheadStr"');

  final lunch = _parseInt(lunchStr, 'lunch_minutes') ?? 0;

  // Check for duplicate
  if (existingDates.contains(date)) {
    return _RowResult(skipped: true);
  }

  // Build TimeLog — overtime will be recalculated by AppState
  final log = TimeLog(
    userId: userId,
    date: date,
    startTime: startTime,
    endTime: endTime.isEmpty ? null : endTime,
    expectedMinutes: expected,
    overheadMinutes: overhead,
    lunchMinutes: lunch,
    overtimeMinutes: 0, // recalculated on insert
    note: note.isEmpty ? null : note,
  );

  return _RowResult(log: log);
}

/// Simple CSV field splitter that handles quoted values containing commas.
List<String> _csvSplit(String line) {
  final fields = <String>[];
  var current = StringBuffer();
  var inQuotes = false;

  for (var i = 0; i < line.length; i++) {
    final ch = line[i];
    if (ch == '"') {
      inQuotes = !inQuotes;
    } else if (ch == ',' && !inQuotes) {
      fields.add(current.toString());
      current = StringBuffer();
    } else {
      current.write(ch);
    }
  }
  fields.add(current.toString());
  return fields;
}

int? _parseInt(String str, String fieldName) {
  if (str.isEmpty) return null;
  final trimmed = str.trim();
  final value = int.tryParse(trimmed);
  if (value == null) return null;
  if (value < 0) return null;
  return value;
}
