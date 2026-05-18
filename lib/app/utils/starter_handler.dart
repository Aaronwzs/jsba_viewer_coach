import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:jsba_app/app/assets/constants/environment_config.dart';
import 'package:jsba_app/app/assets/firebase_options/staging_firebase_options.dart';
import 'package:jsba_app/app/assets/firebase_options/production_firebase_options.dart';
import 'package:jsba_app/app/service/notification_service.dart';

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
