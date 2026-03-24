import 'package:cloud_firestore/cloud_firestore.dart';

class TrainingModel {
  final String id;
  final String className;
  final List<String> playerIds;
  final DateTime date;
  final String dayOfWeek;
  final String venue;
  final String startTime;
  final String? endTime;
  String status;
  final String classType;
  final String level;
  final int durationMinutes;
  final double price;
  final int? maxPlayers;
  final String? coachId;

  // Predefined options
  static const List<String> validClassTypes = [
    'group',
    'private',
    'sparring',
    'skill',
    'physical',
  ];

  static const List<String> validVenues = [
    'Desa Petaling',
    'Midfields',
    'Sky Condo',
    'Yoke Nam',
  ];

  // Helper: Get effective max players
  int getEffectiveMaxPlayers() {
    if (maxPlayers != null) return maxPlayers!;
    switch (classType) {
      case 'private':
        return 1;
      case 'sparring':
        return 2;
      case 'skill':
      case 'physical':
        return 4;
      case 'group':
      default:
        return 6;
    }
  }

  // Compute end time if not provided
  String get computedEndTime {
    if (endTime != null && endTime!.isNotEmpty) return endTime!;

    // Parse start time
    final startParts = startTime.split(':');
    if (startParts.length != 2) return '10:00'; // fallback

    final startHour = int.tryParse(startParts[0]) ?? 9;
    final startMinute = int.tryParse(startParts[1]) ?? 0;

    // Create a dummy DateTime on epoch day, add duration, extract time
    final startDate = DateTime(2000, 1, 1, startHour, startMinute);
    final endDate = startDate.add(Duration(minutes: durationMinutes));

    return '${endDate.hour.toString().padLeft(2, '0')}:${endDate.minute.toString().padLeft(2, '0')}';
  }

  // In TrainingModel
  String getEffectiveStatus() {
    // If explicitly cancelled or completed, respect that
    if (status == 'cancelled' || status == 'completed') {
      return status;
    }

    // Only auto-determine status for 'upcoming' trainings
    final today = DateTime.now();
    final trainingDate = DateTime(date.year, date.month, date.day);
    final todayDate = DateTime(today.year, today.month, today.day);

    if (trainingDate.isBefore(todayDate)) {
      return 'completed';
    }
    return 'upcoming';
  }

  DateTime get startDateTime {
    final parts = startTime.split(':');
    if (parts.length != 2) return date;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  DateTime get endDateTime {
    final parts = computedEndTime.split(':');
    if (parts.length != 2) return startDateTime.add(const Duration(hours: 1));
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  TrainingModel({
    required this.id,
    required this.className,
    required this.playerIds,
    required this.date,
    required this.dayOfWeek,
    required this.venue,
    required this.startTime,
    this.endTime,
    this.status = 'upcoming',
    required this.classType,
    required this.level,
    required this.durationMinutes,
    required this.price,
    this.maxPlayers,
    this.coachId,
  });

  Map<String, dynamic> toJson() => {
    'className': className,
    'playerIds': playerIds,
    'date': Timestamp.fromDate(date),
    'dayOfWeek': dayOfWeek,
    'venue': venue,
    'startTime': startTime,
    'endTime': endTime,
    'status': status,
    'classType': classType,
    'level': level,
    'durationMinutes': durationMinutes,
    'price': price,
    'maxPlayers': maxPlayers,
    'coachId': coachId,
  };

  factory TrainingModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    DateTime? date;
    final dateField = map['date'];
    if (dateField is Timestamp) {
      date = dateField.toDate();
    } else if (dateField is DateTime) {
      date = dateField;
    } else {
      date = DateTime.now();
    }

    return TrainingModel(
      id: id,
      className: map['className'] as String? ?? '',
      playerIds: map['playerIds'] == null
          ? []
          : List<String>.from(map['playerIds'] as List),
      date: date,
      dayOfWeek: map['dayOfWeek'] as String? ?? '',
      venue: map['venue'] as String? ?? 'Desa Petaling',
      startTime: map['startTime'] as String? ?? '09:00',
      endTime: map['endTime'] as String?,
      status: map['status'] as String? ?? 'upcoming',
      classType: map['classType'] as String? ?? 'group',
      level: map['level'] as String? ?? 'Beginner',
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 60,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      maxPlayers: map['maxPlayers'] as int?,
      coachId: map['coachId'] as String?,
    );
  }
}
