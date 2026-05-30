import 'package:cloud_firestore/cloud_firestore.dart';

class MetricCategory {
  static const String physical = 'physical';
  static const String skill = 'skill';
}

class MetricDirection {
  static const String higherIsBetter = 'higher';
  static const String lowerIsBetter = 'lower';
}

class MetricDefinitionModel {
  final String id;
  final String category;
  final String key;
  final String label;
  final String unit;
  final String direction;
  final double worstValue;
  final double bestValue;
  final double weight;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  MetricDefinitionModel({
    required this.id,
    required this.category,
    required this.key,
    required this.label,
    required this.unit,
    required this.direction,
    required this.worstValue,
    required this.bestValue,
    this.weight = 1,
    this.sortOrder = 0,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  double scoreFor(num? rawValue) {
    if (rawValue == null || bestValue == worstValue) return 0;
    final value = rawValue.toDouble();
    final score = direction == MetricDirection.lowerIsBetter
        ? (worstValue - value) / (worstValue - bestValue) * 100
        : (value - worstValue) / (bestValue - worstValue) * 100;
    return score.clamp(0.0, 100.0);
  }

  static double compositeScore(
    Map<String, dynamic> metrics,
    List<MetricDefinitionModel> definitions,
  ) {
    double weightedTotal = 0;
    double totalWeight = 0;
    for (final definition in definitions.where((d) => d.isActive)) {
      final raw = metrics[definition.key];
      final value = raw is num ? raw : num.tryParse(raw?.toString() ?? '');
      if (value == null) continue;
      final weight = definition.weight <= 0 ? 1.0 : definition.weight;
      weightedTotal += definition.scoreFor(value) * weight;
      totalWeight += weight;
    }
    return totalWeight == 0 ? 0 : weightedTotal / totalWeight;
  }

  Map<String, dynamic> toJson() => {
    'category': category,
    'key': key,
    'label': label,
    'unit': unit,
    'direction': direction,
    'worstValue': worstValue,
    'bestValue': bestValue,
    'weight': weight,
    'sortOrder': sortOrder,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory MetricDefinitionModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    DateTime parseDate(dynamic field) {
      if (field is Timestamp) return field.toDate();
      if (field is DateTime) return field;
      return DateTime.now();
    }

    return MetricDefinitionModel(
      id: id,
      category: map['category'] as String? ?? MetricCategory.physical,
      key: map['key'] as String? ?? '',
      label: map['label'] as String? ?? '',
      unit: map['unit'] as String? ?? '',
      direction: map['direction'] as String? ?? MetricDirection.higherIsBetter,
      worstValue: (map['worstValue'] as num?)?.toDouble() ?? 0,
      bestValue: (map['bestValue'] as num?)?.toDouble() ?? 100,
      weight: (map['weight'] as num?)?.toDouble() ?? 1,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  MetricDefinitionModel copyWith({
    String? id,
    String? category,
    String? key,
    String? label,
    String? unit,
    String? direction,
    double? worstValue,
    double? bestValue,
    double? weight,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MetricDefinitionModel(
      id: id ?? this.id,
      category: category ?? this.category,
      key: key ?? this.key,
      label: label ?? this.label,
      unit: unit ?? this.unit,
      direction: direction ?? this.direction,
      worstValue: worstValue ?? this.worstValue,
      bestValue: bestValue ?? this.bestValue,
      weight: weight ?? this.weight,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
