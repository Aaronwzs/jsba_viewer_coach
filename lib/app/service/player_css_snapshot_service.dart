import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/model/player_css_snapshot_model.dart';

class PlayerCssSnapshotService {
  final FirebaseFirestore _db;

  PlayerCssSnapshotService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance {
    if (firestore == null) {
      _db.settings = const Settings(persistenceEnabled: false);
    }
  }

  static const String _collection = 'playerCssSnapshots';

  Future<PlayerCssSnapshotModel?> getLatestByPlayer(String playerId) async {
    final snapshot = await _db
        .collection(_collection)
        .where('playerId', isEqualTo: playerId)
        .orderBy('snapshotDate', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return PlayerCssSnapshotModel.fromMap(
      snapshot.docs.first.data(),
      id: snapshot.docs.first.id,
    );
  }

  Future<List<PlayerCssSnapshotModel>> getHistoryByPlayer(
    String playerId, {
    int limit = 6,
  }) async {
    final snapshot = await _db
        .collection(_collection)
        .where('playerId', isEqualTo: playerId)
        .orderBy('snapshotDate', descending: true)
        .limit(limit)
        .get();

    final results = snapshot.docs
        .map((doc) => PlayerCssSnapshotModel.fromMap(doc.data(), id: doc.id))
        .toList();

    return results.reversed.toList();
  }

  Future<String> create(PlayerCssSnapshotModel snapshot) async {
    final docRef = await _db.collection(_collection).add(snapshot.toJson());
    return docRef.id;
  }

  Future<void> update(String id, PlayerCssSnapshotModel snapshot) async {
    await _db.collection(_collection).doc(id).update(snapshot.toJson());
  }

  Future<void> delete(String id) async {
    await _db.collection(_collection).doc(id).delete();
  }
}
