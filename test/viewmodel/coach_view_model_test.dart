import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:jsba_app/app/model/training_model.dart';
import 'package:jsba_app/app/service/player_service.dart';
import 'package:jsba_app/app/service/training_service.dart';
import 'package:jsba_app/app/viewmodel/coach_view_model.dart';
import 'package:mocktail/mocktail.dart';
import '../helpers/model_factories.dart';

class MockTrainingService extends Mock implements TrainingService {}
class MockPlayerService extends Mock implements PlayerService {}

void main() {
  group('CoachViewModel', () {
    late MockTrainingService trainingService;
    late MockPlayerService playerService;
    late CoachViewModel viewModel;

    setUp(() {
      trainingService = MockTrainingService();
      playerService = MockPlayerService();
      viewModel = CoachViewModel(
        trainingService: trainingService,
        playerService: playerService,
      );
    });

    group('loadCoachData', () {
      test('loads today sessions and players', () async {
        final todaySession = TestModelFactory.createTraining(id: 't1');
        final player = TestModelFactory.createPlayer(id: 'p1');

        when(() => trainingService.getTrainingsForToday())
            .thenAnswer((_) async => [todaySession]);
        when(() => playerService.getPlayers())
            .thenAnswer((_) async => [player]);

        await viewModel.loadCoachData();

        expect(viewModel.isLoading, false);
        expect(viewModel.todaySessions.length, 1);
        expect(viewModel.todaySessions.first.id, 't1');
        expect(viewModel.players.length, 1);
        expect(viewModel.players.first.id, 'p1');
      });

      test('sets error on failure', () async {
        when(() => trainingService.getTrainingsForToday())
            .thenThrow(Exception('Service error'));

        await viewModel.loadCoachData();

        expect(viewModel.error, contains('Service error'));
        expect(viewModel.isLoading, false);
      });

      test('sets isLoading during load', () async {
        when(() => trainingService.getTrainingsForToday())
            .thenAnswer((_) async => []);
        when(() => playerService.getPlayers())
            .thenAnswer((_) async => []);

        final future = viewModel.loadCoachData();
        expect(viewModel.isLoading, true);
        await future;
        expect(viewModel.isLoading, false);
      });
    });

    group('loadCoachSessionsForMonth', () {
      test('loads month sessions for coach', () async {
        final session = TestModelFactory.createTraining(id: 't1', coachId: 'coach1');

        when(() => trainingService.getTrainingsForCoachInMonth(
          any(), any(), any(),
        )).thenAnswer((_) async => [session]);

        await viewModel.loadCoachSessionsForMonth('coach1');

        expect(viewModel.isLoading, false);
        expect(viewModel.monthSessions.length, 1);
        expect(viewModel.monthSessions.first.id, 't1');
        verify(() => trainingService.getTrainingsForCoachInMonth(
          'coach1', any(), any(),
        )).called(1);
      });

      test('sets error on failure', () async {
        when(() => trainingService.getTrainingsForCoachInMonth(
          any(), any(), any(),
        )).thenThrow(Exception('Month error'));

        await viewModel.loadCoachSessionsForMonth('coach1');

        expect(viewModel.error, contains('Month error'));
        expect(viewModel.isLoading, false);
      });
    });

    group('loadAllCoachSessions', () {
      test('loads all sessions for coach', () async {
        final session = TestModelFactory.createTraining(id: 't1', coachId: 'coach1');

        when(() => trainingService.getTrainingsForCoach('coach1'))
            .thenAnswer((_) async => [session]);

        await viewModel.loadAllCoachSessions('coach1');

        expect(viewModel.isLoading, false);
        expect(viewModel.monthSessions.length, 1);
        verify(() => trainingService.getTrainingsForCoach('coach1')).called(1);
      });

      test('sets error on failure', () async {
        when(() => trainingService.getTrainingsForCoach(any()))
            .thenThrow(Exception('All sessions error'));

        await viewModel.loadAllCoachSessions('coach1');

        expect(viewModel.error, contains('All sessions error'));
      });
    });

    group('loadAllSessions', () {
      test('loads from stream', () async {
        final session = TestModelFactory.createTraining(id: 't1');
        final streamController = StreamController<List<TrainingModel>>();

        when(() => trainingService.getAllTrainings())
            .thenAnswer((_) => streamController.stream);

        final future = viewModel.loadAllSessions();
        streamController.add([session]);
        await future;

        expect(viewModel.isLoading, false);
        expect(viewModel.todaySessions.length, 1);
        expect(viewModel.todaySessions.first.id, 't1');

        await streamController.close();
      });

      test('sets error on failure', () async {
        when(() => trainingService.getAllTrainings())
            .thenThrow(Exception('Stream error'));

        await viewModel.loadAllSessions();

        expect(viewModel.error, contains('Stream error'));
        expect(viewModel.isLoading, false);
      });
    });

    group('totalSessionsThisMonth', () {
      test('returns correct count', () async {
        when(() => trainingService.getTrainingsForCoachInMonth(
          any(), any(), any(),
        )).thenAnswer((_) async => [
          TestModelFactory.createTraining(id: 't1', coachId: 'coach1'),
          TestModelFactory.createTraining(id: 't2', coachId: 'coach1'),
        ]);

        await viewModel.loadCoachSessionsForMonth('coach1');

        expect(viewModel.totalSessionsThisMonth, 2);
      });

      test('returns 0 when no sessions loaded', () {
        expect(viewModel.totalSessionsThisMonth, 0);
      });
    });

    group('totalPlayers', () {
      test('returns correct count', () async {
        when(() => trainingService.getTrainingsForToday())
            .thenAnswer((_) async => []);
        when(() => playerService.getPlayers())
            .thenAnswer((_) async => [
              TestModelFactory.createPlayer(id: 'p1'),
              TestModelFactory.createPlayer(id: 'p2'),
              TestModelFactory.createPlayer(id: 'p3'),
            ]);

        await viewModel.loadCoachData();

        expect(viewModel.totalPlayers, 3);
      });

      test('returns 0 when no players loaded', () {
        expect(viewModel.totalPlayers, 0);
      });
    });

    group('createTraining', () {
      test('adds training and reloads', () async {
        final training = TestModelFactory.createTraining(id: 'new-t1');

        when(() => trainingService.addTraining(training))
            .thenAnswer((_) async => 'new-id');
        when(() => trainingService.getTrainingsForToday())
            .thenAnswer((_) async => [training]);
        when(() => playerService.getPlayers())
            .thenAnswer((_) async => []);

        await viewModel.createTraining(training);

        expect(viewModel.isLoading, false);
        verify(() => trainingService.addTraining(training)).called(1);
        verify(() => trainingService.getTrainingsForToday()).called(1);
      });

      test('sets error on failure', () async {
        final training = TestModelFactory.createTraining(id: 't1');

        when(() => trainingService.addTraining(training))
            .thenThrow(Exception('Create failed'));

        await viewModel.createTraining(training);

        expect(viewModel.error, contains('Create failed'));
        expect(viewModel.isLoading, false);
      });
    });

    group('clearError', () {
      test('resets error', () async {
        when(() => trainingService.getTrainingsForToday())
            .thenThrow(Exception('An error'));

        await viewModel.loadCoachData();
        expect(viewModel.error, isNotNull);

        viewModel.clearError();
        expect(viewModel.error, isNull);
      });
    });
  });
}
