import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:jsba_app/app/assets/constants/environment_config.dart';
import 'package:jsba_app/app/assets/firebase_options/staging_firebase_options.dart';
import 'package:jsba_app/app/assets/firebase_options/production_firebase_options.dart';
import 'package:jsba_app/app/service/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory + persistent flag for whether the user had a prior login session.
///
/// This value is also persisted to SharedPreferences so it survives page
/// reloads on web. On init(), it is restored from SharedPreferences so
/// checkAuth() can tell if this is a returning user.
String? cachedLoggedInUid;

/// Key used to persist the logged-in UID in SharedPreferences.
const String _kLoggedInUidKey = 'jsba_logged_in_uid';

/// Persist the UID to both [cachedLoggedInUid] and SharedPreferences.
Future<void> writeCachedLoggedInUid(String? uid) async {
  cachedLoggedInUid = uid;
  try {
    WidgetsFlutterBinding.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    if (uid != null) {
      await prefs.setString(_kLoggedInUidKey, uid);
    } else {
      await prefs.remove(_kLoggedInUidKey);
    }
  } catch (e) {
    debugPrint('[startup] SharedPreferences write skipped: $e');
  }
}

/// Restore [cachedLoggedInUid] from SharedPreferences.
Future<void> _restoreCachedLoggedInUid() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    cachedLoggedInUid = prefs.getString(_kLoggedInUidKey);
  } catch (e) {
    cachedLoggedInUid = null;
    debugPrint('[startup] SharedPreferences restore skipped: $e');
  }
}

FirebaseOptions getFirebaseOptions() {
  switch (appEnvironmentType) {
    case EnvironmentType.staging:
      return StagingFirebaseOptions.currentPlatform;
    case EnvironmentType.production:
      return ProductionFirebaseOptions.currentPlatform;
  }
}

/// Hard cap: init() must not block runApp() for more than this on web.
/// Increased from 6s to 15s to give Firebase JS SDK CDN scripts enough
/// time to load on slow connections. The SplashScreen 5s safety timer
/// still handles the "auth hangs" case independently.
const Duration _kInitTimeout = Duration(seconds: 15);

/// Initialize app services. On web, races against a 15-second timeout so
/// the app always renders even if Firebase or SharedPreferences hang.
/// On mobile, must complete fully before runApp().
Future<void> init() async {
  if (kIsWeb) {
    try {
      await _initFull().timeout(_kInitTimeout);
    } on TimeoutException {
      debugPrint('[startup] init() timed out after ${_kInitTimeout.inSeconds}s — continuing');
    } catch (e) {
      debugPrint('[startup] init() error: $e — continuing');
    }
  } else {
    await _initFull();
  }
}

Future<void> _initFull() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _restoreCachedLoggedInUid();

  await _initFirebase();

  await initApiServices();
}

Future<void> _initFirebase() async {
  if (Firebase.apps.isNotEmpty) return;
  try {
    await Firebase.initializeApp(
      options: getFirebaseOptions(),
    );
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      debugPrint('[startup] Firebase init failed: $e');
    }
  }
}

/// Singleton accessor for NotificationService used across the app
NotificationService get notificationService {
  _ensureNotificationService();
  return _notificationService!;
}

NotificationService? _notificationService;

void _ensureNotificationService() {
  _notificationService ??= NotificationService();
}

Future<void> initApiServices() async {
  if (kIsWeb) return;

  _ensureNotificationService();
  try {
    await _notificationService!.initialize();
  } catch (e) {
    debugPrint('[startup] Notification service initialization skipped: $e');
  }
}
