import 'package:flutter/foundation.dart';
import 'package:jsba_app/app/model/assessment_event_model.dart';
import 'package:jsba_app/app/model/mini_competition_result_model.dart';
import 'package:jsba_app/app/model/physical_result_model.dart';
import 'package:jsba_app/app/model/player_css_snapshot_model.dart';
import 'package:jsba_app/app/model/player_rating_model.dart';
import 'package:jsba_app/app/model/skill_result_model.dart';
import 'package:jsba_app/app/service/assessment_event_service.dart';
import 'package:jsba_app/app/service/mini_competition_result_service.dart';
import 'package:jsba_app/app/service/physical_result_service.dart';
import 'package:jsba_app/app/service/player_css_snapshot_service.dart';
import 'package:jsba_app/app/service/player_rating_service.dart';
import 'package:jsba_app/app/service/skill_result_service.dart';
import 'package:jsba_app/app/utils/glicko2_calculator.dart';

class AssessmentViewModel extends ChangeNotifier {
  final AssessmentEventService _eventService = AssessmentEventService();
  final PhysicalResultService _physicalService = PhysicalResultService();
  final SkillResultService _skillService = SkillResultService();
  final MiniCompetitionResultService _matchService =
      MiniCompetitionResultService();
  final PlayerRatingService _ratingService = PlayerRatingService();
  final PlayerCssSnapshotService _cssService = PlayerCssSnapshotService();

  List<AssessmentEventWithTraining> _events = [];
  List<AssessmentEventWithTraining> get events => _events;

  Map<String, PlayerRatingModel> _allRatings = {};
  Map<String, PlayerRatingModel> get allRatings => _allRatings;

  AssessmentEventWithTraining? _selectedEvent;
  AssessmentEventWithTraining? get selectedEvent => _selectedEvent;

  List<PhysicalResultModel> _eventPhysicalResults = [];
  List<PhysicalResultModel> get eventPhysicalResults => _eventPhysicalResults;

  List<SkillResultModel> _eventSkillResults = [];
  List<SkillResultModel> get eventSkillResults => _eventSkillResults;

  List<MiniCompetitionResultModel> _eventMatchResults = [];
  List<MiniCompetitionResultModel> get eventMatchResults => _eventMatchResults;

  String? _selectedPlayerId;
  String? get selectedPlayerId => _selectedPlayerId;

  List<PhysicalResultModel> _physicalResults = [];
  List<PhysicalResultModel> get physicalResults => _physicalResults;
  PhysicalResultModel? get latestPhysical =>
      _physicalResults.isNotEmpty ? _physicalResults.first : null;

  List<SkillResultModel> _skillResults = [];
  List<SkillResultModel> get skillResults => _skillResults;
  SkillResultModel? get latestSkill =>
      _skillResults.isNotEmpty ? _skillResults.first : null;

  List<MiniCompetitionResultModel> _matchResults = [];
  List<MiniCompetitionResultModel> get matchResults => _matchResults;

  PlayerRatingModel? _playerRating;
  PlayerRatingModel? get playerRating => _playerRating;

  List<PlayerCssSnapshotModel> _cssHistory = [];
  List<PlayerCssSnapshotModel> get cssHistory => _cssHistory;
  PlayerCssSnapshotModel? get latestCss =>
      _cssHistory.isNotEmpty ? _cssHistory.last : null;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingPlayer = false;
  bool get isLoadingPlayer => _isLoadingPlayer;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get hasStaleData => latestCss?.hasStaleComponent ?? false;

  int get totalWins => _matchResults.where((m) => m.isWin).length;

  double get winRate =>
      _matchResults.isEmpty ? 0 : (totalWins / _matchResults.length * 100);

  Future<void> loadAllRatings() async {
    try {
      final ratings = await _ratingService.getAll();
      _allRatings = {for (final r in ratings) r.playerId: r};
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadEvents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _events = await _eventService.getAllWithTraining();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadEventsByDateRange(DateTime from, DateTime to) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final events = await _eventService.getAllWithTraining();
      _events = events.where((entry) {
        final date = entry.date;
        if (date == null) return false;
        return !date.isBefore(from) && !date.isAfter(to);
      }).toList();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadEventData(AssessmentEventWithTraining event) async {
    _selectedEvent = event;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      switch (event.type) {
        case AssessmentEventType.physical:
          _eventPhysicalResults = await _physicalService.getByEvent(event.id);
          _eventSkillResults = [];
          _eventMatchResults = [];
        case AssessmentEventType.skill:
          _eventSkillResults = await _skillService.getByEvent(event.id);
          _eventPhysicalResults = [];
          _eventMatchResults = [];
        case AssessmentEventType.competition:
          _eventMatchResults = await _matchService.getByEvent(event.id);
          _eventPhysicalResults = [];
          _eventSkillResults = [];
        default:
          break;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadPlayerData(String playerId) async {
    _selectedPlayerId = playerId;
    _isLoadingPlayer = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _physicalService.getByPlayer(playerId),
        _skillService.getByPlayer(playerId),
        _matchService.getByPlayer(playerId),
        _ratingService.getByPlayer(playerId),
        _cssService.getHistoryByPlayer(playerId),
      ]);

      _physicalResults = results[0] as List<PhysicalResultModel>;
      _skillResults = results[1] as List<SkillResultModel>;
      _matchResults = results[2] as List<MiniCompetitionResultModel>;
      _playerRating = results[3] as PlayerRatingModel?;
      _cssHistory = results[4] as List<PlayerCssSnapshotModel>;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoadingPlayer = false;
    notifyListeners();
  }

  Future<bool> saveEvent(AssessmentEventModel event) async {
    return _saving(() async {
      await _eventService.create(event);
      await loadEvents();
    });
  }

  Future<bool> updateEvent(String id, AssessmentEventModel event) async {
    return _saving(() async {
      await _eventService.update(id, event);
      await loadEvents();
    });
  }

  Future<bool> markEventCompleted(String id) async {
    return _saving(() async {
      await _eventService.markCompleted(id);
      await loadEvents();
    });
  }

  Future<bool> markEventCancelled(String id) async {
    return _saving(() async {
      await _eventService.markCancelled(id);
      await loadEvents();
    });
  }

  Future<bool> savePhysicalResult(PhysicalResultModel result) async {
    return _saving(() async {
      await _physicalService.create(result);
      if (_selectedPlayerId == result.playerId) {
        _physicalResults = await _physicalService.getByPlayer(result.playerId);
      }
      await _writeUpdatedCssSnapshot(result.playerId, result.playerName);
      if (_selectedEvent?.id == result.eventId) {
        _eventPhysicalResults = await _physicalService.getByEvent(
          result.eventId,
        );
      }
    });
  }

  Future<bool> updatePhysicalResult(
    String id,
    PhysicalResultModel result,
  ) async {
    return _saving(() async {
      await _physicalService.update(id, result);
      if (_selectedPlayerId == result.playerId) {
        _physicalResults = await _physicalService.getByPlayer(result.playerId);
      }
      await _writeUpdatedCssSnapshot(result.playerId, result.playerName);
      if (_selectedEvent?.id == result.eventId) {
        _eventPhysicalResults = await _physicalService.getByEvent(
          result.eventId,
        );
      }
    });
  }

  Future<bool> saveSkillResult(SkillResultModel result) async {
    return _saving(() async {
      await _skillService.create(result);
      if (_selectedPlayerId == result.playerId) {
        _skillResults = await _skillService.getByPlayer(result.playerId);
      }
      await _writeUpdatedCssSnapshot(result.playerId, result.playerName);
      if (_selectedEvent?.id == result.eventId) {
        _eventSkillResults = await _skillService.getByEvent(result.eventId);
      }
    });
  }

  Future<bool> updateSkillResult(String id, SkillResultModel result) async {
    return _saving(() async {
      await _skillService.update(id, result);
      if (_selectedPlayerId == result.playerId) {
        _skillResults = await _skillService.getByPlayer(result.playerId);
      }
      await _writeUpdatedCssSnapshot(result.playerId, result.playerName);
      if (_selectedEvent?.id == result.eventId) {
        _eventSkillResults = await _skillService.getByEvent(result.eventId);
      }
    });
  }

  Future<bool> saveMiniCompResult(MiniCompetitionResultModel result) async {
    return _saving(() async {
      final myRating =
          (_selectedPlayerId == result.playerId && _playerRating != null)
          ? _playerRating!
          : await _ratingService.getByPlayer(result.playerId) ??
                PlayerRatingModel.initial(result.playerId);

      final oppRating =
          await _ratingService.getByPlayer(result.opponentId) ??
          PlayerRatingModel.initial(result.opponentId);

      final updated = Glicko2Calculator.calculate(
        player: myRating,
        opponent: oppRating,
        playerWon: result.isWin,
      );

      final enriched = result.copyWith(
        ratingBefore: myRating.rating,
        ratingAfter: updated.player.rating,
        ratingDeviation: updated.player.ratingDeviation,
      );
      await _matchService.create(enriched);

      await _ratingService.upsert(updated.player);
      await _ratingService.upsert(updated.opponent);

      if (_selectedPlayerId == result.playerId) {
        _playerRating = updated.player;
      }
      if (_selectedPlayerId == result.playerId) {
        _matchResults = await _matchService.getByPlayer(result.playerId);
      }
      await _writeUpdatedCssSnapshot(result.playerId, result.playerName);

      if (_selectedEvent?.id == result.eventId) {
        _eventMatchResults = await _matchService.getByEvent(result.eventId);
      }
    });
  }

  Future<bool> updateMiniCompResult(
    String id,
    MiniCompetitionResultModel result,
  ) async {
    return _saving(() async {
      await _matchService.update(id, result);
      if (_selectedPlayerId == result.playerId) {
        _matchResults = await _matchService.getByPlayer(result.playerId);
      }
      if (_selectedEvent?.id == result.eventId) {
        _eventMatchResults = await _matchService.getByEvent(result.eventId);
      }
    });
  }

  Future<void> _writeUpdatedCssSnapshot(
    String playerId,
    String playerName,
  ) async {
    final previous = await _cssService.getLatestByPlayer(playerId);
    final physical = await _physicalService.getLatestByPlayer(playerId);
    final skill = await _skillService.getLatestByPlayer(playerId);
    final rating = (_selectedPlayerId == playerId && _playerRating != null)
        ? _playerRating!
        : await _ratingService.getByPlayer(playerId) ??
              PlayerRatingModel.initial(playerId);

    final newSnapshot = PlayerCssSnapshotModel(
      id: '',
      playerId: playerId,
      playerName: playerName,
      snapshotDate: DateTime.now(),
      physicalScore: physical?.physicalScore,
      physicalAssessedAt: physical?.date,
      technicalScore: skill?.technicalScore,
      technicalAssessedAt: skill?.date,
      matchScore: rating.matchScore,
      matchAssessedAt: rating.lastMatchDate,
      trend: _computeTrend(
        previous?.cssTotal ?? 0,
        physicalScore: physical?.physicalScore,
        technicalScore: skill?.technicalScore,
        matchScore: rating.matchScore,
      ),
    );

    await _cssService.create(newSnapshot);
    if (_selectedPlayerId == playerId) {
      _cssHistory = await _cssService.getHistoryByPlayer(playerId);
    }
  }

  String _computeTrend(
    double previousTotal, {
    double? physicalScore,
    double? technicalScore,
    double? matchScore,
  }) {
    final tempSnapshot = PlayerCssSnapshotModel(
      id: '',
      playerId: '',
      playerName: '',
      snapshotDate: DateTime.now(),
      physicalScore: physicalScore,
      technicalScore: technicalScore,
      matchScore: matchScore,
    );

    final newTotal = tempSnapshot.cssTotal;
    if (newTotal > previousTotal + 1) return CssTrend.up;
    if (newTotal < previousTotal - 1) return CssTrend.down;
    return CssTrend.flat;
  }

  Future<bool> _saving(Future<void> Function() operation) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await operation();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clearPlayerData() {
    _selectedPlayerId = null;
    _physicalResults = [];
    _skillResults = [];
    _matchResults = [];
    _playerRating = null;
    _cssHistory = [];
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
