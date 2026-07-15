import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/model/player_category_model.dart';

class PlayerCategoryService {
  final FirebaseFirestore _db;

  PlayerCategoryService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _collection => _db.collection('playerCategories');

  Future<List<PlayerCategoryModel>> getActiveCategories() async {
    final snapshot =
        await _collection.where('isActive', isEqualTo: true).get();
    return snapshot.docs
        .map((doc) => PlayerCategoryModel.fromMap(
              doc.data() as Map<String, dynamic>,
              id: doc.id,
            ))
        .toList();
  }

  Future<PlayerCategoryModel?> getCategoryById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return PlayerCategoryModel.fromMap(
      doc.data() as Map<String, dynamic>,
      id: doc.id,
    );
  }

  Future<String> createCategory(PlayerCategoryModel category) async {
    final docRef = await _collection.add(category.toJson());
    return docRef.id;
  }

  Future<void> updateCategory(
      String id, PlayerCategoryModel category) async {
    await _collection.doc(id).update(category.toJson());
  }

  Future<void> deleteCategory(String id) async {
    await _collection.doc(id).delete();
  }
}
