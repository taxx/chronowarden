/// Data model for the app changelog ("What's New").
///
/// The changelog is generated from the git history by
/// `tool/generate_changelog.sh` into `CHANGELOG.md`, shipped as a Flutter
/// asset, and parsed here with [parseChangelog].
library;

/// A single changelog line (one commit).
class ChangelogEntry {
  /// Human-readable summary, e.g. "Add report-issue button to the app bar".
  final String text;

  /// Short commit hash, when present.
  final String? hash;

  const ChangelogEntry({required this.text, this.hash});
}

/// All entries for one commit date.
class ChangelogGroup {
  /// ISO date ("YYYY-MM-DD").
  final String date;
  final List<ChangelogEntry> entries;

  const ChangelogGroup({required this.date, required this.entries});
}

/// Parse the Markdown produced by `tool/generate_changelog.sh`.
///
/// The format is intentionally tiny so the app needs no Markdown dependency:
///
/// ```markdown
/// # Changelog
///
/// ## 2026-10-09
///
/// - Some change (`abc1234`)
/// ```
///
/// Lines before the first `##` heading and unrecognised lines are ignored.
/// Returns an empty list for input with no entries.
List<ChangelogGroup> parseChangelog(String markdown) {
  final groups = <ChangelogGroup>[];
  String? currentDate;
  var currentEntries = <ChangelogEntry>[];

  void flush() {
    final date = currentDate;
    if (date != null) {
      groups.add(ChangelogGroup(date: date, entries: currentEntries));
    }
    currentEntries = <ChangelogEntry>[];
  }

  for (final raw in markdown.split('\n')) {
    final line = raw.trim();

    if (line.startsWith('## ')) {
      flush();
      currentDate = line.substring(3).trim();
      continue;
    }

    if (currentDate != null && line.startsWith('- ')) {
      currentEntries.add(_parseEntry(line.substring(2).trim()));
    }
  }

  flush();
  return groups;
}

/// Extract a trailing ``(`hash`)`` from an entry, if present.
ChangelogEntry _parseEntry(String text) {
  final match = RegExp(r'^(.*?)\s*\(`([0-9a-fA-F]{7,40})`\)$').firstMatch(text);
  if (match == null) return ChangelogEntry(text: text);
  return ChangelogEntry(
    text: match.group(1)!.trim(),
    hash: match.group(2),
  );
}
