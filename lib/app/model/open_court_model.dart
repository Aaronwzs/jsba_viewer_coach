import 'package:cloud_firestore/cloud_firestore.dart';

class OpenCourtModel {
  final String id;
  final String adminId;
  final String venue;
  final DateTime date;
  final String startTime;
  final int durationMinutes;
  final int maxPlayers;
  final String classType;
  final String level;
  final String status;
  final String? bookedByUserId;
  final String? bookedByParentName;
  final String? bookedByPlayerName;
  final String? reservedByUserId;
  final String? reservedByParentName;
  final List<String> playerIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  static const String classTypeGroup = 'group';
  static const String classTypePrivate = 'private';
  static const String classTypeSemiPrivate = 'semi_private';

  static const List<String> allClassTypes = [
    classTypeGroup,
    classTypePrivate,
    classTypeSemiPrivate,
  ];

  static const String levelBeginner = 'beginner';
  static const String levelIntermediate = 'intermediate';
  static const String levelAdvanced = 'advanced';

  static const List<String> allLevels = [
    levelBeginner,
    levelIntermediate,
    levelAdvanced,
  ];

  static const String statusDraft = 'draft';
  static const String statusOpenForBooking = 'open_for_booking';
  static const String statusReservedForBooking = 'reserved_for_booking';
  static const String statusBooked = 'booked';
  static const String statusOpenForRegistration = 'open_for_registration';
  static const String statusClosed = 'closed';

  static const List<String> allStatuses = [
    statusDraft,
    statusOpenForBooking,
    statusReservedForBooking,
    statusBooked,
    statusOpenForRegistration,
    statusClosed,
  ];

  OpenCourtModel({
    required this.id,
    required this.adminId,
    required this.venue,
    required this.date,
    required this.startTime,
    required this.durationMinutes,
    required this.maxPlayers,
    required this.classType,
    required this.level,
    this.status = statusDraft,
    this.bookedByUserId,
    this.bookedByParentName,
    this.bookedByPlayerName,
    this.reservedByUserId,
    this.reservedByParentName,
    List<String>? playerIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : playerIds = playerIds ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  String get computedEndTime {
    final parts = startTime.split(':');
    if (parts.length != 2) return '22:00';

    final hour = int.tryParse(parts[0]) ?? 20;
    final minute = int.tryParse(parts[1]) ?? 0;

    final startDate = DateTime(2000, 1, 1, hour, minute);
    final endDate = startDate.add(Duration(minutes: durationMinutes));

    return '${endDate.hour.toString().padLeft(2, '0')}:${endDate.minute.toString().padLeft(2, '0')}';
  }

  String get classTypeDisplayName {
    switch (classType) {
      case classTypeGroup:
        return 'Group Class';
      case classTypePrivate:
        return 'Private';
      case classTypeSemiPrivate:
        return 'Semi-Private';
      default:
        return classType;
    }
  }

  String get levelDisplayName {
    switch (level) {
      case levelBeginner:
        return 'Beginner';
      case levelIntermediate:
        return 'Intermediate';
      case levelAdvanced:
        return 'Advanced';
      default:
        return level;
    }
  }

  String get statusDisplayName {
    switch (status) {
      case statusDraft:
        return 'Draft';
      case statusOpenForBooking:
        return 'Open for Booking';
      case statusReservedForBooking:
        return 'Reserved for Booking';
      case statusBooked:
        return 'Booked';
      case statusOpenForRegistration:
        return 'Open for Registration';
      case statusClosed:
        return 'Closed';
      default:
        return status;
    }
  }

  int get filledSlots => playerIds.length;

  int get availableSlots => maxPlayers - filledSlots;

  bool get isFull => availableSlots <= 0;

  bool isPlayerRegistered(String playerId) {
    return playerIds.contains(playerId);
  }

  Map<String, dynamic> toJson() => {
    'adminId': adminId,
    'venue': venue,
    'date': Timestamp.fromDate(date),
    'startTime': startTime,
    'durationMinutes': durationMinutes,
    'maxPlayers': maxPlayers,
    'classType': classType,
    'level': level,
    'status': status,
    'bookedByUserId': bookedByUserId,
    'bookedByParentName': bookedByParentName,
    'bookedByPlayerName': bookedByPlayerName,
    'reservedByUserId': reservedByUserId,
    'reservedByParentName': reservedByParentName,
    'playerIds': playerIds,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory OpenCourtModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    DateTime? sessionDate;
    final dateField = map['date'];
    if (dateField is Timestamp) {
      sessionDate = dateField.toDate();
    } else if (dateField is DateTime) {
      sessionDate = dateField;
    }

    DateTime? created;
    final createdField = map['createdAt'];
    if (createdField is Timestamp) {
      created = createdField.toDate();
    } else if (createdField is DateTime) {
      created = createdField;
    }

    DateTime? updated;
    final updatedField = map['updatedAt'];
    if (updatedField is Timestamp) {
      updated = updatedField.toDate();
    } else if (updatedField is DateTime) {
      updated = updatedField;
    }

    final playerIdsList = <String>[];
    final playerIdsField = map['playerIds'];
    if (playerIdsField is List) {
      for (final id in playerIdsField) {
        if (id is String) {
          playerIdsList.add(id);
        }
      }
    } else {
      // Backward compatibility: check for old 'slots' field
      final slotsField = map['slots'];
      if (slotsField is List) {
        for (final slot in slotsField) {
          if (slot is Map<String, dynamic>) {
            final playerId = slot['playerId'] as String?;
            if (playerId != null && playerId.isNotEmpty) {
              playerIdsList.add(playerId);
            }
          }
        }
      }
    }

    return OpenCourtModel(
      id: id,
      adminId: map['adminId'] as String? ?? '',
      venue: map['venue'] as String? ?? '',
      date: sessionDate ?? DateTime.now(),
      startTime: map['startTime'] as String? ?? '20:00',
      durationMinutes: map['durationMinutes'] as int? ?? 120,
      maxPlayers: map['maxPlayers'] as int? ?? 6,
      classType: map['classType'] as String? ?? classTypeGroup,
      level: map['level'] as String? ?? levelBeginner,
      status: map['status'] as String? ?? statusDraft,
      bookedByUserId: map['bookedByUserId'] as String?,
      bookedByParentName: map['bookedByParentName'] as String?,
      bookedByPlayerName: map['bookedByPlayerName'] as String?,
      reservedByUserId: map['reservedByUserId'] as String?,
      reservedByParentName: map['reservedByParentName'] as String?,
      playerIds: playerIdsList,
      createdAt: created,
      updatedAt: updated,
    );
  }

  OpenCourtModel copyWith({
    String? id,
    String? adminId,
    String? venue,
    DateTime? date,
    String? startTime,
    int? durationMinutes,
    int? maxPlayers,
    String? classType,
    String? level,
    String? status,
    String? bookedByUserId,
    String? bookedByParentName,
    String? bookedByPlayerName,
    String? reservedByUserId,
    String? reservedByParentName,
    List<String>? playerIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OpenCourtModel(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      venue: venue ?? this.venue,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      classType: classType ?? this.classType,
      level: level ?? this.level,
      status: status ?? this.status,
      bookedByUserId: bookedByUserId ?? this.bookedByUserId,
      bookedByParentName: bookedByParentName ?? this.bookedByParentName,
      bookedByPlayerName: bookedByPlayerName ?? this.bookedByPlayerName,
      reservedByUserId: reservedByUserId ?? this.reservedByUserId,
      reservedByParentName: reservedByParentName ?? this.reservedByParentName,
      playerIds: playerIds ?? this.playerIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
