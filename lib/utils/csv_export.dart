import '../models/time_log.dart';
import 'web_download.dart';

/// Generates a CSV string from a list of [TimeLog] entries, compatible with
/// the CSV import format (including productive_commute_minutes).
String timeLogsToCsv(List<TimeLog> logs) {
  final buf = StringBuffer();

  // Header row
  buf.writeln('date,start_time,end_time,expected_minutes,overhead_minutes,lunch_minutes,productive_commute_minutes,note');

  for (final log in logs) {
    final date = log.date;
    final start = log.startTime;
    final end = log.endTime ?? '';
    final expected = log.expectedMinutes;
    final overhead = log.overheadMinutes;
    final lunch = log.lunchMinutes;
    final commute = log.productiveCommuteMinutes;
    final note = _csvEscape(log.note ?? '');

    buf.writeln('$date,$start,$end,$expected,$overhead,$lunch,$commute,$note');
  }

  return buf.toString();
}

/// Escape a string for CSV: wrap in quotes if it contains commas or newlines.
String _csvEscape(String value) {
  if (value.contains(',') || value.contains('\n') || value.contains('"')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

/// Trigger a browser download of the CSV content.
void downloadCsv(String csv, String filename) {
  downloadTextFile(csv, filename, 'text/csv');
}
