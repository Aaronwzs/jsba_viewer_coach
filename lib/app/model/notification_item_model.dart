import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for in-app notification feed items stored at
/// `/users/{userId}/notifications/{notificationId}`
class NotificationItemModel {
  final String id;
  final String type; // 'announcement', 'invoice', 'receipt', 'availability', 'session', 'training', 'attendance', 'feedback', 'payment_due'
  final String title;
  final String body;
  final String? referenceId; // ID of the related document
  final String? referenceCollection; // Collection name of the related document
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data; // extra payload

  NotificationItemModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.referenceId,
    this.referenceCollection,
    this.isRead = false,
    required this.createdAt,
    this.data,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'title': title,
    'body': body,
    'referenceId': referenceId,
    'referenceCollection': referenceCollection,
    'isRead': isRead,
    'createdAt': Timestamp.fromDate(createdAt),
    'data': data,
  };

  factory NotificationItemModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    DateTime createdAt;
    final createdAtField = map['createdAt'];
    if (createdAtField is Timestamp) {
      createdAt = createdAtField.toDate();
    } else if (createdAtField is DateTime) {
      createdAt = createdAtField;
    } else {
      createdAt = DateTime.now();
    }

    return NotificationItemModel(
      id: id,
      type: map['type'] as String? ?? 'general',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      referenceId: map['referenceId'] as String?,
      referenceCollection: map['referenceCollection'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: createdAt,
      data: map['data'] as Map<String, dynamic>?,
    );
  }

  NotificationItemModel copyWith({
    String? id,
    String? type,
    String? title,
    String? body,
    String? referenceId,
    String? referenceCollection,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return NotificationItemModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      referenceId: referenceId ?? this.referenceId,
      referenceCollection: referenceCollection ?? this.referenceCollection,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }

  /// Returns an appropriate icon name for the notification type
  String get iconName {
    switch (type) {
      case 'announcement':
        return 'announcement';
      case 'invoice':
        return 'receipt';
      case 'receipt':
        return 'paid';
      case 'availability':
        return 'availability';
      case 'session':
        return 'sports_tennis';
      case 'training':
        return 'schedule';
      case 'attendance':
        return 'fact_check';
      case 'feedback':
        return 'feedback';
      case 'payment_due':
        return 'warning';
      default:
        return 'notifications';
    }
  }
}