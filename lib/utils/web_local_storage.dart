// Platform-neutral localStorage facade.
//
// ChronoWarden targets Flutter Web, but `flutter test` runs on the Dart VM
// where `dart:html` is unavailable. Conditional imports let the same call
// sites compile everywhere: web uses the real localStorage, the VM stub is a
// no-op (the DEK cache is a convenience, never a correctness requirement).
export 'web_local_storage_stub.dart'
    if (dart.library.html) 'web_local_storage_web.dart';
