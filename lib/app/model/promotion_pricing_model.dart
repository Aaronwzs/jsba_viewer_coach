import 'package:cloud_firestore/cloud_firestore.dart';

class PromotionPricingModel {
  final String id;
  final String name;
  final String? description;
  final int sessionsCount;
  final int freeSessions;
  final String discountType; // 'percentage' | 'fixed' | 'bundle'
  final double discountValue;
  final List<String> applicableClassTypes;
  final List<String> applicableCategoryIds;
  final DateTime? validFrom;
  final DateTime? validTo;
  final bool isActive;
  final DateTime createdAt;

  PromotionPricingModel({
    required this.id,
    required this.name,
    this.description,
    required this.sessionsCount,
    this.freeSessions = 0,
    required this.discountType,
    required this.discountValue,
    this.applicableClassTypes = const [],
    this.applicableCategoryIds = const [],
    this.validFrom,
    this.validTo,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'sessionsCount': sessionsCount,
        'freeSessions': freeSessions,
        'discountType': discountType,
        'discountValue': discountValue,
        'applicableClassTypes': applicableClassTypes,
        'applicableCategoryIds': applicableCategoryIds,
        'validFrom':
            validFrom != null ? Timestamp.fromDate(validFrom!) : null,
        'validTo': validTo != null ? Timestamp.fromDate(validTo!) : null,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory PromotionPricingModel.fromMap(
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

    DateTime? validFrom;
    final validFromField = map['validFrom'];
    if (validFromField is Timestamp) {
      validFrom = validFromField.toDate();
    } else if (validFromField is DateTime) {
      validFrom = validFromField;
    }

    DateTime? validTo;
    final validToField = map['validTo'];
    if (validToField is Timestamp) {
      validTo = validToField.toDate();
    } else if (validToField is DateTime) {
      validTo = validToField;
    }

    return PromotionPricingModel(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      sessionsCount: (map['sessionsCount'] as num?)?.toInt() ?? 0,
      freeSessions: (map['freeSessions'] as num?)?.toInt() ?? 0,
      discountType: map['discountType'] as String? ?? 'percentage',
      discountValue: (map['discountValue'] as num?)?.toDouble() ?? 0.0,
      applicableClassTypes:
          List<String>.from(map['applicableClassTypes'] ?? []),
      applicableCategoryIds:
          List<String>.from(map['applicableCategoryIds'] ?? []),
      validFrom: validFrom,
      validTo: validTo,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: createdAt,
    );
  }

  bool get isCurrentlyValid {
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validTo != null && now.isAfter(validTo!)) return false;
    return isActive;
  }
}
