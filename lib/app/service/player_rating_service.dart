import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/model/player_rating_model.dart';

class PlayerRatingService {
  final FirebaseFirestore _db;

  PlayerRatingService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance {
    if (firestore == null) {
      _db.settings = const Settings(persistenceEnabled: false);
    }
  }

  static const String _collection = 'playerRatings';

  Future<List<PlayerRatingModel>> getAll() async {
    final snapshot = await _db
        .collection(_collection)
        .orderBy('rating', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => PlayerRatingModel.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  Future<PlayerRatingModel?> getByPlayer(String playerId) async {
    final snapshot = await _db
        .collection(_collection)
        .where('playerId', isEqualTo: playerId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return PlayerRatingModel.fromMap(
      snapshot.docs.first.data(),
      id: snapshot.docs.first.id,
    );
  }

  Future<void> upsert(PlayerRatingModel rating) async {
    if (rating.id.isNotEmpty) {
      await _db
          .collection(_collection)
          .doc(rating.id)
          .set(rating.toJson(), SetOptions(merge: true));
      return;
    }

    final existing = await getByPlayer(rating.playerId);
    if (existing != null) {
      await _db
          .collection(_collection)
          .doc(existing.id)
          .set(rating.toJson(), SetOptions(merge: true));
    } else {
      await _db.collection(_collection).add(rating.toJson());
    }
  }

  Future<void> delete(String id) async {
    await _db.collection(_collection).doc(id).delete();
  }
}
