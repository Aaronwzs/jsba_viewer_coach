import 'package:flutter/material.dart';
import 'package:jsba_app/app/model/availability_model.dart';
import 'package:jsba_app/app/service/availability_service.dart';

class AvailabilityViewModel extends ChangeNotifier {
  final AvailabilityService _service = AvailabilityService();

  List<AvailabilityModel> _slots = [];
  bool _isLoading = false;
  String? _error;

  List<AvailabilityModel> get slots => _slots;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSlots() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _slots = await _service.getActiveSlots();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> respond(String slotId, String playerId, bool canJoin) async {
    try {
      await _service.respond(slotId, playerId, canJoin);

      final index = _slots.indexWhere((s) => s.id == slotId);
      if (index != -1) {
        final slot = _slots[index];
        final updatedResponses = Map<String, bool>.from(slot.responses);
        updatedResponses[playerId] = canJoin;
        _slots[index] = slot.copyWith(responses: updatedResponses);
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeResponse(String slotId, String playerId) async {
    try {
      await _service.removeResponse(slotId, playerId);

      final index = _slots.indexWhere((s) => s.id == slotId);
      if (index != -1) {
        final slot = _slots[index];
        final updatedResponses = Map<String, bool>.from(slot.responses);
        updatedResponses.remove(playerId);
        _slots[index] = slot.copyWith(responses: updatedResponses);
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
