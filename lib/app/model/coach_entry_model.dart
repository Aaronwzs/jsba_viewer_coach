class CoachCommentCategory {
  static const String footwork = 'footwork';
  static const String fitness = 'fitness';
  static const String technique = 'technique';
  static const String matchPlay = 'match_play';
  static const String attitude = 'attitude';
  static const String general = 'general';

  static const List<String> all = [
    footwork,
    fitness,
    technique,
    matchPlay,
    attitude,
    general,
  ];

  static String label(String key) => switch (key) {
        footwork => 'Footwork',
        fitness => 'Fitness',
        technique => 'Technique',
        matchPlay => 'Match Play',
        attitude => 'Attitude',
        general => 'General',
        _ => key,
      };

  static String icon(String key) => switch (key) {
        footwork => 'directions_run',
        fitness => 'fitness_center',
        technique => 'sports_tennis',
        matchPlay => 'emoji_events',
        attitude => 'psychology',
        general => 'notes',
        _ => 'notes',
      };
}

class CoachEntry {
  final String category;
  final String comment;

  const CoachEntry({
    required this.category,
    required this.comment,
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'comment': comment,
      };

  factory CoachEntry.fromMap(Map<String, dynamic> map) {
    return CoachEntry(
      category: map['category'] as String? ?? CoachCommentCategory.general,
      comment: map['comment'] as String? ?? '',
    );
  }
}
