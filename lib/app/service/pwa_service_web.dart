import 'dart:async';
import 'dart:html' as html;
import 'dart:js_interop';

/// Web-specific PWA service implementation using [dart:html].
///
/// Handles:
/// - `beforeinstallprompt` / `appinstalled` events for install prompt
/// - `online` / `offline` events for connectivity
/// - Service worker lifecycle for update detection
class PwaService {
  PwaService._();

  static bool _initialized = false;

  static final StreamController<bool> _installController =
      StreamController<bool>.broadcast();
  static final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();
  static final StreamController<bool> _updateController =
      StreamController<bool>.broadcast();

  /// Emits `true` when PWA can be installed, `false` when dismissed/installed.
  static Stream<bool> get onInstallAvailable => _installController.stream;

  /// Emits `true` when online, `false` when offline.
  static Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  /// Emits `true` when a new app version is available.
  static Stream<bool> get onUpdateAvailable => _updateController.stream;

  /// Whether the user is currently online.
  static bool get isOnline => html.window.navigator.onLine ?? true;

  /// Initialize listeners for PWA events.
  static void initialize() {
    if (_initialized) return;
    _initialized = true;

    _setupInstallPrompt();
    _setupConnectivity();
    _setupServiceWorker();
  }

  static void _setupInstallPrompt() {
    html.window.addEventListener(
      'beforeinstallprompt',
      (html.Event event) {
        event.preventDefault();
        if (!_installController.isClosed) {
          _installController.add(true);
        }
      },
    );

    html.window.addEventListener(
      'appinstalled',
      (_) {
        if (!_installController.isClosed) {
          _installController.add(false);
        }
      },
    );
  }

  static void _setupConnectivity() {
    html.window.addEventListener('online', (_) {
      if (!_connectivityController.isClosed) {
        _connectivityController.add(true);
      }
    });

    html.window.addEventListener('offline', (_) {
      if (!_connectivityController.isClosed) {
        _connectivityController.add(false);
      }
    });
  }

  static void _setupServiceWorker() {
    try {
      final sw = html.window.navigator.serviceWorker;
      if (sw == null) return;

      // Listen for SW taking control (fires when a new SW activates).
      // This triggers after applyUpdate() -> location.reload() in production
      // when a new service worker version is deployed.
      sw.addEventListener('controllerchange', (_) {
        html.window.location.reload();
      });

      // Defensively listen for updates:
      // getRegistration() has a non-nullable Future return type in dart:html,
      // but JS can resolve with undefined (no SW registered), causing a
      // runtime type error. Guard by checking for an active controller first.
      _tryListenForUpdates(sw);
    } catch (_) {
      // Silently fail on older browsers
    }
  }

  /// Defensively get the SW registration and set up update listeners.
  ///
  /// Skips if there's no active service worker controller (which is always
  /// the case in development mode via `flutter run -d chrome`), avoiding
  /// the runtime type error from `getRegistration()` resolving to JS
  /// `undefined` when the non-nullable `Future<ServiceWorkerRegistration>`
  /// type from `dart:html` cannot accept `null`.
  static void _tryListenForUpdates(html.ServiceWorkerContainer sw) {
    // No active SW controller = no registration to check.
    // This avoids the non-nullable Future type error entirely.
    if (sw.controller == null) return;

    try {
      sw.getRegistration().then((registration) {
        if (registration == null) return;
        _onRegistrationReady(registration);
      }).catchError((_) {
        // getRegistration failed (dev mode, HTTP, etc.)
      });
    } catch (_) {
      // Synchronous error during getRegistration call
    }
  }

  /// Set up update detection on the registration.
  static void _onRegistrationReady(
      html.ServiceWorkerRegistration registration) {
    // Check if there's already a waiting update
    if (registration.waiting != null) {
      _notifyUpdateAvailable();
    }

    // Listen for future updates
    registration.addEventListener('updatefound', (_) {
      final installing = registration.installing;
      if (installing != null) {
        installing.addEventListener('statechange', (_) {
          if (installing.state == 'installed') {
            _notifyUpdateAvailable();
          }
        });
      }
    });
  }

  /// Emit update available event if the controller is not closed.
  static void _notifyUpdateAvailable() {
    if (!_updateController.isClosed) {
      _updateController.add(true);
    }
  }

  /// Prompt the browser's native PWA install dialog.
  /// The actual `prompt()` call is delegated to a JS function defined
  /// in `index.html` to avoid complex JS interop with custom event types.
  static Future<void> promptInstall() async {
    _callNativeInstallPrompt();
    if (!_installController.isClosed) {
      _installController.add(false);
    }
  }

  /// Apply the app update by reloading the page.
  /// The new service worker will take over on the next page load.
  static void applyUpdate() {
    html.window.location.reload();
  }
}

/// JS interop to call `window.triggerPwaInstall()` defined in `index.html`.
@JS('triggerPwaInstall')
external void _callNativeInstallPrompt();
