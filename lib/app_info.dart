/// Central place for project metadata and the public links shown in the app.
///
/// Keep every user-facing reference to the open-source project here so the
/// GitHub URL only ever has to change in one place.
class AppInfo {
  AppInfo._();

  static const String name = 'ChronoWarden';
  static const String tagline = 'Personal time-banking & overtime protection';
  static const String version = '0.1.0';

  /// Public source repository.
  static const String repoUrl = 'https://github.com/taxx/chronowarden';

  /// Where users report bugs and request features.
  static const String issuesUrl = '$repoUrl/issues';

  /// Self-hosting / contributor documentation.
  static const String readmeUrl = '$repoUrl/blob/main/README.md';

  /// The full license text.
  static const String licenseUrl = '$repoUrl/blob/main/LICENSE';
  static const String licenseName = 'MIT License';

  /// The instance hosted by the maintainer. Best effort, no guarantees.
  static const String hostedUrl = 'https://chronowarden.slumpen.com/';
}
