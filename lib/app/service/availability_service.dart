import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/model/availability_model.dart';

class AvailabilityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'kidAvailability';

  Future<List<AvailabilityModel>> getActiveSlots() async {
    final snapshot = await _db
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => AvailabilityModel.fromMap(doc.data(), id: doc.id))
        .where((session) => session.isActive)
        .toList();
  }

  Future<void> respond(String slotId, String playerId, bool canJoin) async {
    await _db.collection(_collection).doc(slotId).update({
      'responses.$playerId': canJoin,
    });
  }

  Future<void> removeResponse(String slotId, String playerId) async {
    await _db.collection(_collection).doc(slotId).update({
      'responses.$playerId': FieldValue.delete(),
    });
  }

  Future<void> toggleSlotActive(String slotId, bool active) async {
    await _db.collection(_collection).doc(slotId).update({'isActive': active});
  }
}
