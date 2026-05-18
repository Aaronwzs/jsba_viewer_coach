import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:jsba_app/app/model/notification_item_model.dart';
import 'package:jsba_app/app/service/notification_service.dart';

/// ViewModel for the in-app notification feed.
/// Reads from `/users/{userId}/notifications` subcollection in real-time.
class NotificationViewModel extends ChangeNotifier {
  final NotificationService _notificationService;
  final FirebaseFirestore _db;

  List<NotificationItemModel> _notifications = [];
  StreamSubscription<QuerySnapshot>? _subscription;
  String? _userId;
  bool _isLoading = false;
  bool _initialized = false;

  NotificationViewModel({
    NotificationService? notificationService,
    FirebaseFirestore? db,
  })  : _notificationService = notificationService ?? NotificationService(),
        _db = db ?? FirebaseFirestore.instance;

  List<NotificationItemModel> get notifications => _notifications;
  bool get isLoading => _isLoading;

  /// Get the 3 most recent notifications for dashboard display
  List<NotificationItemModel> get recentNotifications {
    final unread = _notifications.where((n) => !n.isRead).toList();
    if (unread.length >= 3) return unread.take(3).toList();
    // Pad with recent read ones if not enough unread
    final combined = [...unread];
    for (final n in _notifications) {
      if (!combined.contains(n) && combined.length < 3) {
        combined.add(n);
      }
    }
    return combined;
  }

  /// Count of unread notifications
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Start listening to notifications for a given user.
  /// Call this after login / when user changes.
  void startListening(String userId) {
    if (_userId == userId && _initialized) return;

    // Cancel old subscription if switching users
    _subscription?.cancel();

    _userId = userId;
    _isLoading = true;
    notifyListeners();

    _subscription = _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _notifications = snapshot.docs.map((doc) {
          return NotificationItemModel.fromMap(
            doc.data(),
            id: doc.id,
          );
        }).toList();
        _isLoading = false;
        _initialized = true;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error listening to notifications: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Stop listening to notification updates.
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _userId = null;
    _initialized = false;
    notifyListeners();
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    if (_userId == null) return;

    try {
      await _db
          .collection('users')
          .doc(_userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      // Optimistic local update
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] =
            _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (_userId == null) return;

    try {
      final batch = _db.batch();
      final unreadDocs = await _db
          .collection('users')
          .doc(_userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in unreadDocs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      // Optimistic local update
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Get the icon for a notification type
  static String getNotificationIcon(String type) {
    switch (type) {
      case 'announcement':
        return '📢';
      case 'invoice':
        return '🧾';
      case 'receipt':
        return '✅';
      case 'availability':
        return '📅';
      case 'session':
        return '🏸';
      case 'training':
        return '📆';
      case 'attendance':
        return '📋';
      case 'feedback':
        return '💬';
      case 'payment_due':
        return '⏰';
      default:
        return '🔔';
    }
  }

  /// Get a human-readable title for a notification type
  static String getNotificationTypeLabel(String type) {
    switch (type) {
      case 'announcement':
        return 'Announcement';
      case 'invoice':
        return 'Invoice';
      case 'receipt':
        return 'Receipt';
      case 'availability':
        return 'Availability';
      case 'session':
        return 'Session';
      case 'training':
        return 'Training';
      case 'attendance':
        return 'Attendance';
      case 'feedback':
        return 'Feedback';
      case 'payment_due':
        return 'Payment Due';
      default:
        return 'Notification';
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}