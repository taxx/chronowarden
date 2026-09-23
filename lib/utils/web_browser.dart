// Platform-neutral browser bridge for notifications, audio and vibration.
//
// Keeps all `dart:html` / `dart:js` usage behind a conditional import so the
// Dart VM (and therefore `flutter test`) can compile the app. The VM stub is a
// no-op; these effects are web-only by nature.
export 'web_browser_stub.dart'
    if (dart.library.html) 'web_browser_web.dart';
