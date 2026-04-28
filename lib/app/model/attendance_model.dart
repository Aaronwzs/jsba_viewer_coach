import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  String id;
  String trainingId;
  String playerId;
  String? coachId;
  String attendanceStatus;
  double amountCharge;
  String reasonCharge;
  String coachComments;
  DateTime createdAt;

  AttendanceModel({
    required this.id,
    required this.trainingId,
    required this.playerId,
    this.coachId,
    required this.attendanceStatus,
    required this.amountCharge,
    required this.reasonCharge,
    this.coachComments = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'trainingId': trainingId,
        'playerId': playerId,
        'coachId': coachId,
        'attendanceStatus': attendanceStatus,
        'amountCharge': amountCharge,
        'reasonCharge': reasonCharge,
        'coachComments': coachComments,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory AttendanceModel.fromJson(String id, Map<String, dynamic> json) {
    return AttendanceModel(
      id: id,
      trainingId: json['trainingId'] as String? ?? '',
      playerId: json['playerId'] as String? ?? '',
      coachId: json['coachId'] as String?,
      attendanceStatus: json['attendanceStatus'] as String? ?? 'pending',
      amountCharge: ((json['amountCharge'] as num?) ?? 0).toDouble(),
      reasonCharge: json['reasonCharge'] as String? ?? '',
      coachComments: json['coachComments'] as String? ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}