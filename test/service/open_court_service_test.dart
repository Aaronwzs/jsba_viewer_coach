import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/service/open_court_service.dart';
import 'package:jsba_app/app/model/open_court_model.dart';
import '../helpers/model_factories.dart';

void main() {
  group('OpenCourtService', () {
    late FakeFirebaseFirestore firestore;
    late OpenCourtService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = OpenCourtService(firestore: firestore);
    });

    group('CRUD', () {
      test('createSession and getAllSessions', () async {
        final session = TestModelFactory.createOpenCourtSession();
        final id = await service.createSession(session);
        expect(id.isNotEmpty, true);

        final all = await service.getAllSessions();
        expect(all.length, 1);
        expect(all.first.id, id);
      });

      test('getSession returns null when not found', () async {
        final session = await service.getSession('nonexistent');
        expect(session, isNull);
      });

      test('getSession returns session when found', () async {
        final session = TestModelFactory.createOpenCourtSession(venue: 'Test Venue');
        final id = await service.createSession(session);

        final fetched = await service.getSession(id);
        expect(fetched, isNotNull);
        expect(fetched!.venue, 'Test Venue');
      });

      test('updateSession updates fields', () async {
        final session = TestModelFactory.createOpenCourtSession(venue: 'Original');
        final id = await service.createSession(session);

        final updated = session.copyWith(venue: 'Updated Venue');
        await service.updateSession(id, updated);

        final fetched = await service.getSession(id);
        expect(fetched!.venue, 'Updated Venue');
      });

      test('deleteSession removes session', () async {
        final session = TestModelFactory.createOpenCourtSession();
        final id = await service.createSession(session);

        await service.deleteSession(id);
        final fetched = await service.getSession(id);
        expect(fetched, isNull);
      });
    });

    group('queries', () {
      test('getSessionsByStatus returns filtered sessions', () async {
        await service.createSession(
          TestModelFactory.createOpenCourtSession(status: OpenCourtModel.statusDraft),
        );
        await service.createSession(
          TestModelFactory.createOpenCourtSession(
            id: 'oc2',
            status: OpenCourtModel.statusOpenForBooking,
          ),
        );
        await service.createSession(
          TestModelFactory.createOpenCourtSession(
            id: 'oc3',
            status: OpenCourtModel.statusBooked,
          ),
        );

        final booked = await service.getSessionsByStatus(OpenCourtModel.statusBooked);
        expect(booked.length, 1);
        expect(booked.first.status, OpenCourtModel.statusBooked);
      });

      test('getUpcomingSessions filters past sessions', () async {
        final futureDate = DateTime.now().add(const Duration(days: 10));
        final pastDate = DateTime.now().subtract(const Duration(days: 10));

        final futureId = await service.createSession(
          TestModelFactory.createOpenCourtSession(date: futureDate),
        );
        await service.createSession(
          TestModelFactory.createOpenCourtSession(
            id: 'past',
            date: pastDate,
          ),
        );

        final upcoming = await service.getUpcomingSessions();
        expect(upcoming.any((s) => s.id == futureId), true);
        expect(upcoming.every((s) => s.date.isAfter(DateTime.now().subtract(const Duration(days: 1)))), true);
      });
    });

    group('status transitions', () {
      test('updateStatus changes status', () async {
        final id = await service.createSession(
          TestModelFactory.createOpenCourtSession(status: OpenCourtModel.statusDraft),
        );

        await service.updateStatus(id, OpenCourtModel.statusOpenForBooking);
        final session = await service.getSession(id);
        expect(session!.status, OpenCourtModel.statusOpenForBooking);
      });

      test('reserveCourt sets status to reserved', () async {
        final id = await service.createSession(
          TestModelFactory.createOpenCourtSession(status: OpenCourtModel.statusOpenForBooking),
        );

        await service.reserveCourt(sessionId: id, parentName: 'Parent', userId: 'user1');
        final session = await service.getSession(id);
        expect(session!.status, OpenCourtModel.statusReservedForBooking);
        expect(session.reservedByUserId, 'user1');
        expect(session.reservedByParentName, 'Parent');
      });

      test('cancelReservation reverts to open', () async {
        final id = await service.createSession(
          TestModelFactory.createOpenCourtSession(status: OpenCourtModel.statusReservedForBooking),
        );
        await service.reserveCourt(sessionId: id, parentName: 'Parent', userId: 'user1');

        await service.cancelReservation(id);
        final session = await service.getSession(id);
        expect(session!.status, OpenCourtModel.statusOpenForBooking);
        expect(session.reservedByUserId, isNull);
        expect(session.reservedByParentName, isNull);
      });

      test('bookCourt sets status to booked', () async {
        final id = await service.createSession(
          TestModelFactory.createOpenCourtSession(status: OpenCourtModel.statusOpenForBooking),
        );

        await service.bookCourt(sessionId: id, parentName: 'Parent', userId: 'user1');
        final session = await service.getSession(id);
        expect(session!.status, OpenCourtModel.statusBooked);
        expect(session.bookedByUserId, 'user1');
        expect(session.bookedByParentName, 'Parent');
      });

      test('confirmBooking transitions reserved to booked', () async {
        final id = await service.createSession(
          TestModelFactory.createOpenCourtSession(status: OpenCourtModel.statusReservedForBooking),
        );
        await service.reserveCourt(sessionId: id, parentName: 'Parent', userId: 'user1');

        await service.confirmBooking(sessionId: id, parentName: 'Parent', userId: 'user1');
        final session = await service.getSession(id);
        expect(session!.status, OpenCourtModel.statusBooked);
        expect(session.bookedByUserId, 'user1');
        expect(session.reservedByUserId, isNull);
      });

      test('undoBooking reverts to open and clears booking fields', () async {
        final id = await service.createSession(
          TestModelFactory.createOpenCourtSession(status: OpenCourtModel.statusBooked),
        );
        await service.bookCourt(sessionId: id, parentName: 'Parent', userId: 'user1');

        await service.undoBooking(id);
        final session = await service.getSession(id);
        expect(session!.status, OpenCourtModel.statusOpenForBooking);
        expect(session.bookedByUserId, isNull);
        expect(session.bookedByParentName, isNull);
      });
    });

    group('player management', () {
      test('registerPlayer adds player to session', () async {
        final id = await service.createSession(
          TestModelFactory.createOpenCourtSession(playerIds: []),
        );

        await service.registerPlayer(sessionId: id, playerId: 'player1');
        final session = await service.getSession(id);
        expect(session!.playerIds, contains('player1'));
      });

      test('registerPlayer auto-closes session when full', () async {
        final id = await service.createSession(
          TestModelFactory.createOpenCourtSession(maxPlayers: 1, playerIds: []),
        );

        await service.registerPlayer(sessionId: id, playerId: 'player1');
        final session = await service.getSession(id);
        expect(session!.status, OpenCourtModel.statusClosed);
      });

      test('registerPlayer throws when player already registered', () async {
        final id = await service.createSession(
          TestModelFactory.createOpenCourtSession(playerIds: ['player1']),
        );

        expect(
          () => service.registerPlayer(sessionId: id, playerId: 'player1'),
          throwsException,
        );
      });

      test('registerPlayer throws when session not found', () async {
        expect(
          () => service.registerPlayer(sessionId: 'nonexistent', playerId: 'player1'),
          throwsException,
        );
      });

      test('removePlayer removes player from session', () async {
        final id = await service.createSession(
          TestModelFactory.createOpenCourtSession(playerIds: ['player1', 'player2']),
        );

        await service.removePlayer(id, 'player1');
        final session = await service.getSession(id);
        expect(session!.playerIds, contains('player2'));
        expect(session.playerIds, isNot(contains('player1')));
      });

      test('removePlayer removes last player from session', () async {
        final id = await service.createSession(
          TestModelFactory.createOpenCourtSession(playerIds: ['player1']),
        );

        await service.removePlayer(id, 'player1');
        final session = await service.getSession(id);
        expect(session!.playerIds, isEmpty);
      });
    });
  });
}
