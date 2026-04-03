import 'package:cloud_firestore/cloud_firestore.dart';

enum FeedbackType { bug, feedback }

enum FeedbackCategory { general, suggestion, complaint, praise }

enum FeedbackStatus { pending, reviewed, resolved }

class FeedbackModel {
  final String? id;
  final FeedbackType type;
  final FeedbackCategory? category;
  final String title;
  final String description;
  final String? stepsToReproduce;
  final String? expectedBehavior;
  final String? actualBehavior;
  final String? screenshotUrl;
  final String userId;
  final DeviceInfoModel deviceInfo;
  final DateTime createdAt;
  final FeedbackStatus status;

  FeedbackModel({
    this.id,
    required this.type,
    this.category,
    required this.title,
    required this.description,
    this.stepsToReproduce,
    this.expectedBehavior,
    this.actualBehavior,
    this.screenshotUrl,
    required this.userId,
    required this.deviceInfo,
    required this.createdAt,
    this.status = FeedbackStatus.pending,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'category': category?.name,
      'title': title,
      'description': description,
      'stepsToReproduce': stepsToReproduce,
      'expectedBehavior': expectedBehavior,
      'actualBehavior': actualBehavior,
      'screenshotUrl': screenshotUrl,
      'userId': userId,
      'deviceInfo': deviceInfo.toJson(),
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.name,
    };
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return FeedbackModel(
      id: id,
      type: FeedbackType.values.firstWhere((e) => e.name == map['type']),
      category: map['category'] != null
          ? FeedbackCategory.values.firstWhere((e) => e.name == map['category'])
          : null,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      stepsToReproduce: map['stepsToReproduce'],
      expectedBehavior: map['expectedBehavior'],
      actualBehavior: map['actualBehavior'],
      screenshotUrl: map['screenshotUrl'],
      userId: map['userId'] ?? '',
      deviceInfo: map['deviceInfo'] != null
          ? DeviceInfoModel.fromJson(
              Map<String, dynamic>.from(map['deviceInfo']),
            )
          : DeviceInfoModel.empty(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: FeedbackStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => FeedbackStatus.pending,
      ),
    );
  }
}

class DeviceInfoModel {
  final String model;
  final String osVersion;
  final String appVersion;

  DeviceInfoModel({
    required this.model,
    required this.osVersion,
    required this.appVersion,
  });

  factory DeviceInfoModel.empty() {
    return DeviceInfoModel(
      model: 'Unknown',
      osVersion: 'Unknown',
      appVersion: 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {'model': model, 'osVersion': osVersion, 'appVersion': appVersion};
  }

  factory DeviceInfoModel.fromJson(Map<String, dynamic> json) {
    return DeviceInfoModel(
      model: json['model'] ?? 'Unknown',
      osVersion: json['osVersion'] ?? 'Unknown',
      appVersion: json['appVersion'] ?? 'Unknown',
    );
  }
}
