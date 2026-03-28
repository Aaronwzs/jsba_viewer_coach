import 'package:cloud_firestore/cloud_firestore.dart';

class AvailabilityModel {
  final String id;
  final String adminId;
  final String title;
  final String venue;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final Map<String, bool> responses;
  final bool isActive;
  final DateTime createdAt;

  AvailabilityModel({
    required this.id,
    required this.adminId,
    required this.title,
    required this.venue,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.responses,
    required this.isActive,
    required this.createdAt,
  });

  int get availableCount => responses.values.where((v) => v).length;
  int get unavailableCount => responses.values.where((v) => !v).length;
  int get totalResponses => responses.length;

  bool hasUserResponded(String userId) => responses.containsKey(userId);
  bool? getUserResponse(String userId) => responses[userId];

  String get timeDisplay => '$startTime - $endTime';

  Map<String, dynamic> toJson() {
    return {
      'adminId': adminId,
      'title': title,
      'venue': venue,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'responses': responses,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AvailabilityModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return AvailabilityModel(
      id: id,
      adminId: map['adminId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      venue: map['venue'] as String? ?? '',
      dayOfWeek: map['dayOfWeek'] as String? ?? '',
      startTime: map['startTime'] as String? ?? '',
      endTime: map['endTime'] as String? ?? '',
      responses: Map<String, bool>.from(map['responses'] as Map? ?? {}),
      isActive: map['isActive'] as bool? ?? true,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  AvailabilityModel copyWith({
    String? title,
    String? venue,
    String? dayOfWeek,
    String? startTime,
    String? endTime,
    Map<String, bool>? responses,
    bool? isActive,
  }) {
    return AvailabilityModel(
      id: id,
      adminId: adminId,
      title: title ?? this.title,
      venue: venue ?? this.venue,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      responses: responses ?? this.responses,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
