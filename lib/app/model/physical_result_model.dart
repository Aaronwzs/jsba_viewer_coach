import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/model/metric_definition_model.dart';

class PhysicalResultModel {
  final String id;
  final String eventId;
  final String playerId;
  final String playerName;
  final DateTime date;
  final Map<String, dynamic> metrics;
  final double physicalScore;
  final String? coachNote;
  final String recordedBy;
  final DateTime createdAt;
  final Map<String, bool> personalBests;

  PhysicalResultModel({
    required this.id,
    required this.eventId,
    required this.playerId,
    required this.playerName,
    required this.date,
    Map<String, dynamic>? metrics,
    this.physicalScore = 0,
    this.coachNote,
    required this.recordedBy,
    DateTime? createdAt,
    Map<String, bool>? personalBests,
  }) : metrics = metrics ?? {},
       createdAt = createdAt ?? DateTime.now(),
       personalBests = personalBests ?? {};

  static double calculateScore(
    Map<String, dynamic> metrics,
    List<MetricDefinitionModel> definitions,
  ) => MetricDefinitionModel.compositeScore(metrics, definitions);

  Map<String, dynamic> toJson() => {
    'eventId': eventId,
    'playerId': playerId,
    'playerName': playerName,
    'date': Timestamp.fromDate(date),
    'metrics': metrics,
    'physicalScore': physicalScore,
    'coachNote': coachNote,
    'recordedBy': recordedBy,
    'createdAt': Timestamp.fromDate(createdAt),
    'personalBests': personalBests,
  };

  factory PhysicalResultModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    DateTime parseDate(dynamic field) {
      if (field is Timestamp) return field.toDate();
      if (field is DateTime) return field;
      return DateTime.now();
    }

    final rawMetrics = map['metrics'];
    final metrics = rawMetrics is Map<String, dynamic>
        ? rawMetrics
        : <String, dynamic>{};
    final rawPb = map['personalBests'];
    final pbs = rawPb is Map<String, dynamic>
        ? rawPb.map((key, value) => MapEntry(key, value as bool? ?? false))
        : <String, bool>{};

    return PhysicalResultModel(
      id: id,
      eventId: map['eventId'] as String? ?? '',
      playerId: map['playerId'] as String? ?? '',
      playerName: map['playerName'] as String? ?? '',
      date: parseDate(map['date']),
      metrics: metrics,
      physicalScore: (map['physicalScore'] as num?)?.toDouble() ?? 0,
      coachNote: map['coachNote'] as String?,
      recordedBy: map['recordedBy'] as String? ?? '',
      createdAt: parseDate(map['createdAt']),
      personalBests: pbs,
    );
  }
}
