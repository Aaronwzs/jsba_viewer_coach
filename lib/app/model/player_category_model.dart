import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerCategoryModel {
  final String id;
  final String name;
  final String? description;
  final double groupPrice;
  final double privatePrice;
  final bool isActive;
  final DateTime createdAt;

  PlayerCategoryModel({
    required this.id,
    required this.name,
    this.description,
    required this.groupPrice,
    required this.privatePrice,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'groupPrice': groupPrice,
        'privatePrice': privatePrice,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory PlayerCategoryModel.fromMap(
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

    return PlayerCategoryModel(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      groupPrice: (map['groupPrice'] as num?)?.toDouble() ?? 0.0,
      privatePrice: (map['privatePrice'] as num?)?.toDouble() ?? 0.0,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: createdAt,
    );
  }

  factory PlayerCategoryModel.empty() => PlayerCategoryModel(
        id: '',
        name: 'Unknown',
        groupPrice: 0,
        privatePrice: 0,
        isActive: false,
        createdAt: DateTime.now(),
      );
}
