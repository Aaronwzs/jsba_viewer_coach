import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:jsba_app/app/service/pwa_service.dart';

/// ViewModel managing PWA state including:
/// - Whether the PWA can be installed
/// - Whether the user is online/offline
/// - Whether a new app version is available
class PwaViewModel extends ChangeNotifier {
  bool _canInstall = false;
  bool _isOnline = true;
  bool _updateAvailable = false;
  bool _updateBannerDismissed = false;
  bool _installBannerDismissed = false;

  StreamSubscription<bool>? _installSub;
  StreamSubscription<bool>? _connectivitySub;
  StreamSubscription<bool>? _updateSub;

  PwaViewModel() {
    _isOnline = PwaService.isOnline;

    _installSub = PwaService.onInstallAvailable.listen((available) {
      _canInstall = available;
      // Reset dismissal state if install availability changes
      if (available) {
        _installBannerDismissed = false;
      }
      notifyListeners();
    });

    _connectivitySub = PwaService.onConnectivityChanged.listen((online) {
      _isOnline = online;
      notifyListeners();
    });

    _updateSub = PwaService.onUpdateAvailable.listen((_) {
      _updateAvailable = true;
      _updateBannerDismissed = false;
      notifyListeners();
    });

    PwaService.initialize();
  }

  /// Whether the browser supports PWA installation.
  bool get canInstall => _canInstall && !_installBannerDismissed;

  /// Whether the app is currently online.
  bool get isOnline => _isOnline;

  /// Whether a new app version has been detected (and not yet dismissed).
  bool get updateAvailable => _updateAvailable && !_updateBannerDismissed;

  /// Prompt the browser's native PWA install dialog.
  Future<void> promptInstall() async {
    await PwaService.promptInstall();
  }

  /// Dismiss the install prompt banner for the current session.
  void dismissInstall() {
    _installBannerDismissed = true;
    notifyListeners();
  }

  /// Dismiss the update available notification.
  void dismissUpdate() {
    _updateBannerDismissed = true;
    notifyListeners();
  }

  /// Apply the update by reloading the page with the new version.
  void applyUpdate() {
    _updateBannerDismissed = true;
    notifyListeners();
    PwaService.applyUpdate();
  }

  @override
  void dispose() {
    _installSub?.cancel();
    _connectivitySub?.cancel();
    _updateSub?.cancel();
    super.dispose();
  }
}
