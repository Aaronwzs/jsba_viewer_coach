import 'package:flutter/material.dart';
import 'package:jsba_app/app/model/open_court_model.dart';
import 'package:jsba_app/app/model/training_model.dart';
import 'package:jsba_app/app/service/open_court_service.dart';
import 'package:jsba_app/app/service/player_service.dart';
import 'package:jsba_app/app/service/training_service.dart';

class OpenCourtViewModel extends ChangeNotifier {
  final OpenCourtService _service = OpenCourtService();
  final TrainingService _trainingService = TrainingService();
  final PlayerService _playerService = PlayerService();

  List<OpenCourtModel> _sessions = [];
  List<OpenCourtModel> _availableSessions = [];
  List<OpenCourtModel> _myEnrolledSessions = [];
  List<TrainingModel> _myTrainings = [];
  DateTime _selectedMonth = DateTime.now();
  OpenCourtModel? _currentSession;
  bool _isLoading = false;
  String? _errorMessage;

  List<OpenCourtModel> get sessions => _sessions;
  List<OpenCourtModel> get availableSessions => _availableSessions;
  List<OpenCourtModel> get myEnrolledSessions => _myEnrolledSessions;
  List<TrainingModel> get myTrainings => _myTrainings;
  DateTime get selectedMonth => _selectedMonth;
  List<OpenCourtModel> get openForBookingSessions => _availableSessions
      .where(
        (s) =>
            s.status == OpenCourtModel.statusOpenForBooking ||
            s.status == OpenCourtModel.statusReservedForBooking,
      )
      .toList();
  List<OpenCourtModel> get openForRegistrationSessions => _availableSessions
      .where((s) => s.status == OpenCourtModel.statusOpenForRegistration)
      .toList();
  List<OpenCourtModel> get closedSessions =>
      _sessions.where((s) => s.status == OpenCourtModel.statusClosed).toList();
  OpenCourtModel? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, String> _playerNames = {};
  Map<String, String> get playerNames => _playerNames;

  Future<void> loadSessions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _sessions = await _service.getAllSessions();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAvailableSessions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _sessions = await _service.getAllSessions();
      _availableSessions = _sessions
          .where(
            (s) =>
                s.status == OpenCourtModel.statusOpenForBooking ||
                s.status == OpenCourtModel.statusReservedForBooking ||
                s.status == OpenCourtModel.statusOpenForRegistration ||
                s.status == OpenCourtModel.statusClosed,
          )
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMyClasses(List<String> playerIds) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myTrainings = await _trainingService.getTrainingsForPlayersInMonth(
        playerIds,
        _selectedMonth.year,
        _selectedMonth.month,
      );
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void setSelectedMonth(DateTime month) {
    _selectedMonth = month;
    notifyListeners();
  }

  Future<void> loadSession(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentSession = await _service.getSession(id);
      if (_currentSession != null && _currentSession!.playerIds.isNotEmpty) {
        _playerNames = await _playerService.getPlayerNames(
          _currentSession!.playerIds,
        );
      } else {
        _playerNames = {};
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> bookCourt({
    required String sessionId,
    required String parentName,
    required String userId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.bookCourt(
        sessionId: sessionId,
        parentName: parentName,
        userId: userId,
      );
      await loadAvailableSessions();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> reserveCourt({
    required String sessionId,
    required String parentName,
    required String userId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.reserveCourt(
        sessionId: sessionId,
        parentName: parentName,
        userId: userId,
      );
      await loadAvailableSessions();
      await loadSession(sessionId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelReservation(String sessionId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.cancelReservation(sessionId);
      await loadAvailableSessions();
      await loadSession(sessionId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> undoBooking(String sessionId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.undoBooking(sessionId);
      await loadAvailableSessions();
      await loadSession(sessionId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmBooking({
    required String sessionId,
    required String parentName,
    required String userId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.confirmBooking(
        sessionId: sessionId,
        parentName: parentName,
        userId: userId,
      );
      await loadAvailableSessions();
      await loadSession(sessionId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerPlayer({
    required String sessionId,
    required String playerId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.registerPlayer(sessionId: sessionId, playerId: playerId);
      await loadAvailableSessions();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateStatus(String sessionId, String status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updateStatus(sessionId, status);
      await loadAvailableSessions();
      await loadSession(sessionId);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> removePlayer(String sessionId, String playerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.removePlayer(sessionId, playerId);
      await loadAvailableSessions();
      await loadSession(sessionId);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
