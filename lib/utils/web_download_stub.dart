/// Non-web fallback for `web_download.dart` (Dart VM / tests).
///
/// Browser downloads are web-only; off web this is intentionally a no-op.
library;

void downloadTextFile(String content, String filename, String mimeType) {}
