import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:jsba_app/app/assets/constants/environment_config.dart';
import 'package:jsba_app/app/model/attendance_model.dart';
import 'package:jsba_app/app/model/coach_entry_model.dart';
import 'package:jsba_app/app/model/player_model.dart';

class GeminiSummaryService {
  final String _apiKey;

  GeminiSummaryService({String? apiKey})
      : _apiKey = apiKey ?? EnvValues.geminiApiKey;

  static const String _systemPrompt = '''You are a badminton academy coach assistant writing for parents. Your job is to summarize a player's progress based on categorized coach field comments written during training sessions.

RULES:
1. Write in a warm, encouraging, parent-friendly tone. Avoid technical jargon without explanation.
2. Structure your response in exactly three sections with these exact headers:
   ## Strengths
   ## Areas to Improve
   ## Suggestions for Home Practice
3. Be specific — reference the categories coaches commented on (e.g., "In footwork, coaches noted...")
4. If the same area receives both positive and improvement comments, acknowledge both honestly.
5. Adjust language for the player's age and level:
   - Young players (under 12): simpler language, focus on effort and fun
   - Teen players: more specific technique references, competitive framing
   - Beginners: emphasize fundamentals and consistency
   - Advanced players: reference high-level concepts like shot selection, match strategy
6. If there are fewer than 3 total comments across all categories, respond with exactly:
   "Not enough observations yet. Summary will improve as coaches add more comments over upcoming sessions."
7. Keep the total response under 400 words.
8. Do not invent observations that are not in the data.
9. Group related observations within each section by category (footwork, fitness, technique, match play, attitude).''';

  Future<String> generatePlayerSummary({
    required PlayerModel player,
    required List<AttendanceModel> attendances,
  }) async {
    if (_apiKey.isEmpty) {
      return 'AI summary is not configured. Please set the Gemini API key.';
    }

    final entriesByCategory = <String, List<_DatedEntry>>{};

    for (final attendance in attendances) {
      final dateStr = _formatDate(attendance.createdAt);
      for (final entry in attendance.coachEntries) {
        if (entry.comment.trim().isEmpty) continue;
        entriesByCategory.putIfAbsent(entry.category, () => []);
        entriesByCategory[entry.category]!.add(
          _DatedEntry(date: dateStr, comment: entry.comment),
        );
      }
    }

    final allEntries = entriesByCategory.values.expand((e) => e).toList();
    if (allEntries.length < 3) {
      return 'Not enough observations yet. Summary will improve as coaches add more comments over upcoming sessions.';
    }

    final playerContext = _buildPlayerContext(player);
    final groupedComments = _buildGroupedComments(entriesByCategory);
    final userPrompt = '$playerContext\n\n$groupedComments';

    try {
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: _apiKey,
        systemInstruction: Content.system(_systemPrompt),
      );

      final content = [Content.text(userPrompt)];
      final response = await model.generateContent(content);

      return response.text ??
          'Unable to generate summary. Please try again later.';
    } catch (e) {
      if (e.toString().contains('API_KEY')) {
        return 'AI summary is not configured. Please check the API key.';
      }
      return 'Error generating summary. Please try again.';
    }
  }

  String _buildPlayerContext(PlayerModel player) {
    final levelLabel = _levelLabel(player.level);
    return '''## Player Profile
Name: ${player.name}
Age: ${player.computedAge}
Level: $levelLabel''';
  }

  String _buildGroupedComments(
    Map<String, List<_DatedEntry>> entriesByCategory,
  ) {
    final buffer = StringBuffer('## Coach Observations (Last 3 Months)\n\n');

    final orderedCategories = CoachCommentCategory.all
        .where((cat) => entriesByCategory.containsKey(cat))
        .toList();

    for (final category in orderedCategories) {
      final entries = entriesByCategory[category]!;
      final label = CoachCommentCategory.label(category);
      buffer.writeln('### $label (${entries.length} comment${entries.length == 1 ? '' : 's'})');
      for (final entry in entries) {
        buffer.writeln('- [${entry.date}] "${entry.comment}"');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_monthAbbrev(date.month)}';
  }

  String _monthAbbrev(int month) => switch (month) {
        1 => 'Jan',
        2 => 'Feb',
        3 => 'Mar',
        4 => 'Apr',
        5 => 'May',
        6 => 'Jun',
        7 => 'Jul',
        8 => 'Aug',
        9 => 'Sep',
        10 => 'Oct',
        11 => 'Nov',
        12 => 'Dec',
        _ => '',
      };

  String _levelLabel(String level) {
    final map = {
      'B1': 'Beginner 1',
      'B2': 'Beginner 2',
      'B3': 'Beginner 3',
      'I1': 'Intermediate 1',
      'I2': 'Intermediate 2',
      'I3': 'Intermediate 3',
      'A1': 'Advanced 1',
      'A2': 'Advanced 2',
      'A3': 'Advanced 3',
    };
    return map[level] ?? level;
  }
}

class _DatedEntry {
  final String date;
  final String comment;

  const _DatedEntry({required this.date, required this.comment});
}
