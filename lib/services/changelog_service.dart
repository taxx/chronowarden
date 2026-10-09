import 'package:flutter/services.dart' show rootBundle;

import '../models/changelog.dart';

/// Loads and caches the app changelog.
///
/// The Markdown is generated from the git history by
/// `tool/generate_changelog.sh` and shipped as a Flutter asset.
class ChangelogService {
  ChangelogService._();
  static final ChangelogService _instance = ChangelogService._();
  factory ChangelogService() => _instance;

  /// Asset path, declared in `pubspec.yaml`.
  static const String assetPath = 'CHANGELOG.md';

  List<ChangelogGroup>? _cache;

  /// Load the changelog, parsing it on first use.
  Future<List<ChangelogGroup>> load() async {
    final cached = _cache;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(assetPath);
    return _cache = parseChangelog(raw);
  }
}
