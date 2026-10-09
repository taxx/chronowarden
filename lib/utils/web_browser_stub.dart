/// Non-web fallback for `web_browser.dart` (Dart VM / tests).
library;

/// Ask the browser for Notification permission (no-op off web).
void requestNotificationPermission() {}

/// Register the JS `window._cwBeep` helper used for alert sounds.
void initBeepBridge() {}

/// Play [count] short beeps via the JS helper.
void playBeep(int count) {}

/// Trigger a short device vibration for [milliseconds].
void vibrate(int milliseconds) {}

/// Fetch a text resource (no-op off web; returns null).
Future<String?> fetchText(String url) async => null;

/// Invoke [callback] whenever the page becomes visible again (no-op off web).
void onPageVisible(void Function() callback) {}

/// Reload the current page (no-op off web).
void reloadPage() {}
