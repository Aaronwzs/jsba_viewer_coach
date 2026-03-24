import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/model/open_court_model.dart';

class OpenCourtService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _collection = 'openCourts';

  Future<List<OpenCourtModel>> getAllSessions() async {
    final snapshot = await _db
        .collection(_collection)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => OpenCourtModel.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  Future<List<OpenCourtModel>> getUpcomingSessions() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final snapshot = await _db
        .collection(_collection)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .orderBy('date', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => OpenCourtModel.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  Future<List<OpenCourtModel>> getSessionsByStatus(String status) async {
    final snapshot = await _db
        .collection(_collection)
        .where('status', isEqualTo: status)
        .orderBy('date', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => OpenCourtModel.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  Future<OpenCourtModel?> getSession(String id) async {
    final doc = await _db.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return OpenCourtModel.fromMap(doc.data()!, id: doc.id);
  }

  Future<String> createSession(OpenCourtModel session) async {
    final docRef = await _db.collection(_collection).add(session.toJson());
    return docRef.id;
  }

  Future<void> updateSession(String id, OpenCourtModel session) async {
    await _db.collection(_collection).doc(id).update(session.toJson());
  }

  Future<void> deleteSession(String id) async {
    await _db.collection(_collection).doc(id).delete();
  }

  Future<void> updateStatus(String id, String status) async {
    await _db.collection(_collection).doc(id).update({
      'status': status,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> bookCourt({
    required String sessionId,
    required String parentName,
    required String userId,
  }) async {
    await _db.collection(_collection).doc(sessionId).update({
      'status': OpenCourtModel.statusBooked,
      'bookedByUserId': userId,
      'bookedByParentName': parentName,
      'reservedByUserId': null,
      'reservedByParentName': null,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> reserveCourt({
    required String sessionId,
    required String parentName,
    required String userId,
  }) async {
    await _db.collection(_collection).doc(sessionId).update({
      'status': OpenCourtModel.statusReservedForBooking,
      'reservedByUserId': userId,
      'reservedByParentName': parentName,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> cancelReservation(String sessionId) async {
    await _db.collection(_collection).doc(sessionId).update({
      'status': OpenCourtModel.statusOpenForBooking,
      'reservedByUserId': null,
      'reservedByParentName': null,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> undoBooking(String sessionId) async {
    await _db.collection(_collection).doc(sessionId).update({
      'status': OpenCourtModel.statusOpenForBooking,
      'bookedByUserId': null,
      'bookedByParentName': null,
      'bookedByPlayerName': null,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> confirmBooking({
    required String sessionId,
    required String parentName,
    required String userId,
  }) async {
    await _db.collection(_collection).doc(sessionId).update({
      'status': OpenCourtModel.statusBooked,
      'bookedByUserId': userId,
      'bookedByParentName': parentName,
      'reservedByUserId': null,
      'reservedByParentName': null,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> registerPlayer({
    required String sessionId,
    required String playerId,
  }) async {
    final doc = await _db.collection(_collection).doc(sessionId).get();
    if (!doc.exists) throw Exception('Session not found');

    final data = doc.data()!;
    final rawPlayerIds = data['playerIds'];
    final playerIdsList = rawPlayerIds == null
        ? <String>[]
        : List<String>.from(rawPlayerIds as List);

    if (playerIdsList.contains(playerId)) {
      throw Exception('Player already registered for this session');
    }

    playerIdsList.add(playerId);

    await _db.collection(_collection).doc(sessionId).update({
      'playerIds': playerIdsList,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    final updated = await getSession(sessionId);
    if (updated != null && updated.isFull) {
      await _db.collection(_collection).doc(sessionId).update({
        'status': OpenCourtModel.statusClosed,
      });
    }
  }

  Future<void> removePlayer(String sessionId, String playerId) async {
    final doc = await _db.collection(_collection).doc(sessionId).get();
    if (!doc.exists) throw Exception('Session not found');

    final data = doc.data()!;
    final rawPlayerIds = data['playerIds'];
    final playerIdsList = rawPlayerIds == null
        ? <String>[]
        : List<String>.from(rawPlayerIds as List);

    playerIdsList.remove(playerId);

    await _db.collection(_collection).doc(sessionId).update({
      'playerIds': playerIdsList,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
