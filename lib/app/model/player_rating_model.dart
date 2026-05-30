import 'package:cloud_firestore/cloud_firestore.dart';

class RatingTier {
  static const String starter = 'Starter';
  static const String developing = 'Developing';
  static const String competitive = 'Competitive';
  static const String advanced = 'Advanced';
  static const String elite = 'Elite';

  static String fromRating(double rating) {
    if (rating >= 1700) return elite;
    if (rating >= 1500) return advanced;
    if (rating >= 1300) return competitive;
    if (rating >= 1100) return developing;
    return starter;
  }
}

class PlayerRatingModel {
  final String id;
  final String playerId;
  final double rating;
  final double ratingDeviation;
  final double volatility;
  final int matchCount;
  final int winCount;
  final int lossCount;
  final DateTime? lastMatchDate;
  final DateTime updatedAt;

  PlayerRatingModel({
    required this.id,
    required this.playerId,
    this.rating = 1000.0,
    this.ratingDeviation = 350.0,
    this.volatility = 0.06,
    this.matchCount = 0,
    this.winCount = 0,
    this.lossCount = 0,
    this.lastMatchDate,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  String get tier => RatingTier.fromRating(rating);

  int get displayRating => rating.round();

  double get winRate => matchCount == 0 ? 0 : (winCount / matchCount * 100);

  double get matchScore =>
      ((rating - 800) / (1700 - 800) * 100).clamp(0.0, 100.0);

  bool get isUncertain => ratingDeviation > 150;

  factory PlayerRatingModel.initial(String playerId) =>
      PlayerRatingModel(id: '', playerId: playerId);

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'rating': rating,
    'ratingDeviation': ratingDeviation,
    'volatility': volatility,
    'matchCount': matchCount,
    'winCount': winCount,
    'lossCount': lossCount,
    'lastMatchDate': lastMatchDate != null
        ? Timestamp.fromDate(lastMatchDate!)
        : null,
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory PlayerRatingModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    DateTime? parseOptionalDate(dynamic field) {
      if (field is Timestamp) return field.toDate();
      if (field is DateTime) return field;
      return null;
    }

    DateTime parseDate(dynamic field) =>
        parseOptionalDate(field) ?? DateTime.now();

    return PlayerRatingModel(
      id: id,
      playerId: map['playerId'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 1000.0,
      ratingDeviation: (map['ratingDeviation'] as num?)?.toDouble() ?? 350.0,
      volatility: (map['volatility'] as num?)?.toDouble() ?? 0.06,
      matchCount: map['matchCount'] as int? ?? 0,
      winCount: map['winCount'] as int? ?? 0,
      lossCount: map['lossCount'] as int? ?? 0,
      lastMatchDate: parseOptionalDate(map['lastMatchDate']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  PlayerRatingModel copyWith({
    String? id,
    String? playerId,
    double? rating,
    double? ratingDeviation,
    double? volatility,
    int? matchCount,
    int? winCount,
    int? lossCount,
    DateTime? lastMatchDate,
    DateTime? updatedAt,
  }) {
    return PlayerRatingModel(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      rating: rating ?? this.rating,
      ratingDeviation: ratingDeviation ?? this.ratingDeviation,
      volatility: volatility ?? this.volatility,
      matchCount: matchCount ?? this.matchCount,
      winCount: winCount ?? this.winCount,
      lossCount: lossCount ?? this.lossCount,
      lastMatchDate: lastMatchDate ?? this.lastMatchDate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
