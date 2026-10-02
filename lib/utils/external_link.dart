import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [url] in the browser (web) or the platform's external app.
///
/// Shows a snackbar and returns `false` when no handler is available, so the
/// URL is never silently swallowed.
Future<bool> openExternalLink(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final uri = Uri.tryParse(url);
  if (uri != null) {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return true;
      }
    } catch (_) {
      // Fall through to the error snackbar below.
    }
  }
  messenger?.showSnackBar(SnackBar(content: Text('Could not open $url')));
  return false;
}
