import 'package:cloud_firestore/cloud_firestore.dart';

class CoachPayoutModel {
  final String id;
  final String coachId;
  final String coachRatesId;
  final DateTime? createdAt;
  final DateTime? generatedAt;
  final String periodKey;
  final List<String> trainingIds;
  final String? uploadProof;

  CoachPayoutModel({
    required this.id,
    required this.coachId,
    required this.coachRatesId,
    this.createdAt,
    this.generatedAt,
    required this.periodKey,
    this.trainingIds = const [],
    this.uploadProof,
  });

  factory CoachPayoutModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    DateTime? created;
    DateTime? generated;

    final createdField = map['createdAt'];
    if (createdField is Timestamp) {
      created = createdField.toDate();
    } else if (createdField is DateTime){
      created = createdField;
    }

    final genField = map['generatedAt'];
    if (genField is Timestamp) {
      generated = genField.toDate();
    } else if (genField is DateTime){
      generated = genField;
    }


    final trainingIdsList = (map['trainingIds'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList();

    return CoachPayoutModel(
      id: id,
      coachId: map['coachId'] as String? ?? '',
      coachRatesId: map['coachRatesId'] as String? ?? '',
      createdAt: created,
      generatedAt: generated,
      periodKey: map['periodKey'] as String? ?? '',
      trainingIds: trainingIdsList,
      uploadProof: map['uploadProof'] as String?,
    );
  }
}
