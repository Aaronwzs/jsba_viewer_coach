import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/model/mini_competition_result_model.dart';

class MiniCompetitionResultService {
  final FirebaseFirestore _db;

  MiniCompetitionResultService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance {
    if (firestore == null) {
      _db.settings = const Settings(persistenceEnabled: false);
    }
  }

  static const String _collection = 'miniCompetitionResults';

  Future<List<MiniCompetitionResultModel>> getByPlayer(String playerId) async {
    final snapshot = await _db
        .collection(_collection)
        .where('playerId', isEqualTo: playerId)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map(
          (doc) => MiniCompetitionResultModel.fromMap(doc.data(), id: doc.id),
        )
        .toList();
  }

  Future<List<MiniCompetitionResultModel>> getByEvent(String eventId) async {
    final snapshot = await _db
        .collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .get();

    return snapshot.docs
        .map(
          (doc) => MiniCompetitionResultModel.fromMap(doc.data(), id: doc.id),
        )
        .toList();
  }

  Future<List<MiniCompetitionResultModel>> getOpponentHistory(
    String playerId,
    String opponentId,
  ) async {
    final snapshot = await _db
        .collection(_collection)
        .where('playerId', isEqualTo: playerId)
        .where('opponentId', isEqualTo: opponentId)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map(
          (doc) => MiniCompetitionResultModel.fromMap(doc.data(), id: doc.id),
        )
        .toList();
  }

  Future<String> create(MiniCompetitionResultModel result) async {
    final docRef = await _db.collection(_collection).add(result.toJson());
    return docRef.id;
  }

  Future<void> update(String id, MiniCompetitionResultModel result) async {
    await _db.collection(_collection).doc(id).update(result.toJson());
  }

  Future<void> delete(String id) async {
    await _db.collection(_collection).doc(id).delete();
  }
}
