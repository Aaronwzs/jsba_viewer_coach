import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/model/physical_result_model.dart';

class PhysicalResultService {
  final FirebaseFirestore _db;

  PhysicalResultService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance {
    if (firestore == null) {
      _db.settings = const Settings(persistenceEnabled: false);
    }
  }

  static const String _collection = 'physicalResults';

  Future<List<PhysicalResultModel>> getByPlayer(String playerId) async {
    final snapshot = await _db
        .collection(_collection)
        .where('playerId', isEqualTo: playerId)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => PhysicalResultModel.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  Future<PhysicalResultModel?> getLatestByPlayer(String playerId) async {
    final snapshot = await _db
        .collection(_collection)
        .where('playerId', isEqualTo: playerId)
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return PhysicalResultModel.fromMap(
      snapshot.docs.first.data(),
      id: snapshot.docs.first.id,
    );
  }

  Future<List<PhysicalResultModel>> getByEvent(String eventId) async {
    final snapshot = await _db
        .collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .get();

    return snapshot.docs
        .map((doc) => PhysicalResultModel.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  Future<String> create(PhysicalResultModel result) async {
    final docRef = await _db.collection(_collection).add(result.toJson());
    return docRef.id;
  }

  Future<void> update(String id, PhysicalResultModel result) async {
    await _db.collection(_collection).doc(id).update(result.toJson());
  }

  Future<void> delete(String id) async {
    await _db.collection(_collection).doc(id).delete();
  }
}
