import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/model/player_model.dart';

class PlayerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  PlayerService() {
    _db.settings = const Settings(persistenceEnabled: false);
  }

  Future<List<PlayerModel>> getPlayers() async {
    final snapshot = await _db
        .collection('players')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => PlayerModel.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  Future<List<PlayerModel>> getPlayersByParentId(String parentId) async {
    final snapshot = await _db
        .collection('players')
        .where('parentId', isEqualTo: parentId)
        .get();

    final players = snapshot.docs
        .map((doc) => PlayerModel.fromMap(doc.data(), id: doc.id))
        .toList();

    players.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return players;
  }

  Future<List<PlayerModel>> getApprovedPlayersByParentId(
    String parentId,
  ) async {
    final snapshot = await _db
        .collection('players')
        .where('parentId', isEqualTo: parentId)
        .where('status', isEqualTo: PlayerStatus.approved)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => PlayerModel.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  Future<PlayerModel?> getSelfPlayer(String parentId) async {
    final snapshot = await _db
        .collection('players')
        .where('parentId', isEqualTo: parentId)
        .where('isSelf', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return PlayerModel.fromMap(
      snapshot.docs.first.data(),
      id: snapshot.docs.first.id,
    );
  }

  // Add new player
  Future<void> addPlayer(PlayerModel player) async {
    await _db.collection('players').add(player.toJson());
  }

  Future<String> createPlayer(PlayerModel player) async {
    final docRef = _db.collection('players').doc();
    await docRef.set(player.toJson());
    return docRef.id;
  }

  // Update player
  Future<void> updatePlayer(String id, PlayerModel player) async {
    await _db.collection('players').doc(id).update(player.toJson());
  }

  //
  Future<void> archivePlayer(String id) async {
    await _db.collection('players').doc(id).update({'isActive': false});
  }

  // Reactivate player (set active = true)
  Future<void> reactivatePlayer(String id) async {
    await _db.collection('players').doc(id).update({'isActive': true});
  }

  //Permanent delete
  Future<void> removePlayer(String id) async {
    await _db.collection('players').doc(id).delete();
  }

  Future<Map<String, String>> getPlayerNames(List<String> playerIds) async {
    if (playerIds.isEmpty) return {};

    final Map<String, String> playerNames = {};
    final snapshot = await _db
        .collection('players')
        .where(FieldPath.documentId, whereIn: playerIds)
        .get();

    for (final doc in snapshot.docs) {
      playerNames[doc.id] = doc.data()['name'] as String? ?? 'Unknown';
    }

    return playerNames;
  }
}
