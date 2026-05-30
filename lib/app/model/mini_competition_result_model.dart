import 'package:cloud_firestore/cloud_firestore.dart';

class MiniCompetitionResult {
  static const String win = 'win';
  static const String loss = 'loss';
}

class MiniCompetitionResultModel {
  final String id;
  final String eventId;
  final String playerId;
  final String playerName;
  final String opponentId;
  final String opponentName;
  final DateTime date;
  final int myPoints;
  final int opponentPoints;
  final double ratingBefore;
  final double ratingAfter;
  final double ratingDeviation;
  final bool isStarPlayer;
  final String? note;
  final String recordedBy;
  final DateTime createdAt;

  MiniCompetitionResultModel({
    required this.id,
    required this.eventId,
    required this.playerId,
    required this.playerName,
    required this.opponentId,
    required this.opponentName,
    required this.date,
    required this.myPoints,
    required this.opponentPoints,
    this.ratingBefore = 1000.0,
    this.ratingAfter = 1000.0,
    this.ratingDeviation = 350.0,
    this.isStarPlayer = false,
    this.note,
    required this.recordedBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get result => myPoints > opponentPoints
      ? MiniCompetitionResult.win
      : MiniCompetitionResult.loss;

  bool get isWin => result == MiniCompetitionResult.win;

  double get ratingChange => ratingAfter - ratingBefore;

  Map<String, dynamic> toJson() => {
    'eventId': eventId,
    'playerId': playerId,
    'playerName': playerName,
    'opponentId': opponentId,
    'opponentName': opponentName,
    'date': Timestamp.fromDate(date),
    'myPoints': myPoints,
    'opponentPoints': opponentPoints,
    'result': result,
    'ratingBefore': ratingBefore,
    'ratingAfter': ratingAfter,
    'ratingDeviation': ratingDeviation,
    'isStarPlayer': isStarPlayer,
    'note': note,
    'recordedBy': recordedBy,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory MiniCompetitionResultModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    DateTime parseDate(dynamic field) {
      if (field is Timestamp) return field.toDate();
      if (field is DateTime) return field;
      return DateTime.now();
    }

    return MiniCompetitionResultModel(
      id: id,
      eventId: map['eventId'] as String? ?? '',
      playerId: map['playerId'] as String? ?? '',
      playerName: map['playerName'] as String? ?? '',
      opponentId: map['opponentId'] as String? ?? '',
      opponentName: map['opponentName'] as String? ?? '',
      date: parseDate(map['date']),
      myPoints: map['myPoints'] as int? ?? 0,
      opponentPoints: map['opponentPoints'] as int? ?? 0,
      ratingBefore: (map['ratingBefore'] as num?)?.toDouble() ?? 1000.0,
      ratingAfter: (map['ratingAfter'] as num?)?.toDouble() ?? 1000.0,
      ratingDeviation: (map['ratingDeviation'] as num?)?.toDouble() ?? 350.0,
      isStarPlayer: map['isStarPlayer'] as bool? ?? false,
      note: map['note'] as String?,
      recordedBy: map['recordedBy'] as String? ?? '',
      createdAt: parseDate(map['createdAt']),
    );
  }

  MiniCompetitionResultModel copyWith({
    String? id,
    String? eventId,
    String? playerId,
    String? playerName,
    String? opponentId,
    String? opponentName,
    DateTime? date,
    int? myPoints,
    int? opponentPoints,
    double? ratingBefore,
    double? ratingAfter,
    double? ratingDeviation,
    bool? isStarPlayer,
    String? note,
    String? recordedBy,
    DateTime? createdAt,
  }) {
    return MiniCompetitionResultModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      opponentId: opponentId ?? this.opponentId,
      opponentName: opponentName ?? this.opponentName,
      date: date ?? this.date,
      myPoints: myPoints ?? this.myPoints,
      opponentPoints: opponentPoints ?? this.opponentPoints,
      ratingBefore: ratingBefore ?? this.ratingBefore,
      ratingAfter: ratingAfter ?? this.ratingAfter,
      ratingDeviation: ratingDeviation ?? this.ratingDeviation,
      isStarPlayer: isStarPlayer ?? this.isStarPlayer,
      note: note ?? this.note,
      recordedBy: recordedBy ?? this.recordedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
