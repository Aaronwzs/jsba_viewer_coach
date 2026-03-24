import 'package:flutter/material.dart';
import 'package:jsba_app/app/service/training_service.dart';
import 'package:jsba_app/app/service/player_service.dart';
import 'package:jsba_app/app/model/training_model.dart';
import 'package:jsba_app/app/model/player_model.dart';

class CoachViewModel extends ChangeNotifier {
  final TrainingService _trainingService = TrainingService();
  final PlayerService _playerService = PlayerService();

  List<TrainingModel> _todaySessions = [];
  List<PlayerModel> _players = [];
  bool _isLoading = false;
  String? _error;

  List<TrainingModel> get todaySessions => _todaySessions;
  List<PlayerModel> get players => _players;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalSessionsThisMonth {
    return _todaySessions.length;
  }

  int get totalPlayers => _players.length;

  Future<void> loadCoachData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _todaySessions = await _trainingService.getTrainingsForToday();
      _players = await _playerService.getPlayers();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAllSessions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _todaySessions = await _trainingService.getAllTrainings().first;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createTraining(TrainingModel training) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _trainingService.addTraining(training);
      await loadCoachData();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
