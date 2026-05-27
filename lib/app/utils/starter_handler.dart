import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:jsba_app/app/assets/constants/environment_config.dart';
import 'package:jsba_app/app/assets/firebase_options/staging_firebase_options.dart';
import 'package:jsba_app/app/assets/firebase_options/production_firebase_options.dart';
import 'package:jsba_app/app/service/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🏷 In-memory + persistent flag for whether the user had a prior login session.
///
/// This value is also persisted to SharedPreferences so it survives page
/// reloads on web. On init(), it is restored from SharedPreferences so
/// checkAuth() can tell if this is a returning user and wait long enough
/// for Firebase IndexedDB to resolve.
String? cachedLoggedInUid;

/// Key used to persist the logged-in UID in SharedPreferences.
const String _kLoggedInUidKey = 'jsba_logged_in_uid';

/// Persist the UID to both [cachedLoggedInUid] and SharedPreferences.
///
/// SharedPreferences writes to localStorage on web (survives reload) and
/// to native storage on mobile platforms.
Future<void> writeCachedLoggedInUid(String? uid) async {
  cachedLoggedInUid = uid;
  final prefs = await SharedPreferences.getInstance();
  if (uid != null) {
    await prefs.setString(_kLoggedInUidKey, uid);
  } else {
    await prefs.remove(_kLoggedInUidKey);
  }
}

/// Restore [cachedLoggedInUid] from SharedPreferences.
///
/// Must be called during init() so the value is available when checkAuth()
/// runs after the first frame.
Future<void> _restoreCachedLoggedInUid() async {
  final prefs = await SharedPreferences.getInstance();
  cachedLoggedInUid = prefs.getString(_kLoggedInUidKey);
}

FirebaseOptions getFirebaseOptions() {
  switch (appEnvironmentType) {
    case EnvironmentType.staging:
      return StagingFirebaseOptions.currentPlatform;
    case EnvironmentType.production:
      return ProductionFirebaseOptions.currentPlatform;
  }
}

Future<void> init() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restore the cached UID from persistent storage BEFORE runApp().
  // This ensures checkAuth() can distinguish returning vs first-visit users
  // even after a full page reload on web.
  await _restoreCachedLoggedInUid();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: getFirebaseOptions());
    }
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      // App already initialized, ignore
    } else {
      rethrow;
    }
  }

  await initApiServices();
}

/// Singleton accessor for NotificationService used across the app
NotificationService get notificationService {
  _ensureNotificationService();
  return _notificationService!;
}

NotificationService? _notificationService;

void _ensureNotificationService() {
  if (_notificationService == null) {
    _notificationService = NotificationService();
  }
}

Future<void> initApiServices() async {
  // Initialize notification service (FCM + local notifications)
  _ensureNotificationService();
  await _notificationService!.initialize();
}
