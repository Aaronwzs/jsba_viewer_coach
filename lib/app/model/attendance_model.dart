import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/model/coach_entry_model.dart';

class AttendanceModel {
  String id;
  String trainingId;
  String playerId;
  String? coachId;
  String attendanceStatus;
  double amountCharge;
  String reasonCharge;
  List<CoachEntry> coachEntries;
  DateTime createdAt;

  AttendanceModel({
    required this.id,
    required this.trainingId,
    required this.playerId,
    this.coachId,
    required this.attendanceStatus,
    required this.amountCharge,
    required this.reasonCharge,
    List<CoachEntry>? coachEntries,
    required this.createdAt,
  }) : coachEntries = coachEntries ?? [];

  String get coachComments =>
      coachEntries.map((e) => e.comment).where((c) => c.isNotEmpty).join('\n');

  Map<String, dynamic> toJson() => {
        'trainingId': trainingId,
        'playerId': playerId,
        'coachId': coachId,
        'attendanceStatus': attendanceStatus,
        'amountCharge': amountCharge,
        'reasonCharge': reasonCharge,
        'coachComments': coachComments,
        'coachEntries': coachEntries.map((e) => e.toJson()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory AttendanceModel.fromJson(String id, Map<String, dynamic> json) {
    final legacyComments = json['coachComments'] as String? ?? '';

    List<CoachEntry> entries;
    final rawEntries = json['coachEntries'];
    if (rawEntries is List && rawEntries.isNotEmpty) {
      entries = rawEntries
          .whereType<Map<String, dynamic>>()
          .map((e) => CoachEntry.fromMap(e))
          .toList();
    } else if (legacyComments.isNotEmpty) {
      entries = [
        CoachEntry(
          category: CoachCommentCategory.general,
          comment: legacyComments,
        ),
      ];
    } else {
      entries = [];
    }

    return AttendanceModel(
      id: id,
      trainingId: json['trainingId'] as String? ?? '',
      playerId: json['playerId'] as String? ?? '',
      coachId: json['coachId'] as String?,
      attendanceStatus: json['attendanceStatus'] as String? ?? 'pending',
      amountCharge: ((json['amountCharge'] as num?) ?? 0).toDouble(),
      reasonCharge: json['reasonCharge'] as String? ?? '',
      coachEntries: entries,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
