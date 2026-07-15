import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/model/attendance_model.dart';

class AttendanceService {
  final FirebaseFirestore _db;

  AttendanceService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  Future<void> createAttendanceBatch(
    String trainingId,
    List<String> playerIds, {
    String? coachId,
  }) async {
    final batch = _db.batch();
    final now = DateTime.now();

    for (final playerId in playerIds) {
      final docRef = _db.collection('attendances').doc();

      batch.set(docRef, {
        'trainingId': trainingId,
        'playerId': playerId,
        'coachId': coachId,
        'attendanceStatus': 'pending',
        'coachComments': '',
        'coachEntries': [],
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

  /// Fetches multiple attendance docs by their IDs (batched in chunks of 30).
  Future<List<AttendanceModel>> getAttendanceByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final results = <AttendanceModel>[];
    for (var i = 0; i < ids.length; i += 30) {
      final batch = ids.sublist(i, (i + 30).clamp(0, ids.length));
      final snapshot = await _db
          .collection('attendances')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      for (final doc in snapshot.docs) {
        results.add(AttendanceModel.fromJson(doc.id, doc.data()));
      }
    }
    return results;
  }

  Future<void> batchUpdateAttendance(List<AttendanceModel> list) async {
    final batch = _db.batch();

    for (final a in list) {
      final ref = _db.collection('attendances').doc(a.id);
      batch.update(ref, {
        'attendanceStatus': a.attendanceStatus,
        'coachComments': a.coachComments,
        'coachEntries': a.coachEntries.map((e) => e.toJson()).toList(),
      });
    }

    await batch.commit();
  }

  Future<void> updateAttendance(AttendanceModel attendance) async {
    await _db
        .collection('attendances')
        .doc(attendance.id)
        .update(attendance.toJson());
  }

  Future<List<AttendanceModel>> getAttendanceForMonth(
    DateTime start,
    DateTime end,
  ) async {
    final startTs = Timestamp.fromDate(start);
    final endTs = Timestamp.fromDate(end);

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
    try {
      // Try the server-side query first (requires a composite index: playerId + createdAt)
      final snapshot = await _db
          .collection('attendances')
          .where('playerId', isEqualTo: playerId)
          .where('createdAt', isGreaterThanOrEqualTo: startTs)
          .where('createdAt', isLessThan: endTs)
          .get();

      return snapshot.docs
          .map((doc) => AttendanceModel.fromJson(doc.id, doc.data()))
          .toList();
    } catch (e) {
      // Firestore will throw when a required composite index is missing. Fall back
      // to a client-side filter to keep the app usable during development.
      final message = e is Exception ? e.toString() : '';
      if (message.contains('requires an index') || message.contains('index')) {
        // Fetch by playerId only and filter by date range client-side.
        final snapshot = await _db
            .collection('attendances')
            .where('playerId', isEqualTo: playerId)
            .orderBy('createdAt', descending: true)
            .get();

        final all = snapshot.docs
            .map((doc) => AttendanceModel.fromJson(doc.id, doc.data()))
            .toList();

        return all
            .where((a) => !a.createdAt.isBefore(start) && a.createdAt.isBefore(end))
            .toList();
      }

      rethrow;
    }
  }

  Future<List<AttendanceModel>> getAttendanceForPlayer(
    String playerId, {
    int limit = 30,
  }) async {
    final snapshot = await _db
        .collection('attendances')
        .where('playerId', isEqualTo: playerId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => AttendanceModel.fromJson(doc.id, doc.data()))
        .toList();
  }
}
