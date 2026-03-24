import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/model/attendance_model.dart';

class AttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createAttendanceBatch(
    String trainingId,
    List<String> playerIds,
    double price,
  ) async {
    final batch = _db.batch();
    final now = DateTime.now();

    for (final playerId in playerIds) {
      final docRef = _db.collection('attendances').doc();

      batch.set(docRef, {
        'trainingId': trainingId,
        'playerId': playerId,
        'attendanceStatus': 'pending',
        'amountCharge': price,
        'reasonCharge': '',
        'coachComments': '',
        'createdAt': now,
      });
    }

    await batch.commit();
  }

  Future<List<AttendanceModel>> getAttendanceForTraining(
    String trainingId,
  ) async {
    final snapshot = await _db
        .collection('attendances')
        .where('trainingId', isEqualTo: trainingId)
        .get();

    return snapshot.docs
        .map((d) => AttendanceModel.fromJson(d.id, d.data()))
        .toList();
  }

  Future<void> batchUpdateAttendance(List<AttendanceModel> list) async {
    final batch = _db.batch();

    for (final a in list) {
      final ref = _db.collection('attendances').doc(a.id);
      batch.update(ref, {
        'attendanceStatus': a.attendanceStatus,
        'amountCharge': a.amountCharge,
        'reasonCharge': a.reasonCharge,
        'coachComments': a.coachComments,
      });
    }

    await batch.commit();
  }

  Future<List<AttendanceModel>> getAttendanceForMonth(
    DateTime start,
    DateTime end,
  ) async {
    final startTs = Timestamp.fromDate(start);
    final endTs = Timestamp.fromDate(end);

    // 🔍 now run filtered query
    final snapshot = await _db
        .collection('attendances')
        .where('createdAt', isGreaterThanOrEqualTo: startTs)
        .where('createdAt', isLessThan: endTs)
        .get();

    return snapshot.docs
        .map((doc) => AttendanceModel.fromJson(doc.id, doc.data()))
        .toList();
  }

  Future<List<AttendanceModel>> getAllAttendance() async {
    final snapshot = await _db.collection('attendances').get();
    return snapshot.docs
        .map((doc) => AttendanceModel.fromJson(doc.id, doc.data()))
        .toList();
  }

  Future<List<AttendanceModel>> getAttendanceForPlayerInMonth(
    String playerId,
    DateTime start,
    DateTime end,
  ) async {
    final startTs = Timestamp.fromDate(start);
    final endTs = Timestamp.fromDate(end);

    final snapshot = await _db
        .collection('attendances')
        .where('playerId', isEqualTo: playerId)
        .where('createdAt', isGreaterThanOrEqualTo: startTs)
        .where('createdAt', isLessThan: endTs)
        .get();

    return snapshot.docs
        .map((doc) => AttendanceModel.fromJson(doc.id, doc.data()))
        .toList();
  }
}
