// Platform-neutral file-download facade (used by CSV export).
export 'web_download_stub.dart'
    if (dart.library.html) 'web_download_web.dart';
