import 'package:cloud_firestore/cloud_firestore.dart';

class CssTrend {
  static const String up = 'up';
  static const String flat = 'flat';
  static const String down = 'down';
}

class PlayerCssSnapshotModel {
  final String id;
  final String playerId;
  final String playerName;
  final DateTime snapshotDate;
  final double? physicalScore;
  final DateTime? physicalAssessedAt;
  final double? technicalScore;
  final DateTime? technicalAssessedAt;
  final double? matchScore;
  final DateTime? matchAssessedAt;
  final String trend;
  final DateTime createdAt;

  PlayerCssSnapshotModel({
    required this.id,
    required this.playerId,
    required this.playerName,
    required this.snapshotDate,
    this.physicalScore,
    this.physicalAssessedAt,
    this.technicalScore,
    this.technicalAssessedAt,
    this.matchScore,
    this.matchAssessedAt,
    this.trend = CssTrend.flat,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get cssTotal {
    final entries = <_CssEntry>[];
    if (physicalScore != null) entries.add(_CssEntry(physicalScore!, 0.30));
    if (technicalScore != null) entries.add(_CssEntry(technicalScore!, 0.40));
    if (matchScore != null) entries.add(_CssEntry(matchScore!, 0.30));
    if (entries.isEmpty) return 0;

    final totalWeight = entries.fold<double>(0, (s, e) => s + e.weight);
    final weightedSum = entries.fold<double>(
      0,
      (s, e) => s + e.score * e.weight,
    );
    return (weightedSum / totalWeight).clamp(0.0, 100.0);
  }

  bool get hasStaleComponent {
    final threshold = DateTime.now().subtract(const Duration(days: 60));
    if (physicalScore != null &&
        (physicalAssessedAt == null ||
            physicalAssessedAt!.isBefore(threshold))) {
      return true;
    }
    if (technicalScore != null &&
        (technicalAssessedAt == null ||
            technicalAssessedAt!.isBefore(threshold))) {
      return true;
    }
    if (matchScore != null &&
        (matchAssessedAt == null || matchAssessedAt!.isBefore(threshold))) {
      return true;
    }
    return false;
  }

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'playerName': playerName,
    'snapshotDate': Timestamp.fromDate(snapshotDate),
    'physicalScore': physicalScore,
    'physicalAssessedAt': physicalAssessedAt != null
        ? Timestamp.fromDate(physicalAssessedAt!)
        : null,
    'technicalScore': technicalScore,
    'technicalAssessedAt': technicalAssessedAt != null
        ? Timestamp.fromDate(technicalAssessedAt!)
        : null,
    'matchScore': matchScore,
    'matchAssessedAt': matchAssessedAt != null
        ? Timestamp.fromDate(matchAssessedAt!)
        : null,
    'cssTotal': cssTotal,
    'trend': trend,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory PlayerCssSnapshotModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    DateTime? parseOptional(dynamic field) {
      if (field is Timestamp) return field.toDate();
      if (field is DateTime) return field;
      return null;
    }

    DateTime parseRequired(dynamic field) =>
        parseOptional(field) ?? DateTime.now();

    return PlayerCssSnapshotModel(
      id: id,
      playerId: map['playerId'] as String? ?? '',
      playerName: map['playerName'] as String? ?? '',
      snapshotDate: parseRequired(map['snapshotDate']),
      physicalScore: (map['physicalScore'] as num?)?.toDouble(),
      physicalAssessedAt: parseOptional(map['physicalAssessedAt']),
      technicalScore: (map['technicalScore'] as num?)?.toDouble(),
      technicalAssessedAt: parseOptional(map['technicalAssessedAt']),
      matchScore: (map['matchScore'] as num?)?.toDouble(),
      matchAssessedAt: parseOptional(map['matchAssessedAt']),
      trend: map['trend'] as String? ?? CssTrend.flat,
      createdAt: parseRequired(map['createdAt']),
    );
  }

  PlayerCssSnapshotModel copyWith({
    String? id,
    String? playerId,
    String? playerName,
    DateTime? snapshotDate,
    double? physicalScore,
    DateTime? physicalAssessedAt,
    double? technicalScore,
    DateTime? technicalAssessedAt,
    double? matchScore,
    DateTime? matchAssessedAt,
    String? trend,
    DateTime? createdAt,
  }) {
    return PlayerCssSnapshotModel(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      snapshotDate: snapshotDate ?? this.snapshotDate,
      physicalScore: physicalScore ?? this.physicalScore,
      physicalAssessedAt: physicalAssessedAt ?? this.physicalAssessedAt,
      technicalScore: technicalScore ?? this.technicalScore,
      technicalAssessedAt: technicalAssessedAt ?? this.technicalAssessedAt,
      matchScore: matchScore ?? this.matchScore,
      matchAssessedAt: matchAssessedAt ?? this.matchAssessedAt,
      trend: trend ?? this.trend,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class _CssEntry {
  final double score;
  final double weight;

  const _CssEntry(this.score, this.weight);
}
