import 'dart:async';

/// Stub PWA service for non-web platforms.
/// All operations are no-ops since PWA features are web-only.
class PwaService {
  PwaService._();

  /// Stream indicating whether PWA installation is available (`true`)
  /// or was completed/dismissed (`false`).
  static Stream<bool> get onInstallAvailable => const Stream.empty();

  /// Stream indicating connectivity changes (`true` = online, `false` = offline).
  static Stream<bool> get onConnectivityChanged => const Stream.empty();

  /// Stream indicating a new app version is available to install.
  static Stream<bool> get onUpdateAvailable => const Stream.empty();

  /// Whether the user is currently online.
  static bool get isOnline => true;

  /// Initialize the PWA service (listeners, etc.).
  static void initialize() {}

  /// Prompt the user to install the PWA.
  static Future<void> promptInstall() async {}

  /// Apply the app update (reloads the page on web).
  static void applyUpdate() {}
}
