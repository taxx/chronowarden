// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:js';

import 'dart:html' as html;

/// Ask the browser for Notification permission. The permission is needed both
/// for OS-level alerts and as a prerequisite for showing notifications.
void requestNotificationPermission() {
  try {
    if (html.Notification.permission != 'granted') {
      html.Notification.requestPermission().then((_) {}).catchError((_) {});
    }
  } catch (_) {}
}

/// JS audio bridge.
///
/// A single shared [AudioContext] (`window._cwAudioCtx`) is created lazily and
/// reused for every beep. It must be created/resumed from a user gesture
/// (see [unlockAudio]); browsers keep it `suspended` otherwise, which is the
/// classic reason "the alert sound doesn't play".
const String _beepScript = r'''
window._cwEnsureAudioCtx = function() {
  try {
    var AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return null;
    if (!window._cwAudioCtx) window._cwAudioCtx = new AC();
    return window._cwAudioCtx;
  } catch (e) { return null; }
};
window._cwUnlockAudio = function() {
  var ctx = window._cwEnsureAudioCtx();
  if (ctx && ctx.state === 'suspended') {
    try { ctx.resume(); } catch (e) {}
  }
};
window._cwAudioState = function() {
  try { return window._cwAudioCtx ? window._cwAudioCtx.state : 'none'; }
  catch (e) { return 'error'; }
};
window._cwBeep = function(count) {
  var ctx = window._cwEnsureAudioCtx();
  if (!ctx) return;
  function play() {
    try {
      var t0 = ctx.currentTime;
      for (var i = 0; i < count; i++) {
        var start = t0 + i * 0.35;
        var osc = ctx.createOscillator();
        osc.type = 'sine';
        osc.frequency.value = 880;
        var gain = ctx.createGain();
        gain.gain.setValueAtTime(0.0001, start);
        gain.gain.exponentialRampToValueAtTime(0.5, start + 0.02);
        gain.gain.exponentialRampToValueAtTime(0.0001, start + 0.28);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(start);
        osc.stop(start + 0.3);
      }
    } catch (e) {}
  }
  if (ctx.state === 'suspended') {
    ctx.resume().then(play).catch(function() {});
  } else {
    play();
  }
};
''';

/// Register the JS beep helpers (idempotent).
void initBeepBridge() {
  try {
    context.callMethod('eval', [_beepScript]);
  } catch (_) {}
}

/// Create/resume the shared audio context. Must be called from a user gesture.
void unlockAudio() {
  try {
    context.callMethod('eval', ['window._cwUnlockAudio && window._cwUnlockAudio()']);
  } catch (_) {}
}

/// Current state of the shared audio context ("running"/"suspended"/"none"/…).
String audioState() {
  try {
    final result = context.callMethod(
      'eval',
      ['window._cwAudioState ? window._cwAudioState() : "none"'],
    );
    return result?.toString() ?? 'none';
  } catch (_) {
    return 'unsupported';
  }
}

/// Current browser Notification permission, or "unsupported" when unavailable.
String notificationPermission() {
  try {
    return html.Notification.permission ?? 'default';
  } catch (_) {
    return 'unsupported';
  }
}

/// Whether the device exposes the Vibration API.
bool vibrateSupported() {
  try {
    final navigator = context['navigator'] as JsObject?;
    return navigator?.hasProperty('vibrate') ?? false;
  } catch (_) {
    return false;
  }
}

/// Play [count] short beeps via the registered JS helper.
void playBeep(int count) {
  try {
    context.callMethod('eval', ['window._cwBeep && window._cwBeep($count)']);
  } catch (_) {}
}

/// Show an operating-system notification (works while the page is open, even
/// if its tab is in the background). No-op when permission isn't granted.
void showOsNotification(String title, String body, {bool urgent = false}) {
  try {
    if (html.Notification.permission != 'granted') return;
    html.Notification(
      title,
      body: body,
      tag: 'chronowarden-leave',
    );
  } catch (_) {
    // Safari on iOS (non-PWA) has no Notification constructor.
  }
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

// ---------------------------------------------------------------------------
// Server-Sent Events (cross-device sync)
// ---------------------------------------------------------------------------

html.EventSource? _eventSource;
void Function(String data)? _eventSourceHandler;

/// Open an SSE stream, replacing any previous one. `EventSource` reconnects
/// automatically after transient failures, so no retry logic is needed here.
void startEventStream(String url, void Function(String data) onData) {
  stopEventStream();
  try {
    final source = html.EventSource(url);
    _eventSource = source;
    _eventSourceHandler = onData;
    source.onMessage.listen((event) {
      final data = event.data;
      if (data is String && data.isNotEmpty) _eventSourceHandler?.call(data);
    });
    // Errors (including the automatic reconnect) need no handling here.
    source.onError.listen((_) {});
  } catch (_) {
    _eventSource = null;
    _eventSourceHandler = null;
  }
}

/// Close the current SSE stream, if any.
void stopEventStream() {
  try {
    _eventSource?.close();
  } catch (_) {}
  _eventSource = null;
  _eventSourceHandler = null;
}
