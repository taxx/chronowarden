// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:js';

/// Ask the browser for Notification permission. We only need the permission
/// itself; the actual alert is rendered in-app (overlay + beep + vibration).
void requestNotificationPermission() {
  try {
    if (html.Notification.permission != 'granted') {
      html.Notification.requestPermission().then((_) {}).catchError((_) {});
    }
  } catch (_) {}
}

/// Register a JS beep function via eval (Web Audio API).
void initBeepBridge() {
  try {
    context.callMethod('eval', [
      'window._cwBeep = function(count) {'
          'var ctx = new (window.AudioContext || window.webkitAudioContext)();'
          'for (var i = 0; i < count; i++) {'
            'var now = ctx.currentTime;'
            'var osc = ctx.createOscillator();'
            'osc.frequency.value = 440;'
            'var gain = ctx.createGain();'
            'gain.gain.value = 0.3;'
            'osc.connect(gain);'
            'gain.connect(ctx.destination);'
            'osc.start(now + i * 0.5);'
            'osc.stop(now + i * 0.5 + 0.3);'
          '}'
      '}'
    ]);
  } catch (_) {}
}

/// Play [count] short beeps via the registered JS helper.
void playBeep(int count) {
  try {
    context.callMethod('eval', ['window._cwBeep($count)']);
  } catch (_) {}
}

/// Trigger a short vibration via the Navigator API (no permission needed).
void vibrate(int milliseconds) {
  try {
    final navigator = context['navigator'] as JsObject?;
    navigator?.callMethod('vibrate', [milliseconds]);
  } catch (_) {}
}

/// Fetch a text resource (used to poll the server's `version.json`).
/// Returns null on any failure so callers can treat it as "no update info".
Future<String?> fetchText(String url) async {
  try {
    return await html.HttpRequest.getString(url);
  } catch (_) {
    return null;
  }
}

/// Invoke [callback] whenever the page becomes visible again. Lets a
/// long-lived tab re-check for updates as soon as the user returns to it.
void onPageVisible(void Function() callback) {
  try {
    html.document.onVisibilityChange.listen((_) {
      if (html.document.hidden != true) callback();
    });
  } catch (_) {}
}

/// Reload the current page, picking up a newly deployed build.
void reloadPage() {
  try {
    html.window.location.reload();
  } catch (_) {}
}
