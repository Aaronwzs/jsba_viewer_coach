// PWA service that provides install prompt, connectivity monitoring,
// and service worker update detection.
// On web platforms, uses [dart:html] for PWA events.
// On non-web platforms, all operations are no-ops.

export 'pwa_service_stub.dart'
  if (dart.library.html) 'pwa_service_web.dart';
