import 'package:flutter_test/flutter_test.dart';
import 'package:jsba_app/app/model/player_model.dart';
import 'package:jsba_app/app/service/player_service.dart';
import 'package:jsba_app/app/viewmodel/parent_view_model.dart';
import 'package:mocktail/mocktail.dart';
import '../helpers/model_factories.dart';

class MockPlayerService extends Mock implements PlayerService {}

void main() {
  group('ParentViewModel', () {
    late MockPlayerService playerService;
    late ParentViewModel viewModel;

    setUpAll(() {
      registerFallbackValue(TestModelFactory.createPlayer());
    });

    setUp(() {
      playerService = MockPlayerService();
      viewModel = ParentViewModel(playerService: playerService);
    });

    group('loadMyKids', () {
      test('splits players into self, approved kids, pending kids', () async {
        final selfPlayer = TestModelFactory.createPlayer(
          id: 'self1',
          name: 'Parent Self',
          isSelf: true,
          status: PlayerStatus.approved,
        );
        final approvedKid = TestModelFactory.createPlayer(
          id: 'kid1',
          name: 'Kid Approved',
          isSelf: false,
          status: PlayerStatus.approved,
        );
        final pendingKid = TestModelFactory.createPlayer(
          id: 'kid2',
          name: 'Kid Pending',
          isSelf: false,
          status: PlayerStatus.pending,
        );

        when(() => playerService.getPlayersByParentId('parent1'))
            .thenAnswer((_) async => [selfPlayer, approvedKid, pendingKid]);

        await viewModel.loadMyKids('parent1');

        expect(viewModel.isLoading, false);
        expect(viewModel.selfPlayer, isNotNull);
        expect(viewModel.selfPlayer!.id, 'self1');
        expect(viewModel.myKids.length, 1);
        expect(viewModel.myKids.first.id, 'kid1');
        expect(viewModel.pendingKids.length, 1);
        expect(viewModel.pendingKids.first.id, 'kid2');
      });

      test('handles no self player', () async {
        final approvedKid = TestModelFactory.createPlayer(
          id: 'kid1',
          isSelf: false,
          status: PlayerStatus.approved,
        );

        when(() => playerService.getPlayersByParentId('parent1'))
            .thenAnswer((_) async => [approvedKid]);

        await viewModel.loadMyKids('parent1');

        expect(viewModel.selfPlayer, isNull);
        expect(viewModel.myKids.length, 1);
        expect(viewModel.pendingKids.length, 0);
      });

      test('sets error on failure', () async {
        when(() => playerService.getPlayersByParentId(any()))
            .thenThrow(Exception('Load error'));

        await viewModel.loadMyKids('parent1');

        expect(viewModel.error, contains('Load error'));
        expect(viewModel.isLoading, false);
      });
    });

    group('allKids', () {
      test('combines myKids and pendingKids', () async {
        final selfPlayer = TestModelFactory.createPlayer(
          id: 'self1',
          name: 'Me',
          isSelf: true,
          status: PlayerStatus.approved,
        );
        final approvedKid = TestModelFactory.createPlayer(
          id: 'kid1',
          name: 'Alice',
          isSelf: false,
          status: PlayerStatus.approved,
        );
        final pendingKid = TestModelFactory.createPlayer(
          id: 'kid2',
          name: 'Bob',
          isSelf: false,
          status: PlayerStatus.pending,
        );

        when(() => playerService.getPlayersByParentId('parent1'))
            .thenAnswer((_) async => [selfPlayer, approvedKid, pendingKid]);

        await viewModel.loadMyKids('parent1');

        expect(viewModel.allKids.length, 2);
        expect(viewModel.allKids.map((p) => p.id),
            containsAll(['kid1', 'kid2']));
        expect(viewModel.allKids.map((p) => p.id),
            isNot(contains('self1')));
      });
    });

    group('hasSelfAdded', () {
      test('returns true when selfPlayer is present', () async {
        final selfPlayer = TestModelFactory.createPlayer(
          id: 'self1',
          isSelf: true,
        );

        when(() => playerService.getPlayersByParentId('parent1'))
            .thenAnswer((_) async => [selfPlayer]);

        await viewModel.loadMyKids('parent1');

        expect(viewModel.hasSelfAdded, true);
      });

      test('returns false when no selfPlayer', () async {
        when(() => playerService.getPlayersByParentId('parent1'))
            .thenAnswer((_) async => []);

        await viewModel.loadMyKids('parent1');

        expect(viewModel.hasSelfAdded, false);
      });
    });

    group('addSelf', () {
      test('creates self player and reloads', () async {
        when(() => playerService.createPlayer(any()))
            .thenAnswer((_) async => 'new-self-id');
        when(() => playerService.getPlayersByParentId('parent1'))
            .thenAnswer((_) async => []);

        final result = await viewModel.addSelf(
          'parent1',
          'Me',
          30,
          'Advanced',
          '0123456789',
        );

        expect(result, true);
        expect(viewModel.isLoading, false);
        verify(() => playerService.createPlayer(
          any(
            that: isA<PlayerModel>().having(
              (p) => p.isSelf, 'isSelf', true,
            ),
          ),
        )).called(1);
      });

      test('returns false on failure', () async {
        when(() => playerService.createPlayer(any()))
            .thenThrow(Exception('Create failed'));

        final result = await viewModel.addSelf(
          'parent1',
          'Me',
          30,
          'Advanced',
          '0123456789',
        );

        expect(result, false);
        expect(viewModel.error, contains('Create failed'));
        expect(viewModel.isLoading, false);
      });
    });

    group('addChild', () {
      test('creates child with pending status', () async {
        final childPlayer = TestModelFactory.createPlayer(
          id: '',
          name: 'Child',
          age: 8,
          level: 'Beginner',
          phone: '0123456789',
          parentId: 'parent1',
        );

        when(() => playerService.createPlayer(any()))
            .thenAnswer((_) async => 'new-child-id');
        when(() => playerService.getPlayersByParentId('parent1'))
            .thenAnswer((_) async => []);

        final result = await viewModel.addChild(childPlayer);

        expect(result, true);
        expect(viewModel.isLoading, false);
        verify(() => playerService.createPlayer(
          any(
            that: isA<PlayerModel>().having(
              (p) => p.status, 'status', PlayerStatus.pending,
            ),
          ),
        )).called(1);
      });

      test('returns false on failure', () async {
        final childPlayer = TestModelFactory.createPlayer(
          id: '',
          name: 'Child',
          parentId: 'parent1',
        );

        when(() => playerService.createPlayer(any()))
            .thenThrow(Exception('Add child failed'));

        final result = await viewModel.addChild(childPlayer);

        expect(result, false);
        expect(viewModel.error, contains('Add child failed'));
        expect(viewModel.isLoading, false);
      });
    });

    group('updatePlayerImage', () {
      test('updates self player image', () async {
        final selfPlayer = TestModelFactory.createPlayer(
          id: 'self1',
          name: 'Me',
          isSelf: true,
          status: PlayerStatus.approved,
        );

        when(() => playerService.getPlayersByParentId('parent1'))
            .thenAnswer((_) async => [selfPlayer]);
        when(() => playerService.updatePlayer(any(), any()))
            .thenAnswer((_) async => {});

        await viewModel.loadMyKids('parent1');

        final result = await viewModel.updatePlayerImage(
          'self1',
          'http://img.new',
        );

        expect(result, true);
        expect(viewModel.selfPlayer!.imageUrl, 'http://img.new');
        verify(() => playerService.updatePlayer('self1', any())).called(1);
      });

      test('updates kid player image', () async {
        final kid = TestModelFactory.createPlayer(
          id: 'kid1',
          name: 'Kid',
          isSelf: false,
          status: PlayerStatus.approved,
        );

        when(() => playerService.getPlayersByParentId('parent1'))
            .thenAnswer((_) async => [kid]);
        when(() => playerService.updatePlayer(any(), any()))
            .thenAnswer((_) async => {});

        await viewModel.loadMyKids('parent1');

        final result = await viewModel.updatePlayerImage(
          'kid1',
          'http://img.kid',
        );

        expect(result, true);
        expect(viewModel.myKids.first.imageUrl, 'http://img.kid');
        verify(() => playerService.updatePlayer('kid1', any())).called(1);
      });

      test('returns false when player not found', () async {
        final result = await viewModel.updatePlayerImage(
          'nonexistent',
          'http://img',
        );

        expect(result, false);
      });

      test('sets error on failure', () async {
        final selfPlayer = TestModelFactory.createPlayer(
          id: 'self1',
          isSelf: true,
          status: PlayerStatus.approved,
        );

        when(() => playerService.getPlayersByParentId('parent1'))
            .thenAnswer((_) async => [selfPlayer]);
        when(() => playerService.updatePlayer(any(), any()))
            .thenThrow(Exception('Update failed'));

        await viewModel.loadMyKids('parent1');

        final result = await viewModel.updatePlayerImage(
          'self1',
          'http://img',
        );

        expect(result, false);
        expect(viewModel.error, contains('Update failed'));
      });
    });

    group('clearError', () {
      test('resets error', () async {
        when(() => playerService.getPlayersByParentId(any()))
            .thenThrow(Exception('An error'));

        await viewModel.loadMyKids('parent1');
        expect(viewModel.error, isNotNull);

        viewModel.clearError();
        expect(viewModel.error, isNull);
      });
    });
  });
}
