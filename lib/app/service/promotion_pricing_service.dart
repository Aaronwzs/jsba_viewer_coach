import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/model/promotion_pricing_model.dart';

class PromotionPricingService {
  final FirebaseFirestore _db;

  PromotionPricingService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _collection => _db.collection('promotionPricing');

  Future<List<PromotionPricingModel>> getActivePromotions() async {
    final snapshot =
        await _collection.where('isActive', isEqualTo: true).get();
    return snapshot.docs
        .map((doc) => PromotionPricingModel.fromMap(
              doc.data() as Map<String, dynamic>,
              id: doc.id,
            ))
        .toList();
  }

  Future<List<PromotionPricingModel>> getPromotionsForCategory(
      String categoryId) async {
    final snapshot = await _collection
        .where('isActive', isEqualTo: true)
        .where('applicableCategoryIds', arrayContains: categoryId)
        .get();

    // Also fetch promotions with empty applicableCategoryIds (apply to all)
    final allSnapshot = await _collection
        .where('isActive', isEqualTo: true)
        .get();

    final allPromotions = allSnapshot.docs
        .map((doc) => PromotionPricingModel.fromMap(
              doc.data() as Map<String, dynamic>,
              id: doc.id,
            ))
        .toList();

    final categorySpecific = snapshot.docs
        .map((doc) => PromotionPricingModel.fromMap(
              doc.data() as Map<String, dynamic>,
              id: doc.id,
            ))
        .toList();

    // Merge: category-specific + those with empty applicableCategoryIds
    final seen = <String>{};
    final results = <PromotionPricingModel>[];

    for (final p in categorySpecific) {
      if (seen.add(p.id)) results.add(p);
    }
    for (final p in allPromotions) {
      if (p.applicableCategoryIds.isEmpty && seen.add(p.id)) {
        results.add(p);
      }
    }

    return results;
  }

  Future<PromotionPricingModel?> getPromotionById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return PromotionPricingModel.fromMap(
      doc.data() as Map<String, dynamic>,
      id: doc.id,
    );
  }

  Future<String> createPromotion(PromotionPricingModel promotion) async {
    final docRef = await _collection.add(promotion.toJson());
    return docRef.id;
  }

  Future<void> updatePromotion(
      String id, PromotionPricingModel promotion) async {
    await _collection.doc(id).update(promotion.toJson());
  }

  Future<void> deletePromotion(String id) async {
    await _collection.doc(id).delete();
  }
}
