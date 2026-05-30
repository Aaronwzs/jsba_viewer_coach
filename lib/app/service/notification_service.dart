import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:jsba_app/app/model/notification_item_model.dart';

class NotificationService {
  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Callback for handling notification taps (set by UI layer for navigation)
  void Function(NotificationItemModel notification)? onNotificationTap;

  // Whether the service has been initialized
  bool _initialized = false;

  /// Returns true if at least one Firebase app has been initialized.
  /// Used to guard against calls when Firebase is not available (tests, web).
  bool get _firebaseAvailable => Firebase.apps.isNotEmpty;

  /// Initialize notification channels and listeners.
  /// Call once at app startup.
  Future<void> initialize() async {
    if (_initialized) return;

    // Android notification channel configuration
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      // On iOS, when a notification is tapped while app is closed
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    );
    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request notification permissions
    await requestPermissions();

    // Listen for foreground messages from FCM
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Listen for when user taps a notification to open the app
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpenedApp);

    // Handle notification that launched the app (cold start)
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationOpenedApp(initialMessage);
    }

    _initialized = true;
    debugPrint('NotificationService initialized');
  }

  /// Request notification permissions (iOS shows dialog, Android 13+ shows runtime prompt)
  Future<NotificationSettings> requestPermissions() async {
    return _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: true,
    );
  }

  /// Get the FCM device token
  Future<String?> getDeviceToken() async {
    if (!_firebaseAvailable) {
      debugPrint('NotificationService: getDeviceToken skipped — Firebase not initialized');
      return null;
    }
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Listen for token refresh and call the callback when a new token is issued
  void onTokenRefresh(void Function(String newToken) callback) {
    if (!_firebaseAvailable) {
      debugPrint('NotificationService: onTokenRefresh skipped — Firebase not initialized');
      return;
    }
    _fcm.onTokenRefresh.listen(callback);
  }

  /// Save the device token to the user's document in Firestore.
  /// Call this on login.
  Future<void> saveDeviceToken(String userId) async {
    if (!_firebaseAvailable) {
      debugPrint('NotificationService: saveDeviceToken skipped — Firebase not initialized');
      return;
    }
    try {
      final token = await getDeviceToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update(
          {
            'deviceTokens': FieldValue.arrayUnion([token]),
          },
        );
        debugPrint('Device token saved for user: $userId');
      }
    } catch (e) {
      debugPrint('Error saving device token: $e');
    }
  }

  /// Remove the device token from the user's document.
  /// Call this on logout.
  Future<void> removeDeviceToken(String userId) async {
    if (!_firebaseAvailable) {
      debugPrint('NotificationService: removeDeviceToken skipped — Firebase not initialized');
      return;
    }
    try {
      final token = await getDeviceToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update(
          {
            'deviceTokens': FieldValue.arrayRemove([token]),
          },
        );
        debugPrint('Device token removed for user: $userId');
      }
    } catch (e) {
      debugPrint('Error removing device token: $e');
    }
  }

  /// Write a notification document to a list of user's Firestore subcollections
  /// at /users/{userId}/notifications/{notificationId}.
  /// This is the in-app feed — the NotificationViewModel picks it up in real-time.
  Future<void> sendNotificationToUserIds({
    required List<String> userIds,
    required String type,
    required String title,
    required String body,
    String? referenceId,
    String? referenceCollection,
  }) async {
    if (userIds.isEmpty) return;
    if (!_firebaseAvailable) {
      debugPrint('NotificationService: sendNotificationToUserIds skipped — Firebase not initialized');
      return;
    }

    try {
      final batch = FirebaseFirestore.instance.batch();

      for (final userId in userIds) {
        final notifRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc();

        batch.set(notifRef, {
          'type': type,
          'title': title,
          'body': body,
          'referenceId': referenceId,
          'referenceCollection': referenceCollection,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint('Notification written for ${userIds.length} user(s)');
    } catch (e) {
      debugPrint('Error writing notification: $e');
    }
  }

  /// Look up parent user IDs from a list of player IDs
  /// by querying the `players` collection where the doc ID is in the list.
  static Future<List<String>> getParentIdsForPlayers(
    List<String> playerIds,
  ) async {
    if (playerIds.isEmpty) return [];
    if (Firebase.apps.isEmpty) {
      debugPrint('NotificationService: getParentIdsForPlayers skipped — Firebase not initialized');
      return [];
    }

    final players = await FirebaseFirestore.instance
        .collection('players')
        .where(FieldPath.documentId, whereIn: playerIds.take(30).toList())
        .get();

    final parentIds = <String>{};
    for (final doc in players.docs) {
      final parentId = doc.data()['parentId'] as String?;
      if (parentId != null) parentIds.add(parentId);
    }

    return parentIds.toList();
  }

  /// Handle a foreground FCM message — show local notification
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      _showLocalNotification(
        id: message.hashCode,
        title: notification.title ?? '',
        body: notification.body ?? '',
        payload: message.data,
      );
    } else if (message.data.isNotEmpty) {
      // Data-only message
      _showLocalNotification(
        id: message.hashCode,
        title: message.data['title'] ?? 'Notification',
        body: message.data['body'] ?? '',
        payload: message.data,
      );
    }
  }

  /// Show a local notification (used when app is in foreground)
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      details,
      payload: payload != null ? jsonEncode(payload) : null,
    );
  }

  /// Handle a local notification tap (when app was in foreground and user taps a local notification)
  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        _navigateToNotification(data);
      } catch (_) {
        // Payload was a simple string, ignore
      }
    }
  }

  /// Handle when user opens app from a notification (background/terminated)
  void _handleNotificationOpenedApp(RemoteMessage message) {
    _navigateToNotification(message.data);
  }

  /// iOS specific handler for local notifications received in foreground
  void _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    // iOS handles this via the main delegate
  }

  /// Navigate based on notification data
  void _navigateToNotification(Map<String, dynamic> data) {
    if (onNotificationTap == null) return;

    final notification = NotificationItemModel(
      id: data['referenceId'] ?? '',
      type: data['type'] as String? ?? 'general',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      referenceId: data['referenceId'] as String?,
      referenceCollection: data['referenceCollection'] as String?,
      createdAt: DateTime.now(),
      data: data,
    );

    onNotificationTap!(notification);
  }
}
