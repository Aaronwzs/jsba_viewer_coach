import 'package:flutter/material.dart';
import 'package:jsba_app/app/model/player_category_model.dart';
import 'package:jsba_app/app/model/promotion_pricing_model.dart';
import 'package:jsba_app/app/service/player_category_service.dart';
import 'package:jsba_app/app/service/promotion_pricing_service.dart';

class PlayerDetailViewModel extends ChangeNotifier {
  final PlayerCategoryService _categoryService;
  final PromotionPricingService _promotionService;

  PlayerDetailViewModel({
    PlayerCategoryService? categoryService,
    PromotionPricingService? promotionService,
  })  : _categoryService = categoryService ?? PlayerCategoryService(),
        _promotionService = promotionService ?? PromotionPricingService();

  PlayerCategoryModel? _category;
  List<PromotionPricingModel> _promotions = [];
  bool _isLoading = false;
  String? _error;

  PlayerCategoryModel? get category => _category;
  List<PromotionPricingModel> get promotions => _promotions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double? get groupPrice => _category?.groupPrice;
  double? get privatePrice => _category?.privatePrice;

  Future<void> loadPlayerPricing(String? categoryId) async {
    if (categoryId == null || categoryId.isEmpty) {
      _category = null;
      _promotions = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _category = await _categoryService.getCategoryById(categoryId);
      _promotions =
          await _promotionService.getPromotionsForCategory(categoryId);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void clear() {
    _category = null;
    _promotions = [];
    _error = null;
    notifyListeners();
  }
}
