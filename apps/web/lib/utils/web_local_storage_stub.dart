/// Non-web fallback for `web_local_storage.dart` (Dart VM / tests).
library;

String? readLocalStorage(String key) => null;

void writeLocalStorage(String key, String value) {}

void removeLocalStorage(String key) {}
