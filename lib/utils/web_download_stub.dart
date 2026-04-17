// lib/utils/web_download_stub.dart
// This file acts as the common interface for web download functionality.
// It conditionally exports the web-specific implementation or a non-web stub.

export 'web_download_util.non_web.dart'
    if (dart.library.html) 'web_download_util.web.dart';
