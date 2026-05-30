import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/model/skill_result_model.dart';

class SkillResultService {
  final FirebaseFirestore _db;

  SkillResultService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance {
    if (firestore == null) {
      _db.settings = const Settings(persistenceEnabled: false);
    }
  }

  static const String _collection = 'skillResults';

  Future<List<SkillResultModel>> getByPlayer(String playerId) async {
    final snapshot = await _db
        .collection(_collection)
        .where('playerId', isEqualTo: playerId)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => SkillResultModel.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  Future<SkillResultModel?> getLatestByPlayer(String playerId) async {
    final snapshot = await _db
        .collection(_collection)
        .where('playerId', isEqualTo: playerId)
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return SkillResultModel.fromMap(
      snapshot.docs.first.data(),
      id: snapshot.docs.first.id,
    );
  }

  Future<List<SkillResultModel>> getByEvent(String eventId) async {
    final snapshot = await _db
        .collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .get();

    return snapshot.docs
        .map((doc) => SkillResultModel.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  Future<String> create(SkillResultModel result) async {
    final docRef = await _db.collection(_collection).add(result.toJson());
    return docRef.id;
  }

  Future<void> update(String id, SkillResultModel result) async {
    await _db.collection(_collection).doc(id).update(result.toJson());
  }

  Future<void> delete(String id) async {
    await _db.collection(_collection).doc(id).delete();
  }
}
