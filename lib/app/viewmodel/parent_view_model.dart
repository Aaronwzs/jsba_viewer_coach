import 'package:flutter/material.dart';
import 'package:jsba_app/app/service/player_service.dart';
import 'package:jsba_app/app/service/training_service.dart';
import 'package:jsba_app/app/model/player_model.dart';
import 'package:jsba_app/app/model/training_model.dart';

class ParentViewModel extends ChangeNotifier {
  final PlayerService _playerService = PlayerService();
  final TrainingService _trainingService = TrainingService();

  List<PlayerModel> _myKids = [];
  List<PlayerModel> _pendingKids = [];
  PlayerModel? _selfPlayer;
  List<TrainingModel> _upcomingSessions = [];
  bool _isLoading = false;
  String? _error;

  List<PlayerModel> get myKids => _myKids;
  List<PlayerModel> get pendingKids => _pendingKids;
  List<PlayerModel> get allKids => [..._myKids, ..._pendingKids];
  PlayerModel? get selfPlayer => _selfPlayer;
  bool get hasSelfAdded => _selfPlayer != null;
  List<TrainingModel> get upcomingSessions => _upcomingSessions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMyKids(String parentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final allPlayers = await _playerService.getPlayersByParentId(parentId);

      _selfPlayer = allPlayers.where((p) => p.isSelf).firstOrNull;

      _myKids = allPlayers
          .where((p) => !p.isSelf && p.status == PlayerStatus.approved)
          .toList();

      _pendingKids = allPlayers
          .where((p) => !p.isSelf && p.status == PlayerStatus.pending)
          .toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addSelf(
    String parentId,
    String name,
    int age,
    String level,
    String phone,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final player = PlayerModel(
        id: '',
        name: name,
        age: age,
        level: level,
        phone: phone,
        createdAt: DateTime.now(),
        isActive: true,
        parentId: parentId,
        status: PlayerStatus.approved,
        isSelf: true,
      );

      await _playerService.createPlayer(player);
      await loadMyKids(parentId);
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> addChild(PlayerModel player) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newPlayer = PlayerModel(
        id: '',
        name: player.name,
        age: player.age,
        level: player.level,
        phone: player.phone,
        createdAt: DateTime.now(),
        isActive: true,
        parentId: player.parentId,
        parentName: player.parentName,
        parentPhone: player.parentPhone,
        parentEmail: player.parentEmail,
        status: PlayerStatus.pending,
        isSelf: false,
      );

      await _playerService.createPlayer(newPlayer);
      if (player.parentId != null) {
        await loadMyKids(player.parentId!);
      }
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
