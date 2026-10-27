// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

/// Trigger a browser download of [content] as [filename].
void downloadTextFile(String content, String filename, String mimeType) {
  final blob = html.Blob([content], mimeType);
  final url = html.Url.createObjectUrl(blob);
  html.AnchorElement()
    ..href = url
    ..download = filename
    ..click();
  html.Url.revokeObjectUrl(url);
}
