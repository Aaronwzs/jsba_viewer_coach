import 'package:flutter_test/flutter_test.dart';
import 'package:jsba_app/app/model/open_court_model.dart';
import 'package:jsba_app/app/service/open_court_service.dart';
import 'package:jsba_app/app/service/player_service.dart';
import 'package:jsba_app/app/service/training_service.dart';
import 'package:jsba_app/app/viewmodel/open_court_view_model.dart';
import 'package:mocktail/mocktail.dart';
import '../helpers/model_factories.dart';

class MockOpenCourtService extends Mock implements OpenCourtService {}
class MockTrainingService extends Mock implements TrainingService {}
class MockPlayerService extends Mock implements PlayerService {}

void main() {
  group('OpenCourtViewModel', () {
    late MockOpenCourtService service;
    late MockTrainingService trainingService;
    late MockPlayerService playerService;
    late OpenCourtViewModel viewModel;

    setUp(() {
      service = MockOpenCourtService();
      trainingService = MockTrainingService();
      playerService = MockPlayerService();
      viewModel = OpenCourtViewModel(
        service: service,
        trainingService: trainingService,
        playerService: playerService,
      );
    });

    group('loadSessions', () {
      test('loads all sessions', () async {
        final session = TestModelFactory.createOpenCourtSession(id: 'oc1');

        when(() => service.getAllSessions())
            .thenAnswer((_) async => [session]);

        await viewModel.loadSessions();

        expect(viewModel.isLoading, false);
        expect(viewModel.sessions.length, 1);
        expect(viewModel.sessions.first.id, 'oc1');
      });

      test('sets error on failure', () async {
        when(() => service.getAllSessions())
            .thenThrow(Exception('Load error'));

        await viewModel.loadSessions();

        expect(viewModel.errorMessage, contains('Load error'));
        expect(viewModel.isLoading, false);
      });
    });

    group('loadAvailableSessions', () {
      test('filters by relevant statuses', () async {
        final openForBooking = TestModelFactory.createOpenCourtSession(
          id: 'oc1',
          status: OpenCourtModel.statusOpenForBooking,
        );
        final reserved = TestModelFactory.createOpenCourtSession(
          id: 'oc2',
          status: OpenCourtModel.statusReservedForBooking,
        );
        final openForReg = TestModelFactory.createOpenCourtSession(
          id: 'oc3',
          status: OpenCourtModel.statusOpenForRegistration,
        );
        final closed = TestModelFactory.createOpenCourtSession(
          id: 'oc4',
          status: OpenCourtModel.statusClosed,
        );
        final draft = TestModelFactory.createOpenCourtSession(
          id: 'oc5',
          status: OpenCourtModel.statusDraft,
        );
        final booked = TestModelFactory.createOpenCourtSession(
          id: 'oc6',
          status: OpenCourtModel.statusBooked,
        );

        when(() => service.getAllSessions())
            .thenAnswer((_) async => [
              openForBooking,
              reserved,
              openForReg,
              closed,
              draft,
              booked,
            ]);

        await viewModel.loadAvailableSessions();

        expect(viewModel.availableSessions.length, 4);
        expect(viewModel.availableSessions.map((s) => s.id),
            containsAll(['oc1', 'oc2', 'oc3', 'oc4']));
      });

      test('sets error on failure', () async {
        when(() => service.getAllSessions())
            .thenThrow(Exception('Avail error'));

        await viewModel.loadAvailableSessions();

        expect(viewModel.errorMessage, contains('Avail error'));
        expect(viewModel.isLoading, false);
      });
    });

    group('openForBookingSessions', () {
      test('returns sessions with booking or reserved status', () async {
        final openForBooking = TestModelFactory.createOpenCourtSession(
          id: 'oc1',
          status: OpenCourtModel.statusOpenForBooking,
        );
        final reserved = TestModelFactory.createOpenCourtSession(
          id: 'oc2',
          status: OpenCourtModel.statusReservedForBooking,
        );
        final openForReg = TestModelFactory.createOpenCourtSession(
          id: 'oc3',
          status: OpenCourtModel.statusOpenForRegistration,
        );

        when(() => service.getAllSessions())
            .thenAnswer((_) async => [openForBooking, reserved, openForReg]);

        await viewModel.loadAvailableSessions();

        expect(viewModel.openForBookingSessions.length, 2);
        expect(viewModel.openForBookingSessions.map((s) => s.id),
            containsAll(['oc1', 'oc2']));
      });
    });

    group('bookCourt', () {
      test('calls service and reloads', () async {
        when(() => service.bookCourt(
          sessionId: any(named: 'sessionId'),
          parentName: any(named: 'parentName'),
          userId: any(named: 'userId'),
        )).thenAnswer((_) async => {});
        when(() => service.getAllSessions())
            .thenAnswer((_) async => []);

        final result = await viewModel.bookCourt(
          sessionId: 'oc1',
          parentName: 'Parent',
          userId: 'user1',
        );

        expect(result, true);
        expect(viewModel.isLoading, false);
        verify(() => service.bookCourt(
          sessionId: 'oc1',
          parentName: 'Parent',
          userId: 'user1',
        )).called(1);
      });

      test('returns false on failure', () async {
        when(() => service.bookCourt(
          sessionId: any(named: 'sessionId'),
          parentName: any(named: 'parentName'),
          userId: any(named: 'userId'),
        )).thenThrow(Exception('Book failed'));

        final result = await viewModel.bookCourt(
          sessionId: 'oc1',
          parentName: 'Parent',
          userId: 'user1',
        );

        expect(result, false);
        expect(viewModel.errorMessage, contains('Book failed'));
        expect(viewModel.isLoading, false);
      });
    });

    group('reserveCourt', () {
      test('calls service and reloads', () async {
        final session = TestModelFactory.createOpenCourtSession(id: 'oc1');

        when(() => service.reserveCourt(
          sessionId: any(named: 'sessionId'),
          parentName: any(named: 'parentName'),
          userId: any(named: 'userId'),
        )).thenAnswer((_) async => {});
        when(() => service.getAllSessions())
            .thenAnswer((_) async => []);
        when(() => service.getSession(any()))
            .thenAnswer((_) async => session);

        final result = await viewModel.reserveCourt(
          sessionId: 'oc1',
          parentName: 'Parent',
          userId: 'user1',
        );

        expect(result, true);
        expect(viewModel.isLoading, false);
        verify(() => service.reserveCourt(
          sessionId: 'oc1',
          parentName: 'Parent',
          userId: 'user1',
        )).called(1);
      });

      test('returns false on failure', () async {
        when(() => service.reserveCourt(
          sessionId: any(named: 'sessionId'),
          parentName: any(named: 'parentName'),
          userId: any(named: 'userId'),
        )).thenThrow(Exception('Reserve failed'));

        final result = await viewModel.reserveCourt(
          sessionId: 'oc1',
          parentName: 'Parent',
          userId: 'user1',
        );

        expect(result, false);
        expect(viewModel.errorMessage, contains('Reserve failed'));
      });
    });

    group('cancelReservation', () {
      test('calls service and reloads', () async {
        final session = TestModelFactory.createOpenCourtSession(id: 'oc1');

        when(() => service.cancelReservation(any()))
            .thenAnswer((_) async => {});
        when(() => service.getAllSessions())
            .thenAnswer((_) async => []);
        when(() => service.getSession(any()))
            .thenAnswer((_) async => session);

        final result = await viewModel.cancelReservation('oc1');

        expect(result, true);
        expect(viewModel.isLoading, false);
        verify(() => service.cancelReservation('oc1')).called(1);
      });

      test('returns false on failure', () async {
        when(() => service.cancelReservation(any()))
            .thenThrow(Exception('Cancel failed'));

        final result = await viewModel.cancelReservation('oc1');

        expect(result, false);
        expect(viewModel.errorMessage, contains('Cancel failed'));
      });
    });

    group('undoBooking', () {
      test('calls service and reloads', () async {
        final session = TestModelFactory.createOpenCourtSession(id: 'oc1');

        when(() => service.undoBooking(any()))
            .thenAnswer((_) async => {});
        when(() => service.getAllSessions())
            .thenAnswer((_) async => []);
        when(() => service.getSession(any()))
            .thenAnswer((_) async => session);

        final result = await viewModel.undoBooking('oc1');

        expect(result, true);
        expect(viewModel.isLoading, false);
        verify(() => service.undoBooking('oc1')).called(1);
      });

      test('returns false on failure', () async {
        when(() => service.undoBooking(any()))
            .thenThrow(Exception('Undo failed'));

        final result = await viewModel.undoBooking('oc1');

        expect(result, false);
        expect(viewModel.errorMessage, contains('Undo failed'));
      });
    });

    group('confirmBooking', () {
      test('calls service and reloads', () async {
        final session = TestModelFactory.createOpenCourtSession(id: 'oc1');

        when(() => service.confirmBooking(
          sessionId: any(named: 'sessionId'),
          parentName: any(named: 'parentName'),
          userId: any(named: 'userId'),
        )).thenAnswer((_) async => {});
        when(() => service.getAllSessions())
            .thenAnswer((_) async => []);
        when(() => service.getSession(any()))
            .thenAnswer((_) async => session);

        final result = await viewModel.confirmBooking(
          sessionId: 'oc1',
          parentName: 'Parent',
          userId: 'user1',
        );

        expect(result, true);
        expect(viewModel.isLoading, false);
        verify(() => service.confirmBooking(
          sessionId: 'oc1',
          parentName: 'Parent',
          userId: 'user1',
        )).called(1);
      });

      test('returns false on failure', () async {
        when(() => service.confirmBooking(
          sessionId: any(named: 'sessionId'),
          parentName: any(named: 'parentName'),
          userId: any(named: 'userId'),
        )).thenThrow(Exception('Confirm failed'));

        final result = await viewModel.confirmBooking(
          sessionId: 'oc1',
          parentName: 'Parent',
          userId: 'user1',
        );

        expect(result, false);
        expect(viewModel.errorMessage, contains('Confirm failed'));
      });
    });

    group('registerPlayer', () {
      test('updates session and reloads', () async {
        when(() => service.registerPlayer(
          sessionId: any(named: 'sessionId'),
          playerId: any(named: 'playerId'),
        )).thenAnswer((_) async => {});
        when(() => service.getAllSessions())
            .thenAnswer((_) async => []);

        final result = await viewModel.registerPlayer(
          sessionId: 'oc1',
          playerId: 'p1',
        );

        expect(result, true);
        expect(viewModel.isLoading, false);
        verify(() => service.registerPlayer(
          sessionId: 'oc1',
          playerId: 'p1',
        )).called(1);
      });

      test('returns false on failure', () async {
        when(() => service.registerPlayer(
          sessionId: any(named: 'sessionId'),
          playerId: any(named: 'playerId'),
        )).thenThrow(Exception('Register failed'));

        final result = await viewModel.registerPlayer(
          sessionId: 'oc1',
          playerId: 'p1',
        );

        expect(result, false);
        expect(viewModel.errorMessage, contains('Register failed'));
      });
    });

    group('loadSession', () {
      test('loads session with player names and images', () async {
        final session = TestModelFactory.createOpenCourtSession(
          id: 'oc1',
          playerIds: ['p1', 'p2'],
        );

        when(() => service.getSession('oc1'))
            .thenAnswer((_) async => session);
        when(() => playerService.getPlayerNames(['p1', 'p2']))
            .thenAnswer((_) async => {'p1': 'Alice', 'p2': 'Bob'});
        when(() => playerService.getPlayerImages(['p1', 'p2']))
            .thenAnswer((_) async => {'p1': 'http://img.alice'});

        await viewModel.loadSession('oc1');

        expect(viewModel.isLoading, false);
        expect(viewModel.currentSession, isNotNull);
        expect(viewModel.currentSession!.id, 'oc1');
        expect(viewModel.playerNames['p1'], 'Alice');
        expect(viewModel.playerNames['p2'], 'Bob');
        expect(viewModel.playerImages['p1'], 'http://img.alice');
      });

      test('handles session with no playerIds', () async {
        final session = TestModelFactory.createOpenCourtSession(
          id: 'oc1',
          playerIds: [],
        );

        when(() => service.getSession('oc1'))
            .thenAnswer((_) async => session);

        await viewModel.loadSession('oc1');

        expect(viewModel.currentSession, isNotNull);
        expect(viewModel.playerNames, isEmpty);
        expect(viewModel.playerImages, isEmpty);
      });

      test('sets error on failure', () async {
        when(() => service.getSession(any()))
            .thenThrow(Exception('Session error'));

        await viewModel.loadSession('oc1');

        expect(viewModel.errorMessage, contains('Session error'));
        expect(viewModel.isLoading, false);
      });
    });

    group('setSelectedMonth', () {
      test('updates selected month', () {
        final month = DateTime(2024, 9);
        viewModel.setSelectedMonth(month);
        expect(viewModel.selectedMonth.year, 2024);
        expect(viewModel.selectedMonth.month, 9);
      });
    });

    group('removePlayer', () {
      test('removes player and reloads', () async {
        final session = TestModelFactory.createOpenCourtSession(id: 'oc1');

        when(() => service.removePlayer(any(), any()))
            .thenAnswer((_) async => {});
        when(() => service.getAllSessions())
            .thenAnswer((_) async => []);
        when(() => service.getSession(any()))
            .thenAnswer((_) async => session);

        await viewModel.removePlayer('oc1', 'p1');

        expect(viewModel.isLoading, false);
        verify(() => service.removePlayer('oc1', 'p1')).called(1);
      });

      test('sets error on failure', () async {
        when(() => service.removePlayer(any(), any()))
            .thenThrow(Exception('Remove failed'));

        await viewModel.removePlayer('oc1', 'p1');

        expect(viewModel.errorMessage, contains('Remove failed'));
        expect(viewModel.isLoading, false);
      });
    });

    group('clearError', () {
      test('resets error message', () {
        viewModel.setSelectedMonth(DateTime(2024, 6));

        when(() => service.getAllSessions())
            .thenThrow(Exception('An error'));

        viewModel.loadAvailableSessions();

        viewModel.clearError();
        expect(viewModel.errorMessage, isNull);
      });
    });
  });
}
