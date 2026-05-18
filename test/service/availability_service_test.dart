import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/service/availability_service.dart';
import 'package:jsba_app/app/model/availability_model.dart';
import '../helpers/model_factories.dart';

void main() {
  group('AvailabilityService', () {
    late FakeFirebaseFirestore firestore;
    late AvailabilityService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = AvailabilityService(firestore: firestore);
    });

    group('getActiveSlots', () {
      test('only returns active slots', () async {
        await firestore.collection('kidAvailability').add(
          TestModelFactory.createAvailabilitySlot(id: 'active1', isActive: true).toJson(),
        );
        await firestore.collection('kidAvailability').add(
          TestModelFactory.createAvailabilitySlot(id: 'inactive1', isActive: false).toJson(),
        );

        final slots = await service.getActiveSlots();
        expect(slots.length, 1);
        expect(slots.every((s) => s.isActive), true);
      });

      test('returns empty list when no active slots', () async {
        await firestore.collection('kidAvailability').add(
          TestModelFactory.createAvailabilitySlot(isActive: false).toJson(),
        );

        final slots = await service.getActiveSlots();
        expect(slots, isEmpty);
      });

      test('returns all active slots when multiple exist', () async {
        await firestore.collection('kidAvailability').add(
          TestModelFactory.createAvailabilitySlot(id: 'slot1', isActive: true).toJson(),
        );
        await firestore.collection('kidAvailability').add(
          TestModelFactory.createAvailabilitySlot(id: 'slot2', isActive: true).toJson(),
        );

        final slots = await service.getActiveSlots();
        expect(slots.length, 2);
      });
    });

    group('respond', () {
      test('updates nested field responses.player1', () async {
        final docRef = await firestore.collection('kidAvailability').add(
          TestModelFactory.createAvailabilitySlot(responses: {}).toJson(),
        );

        await service.respond(docRef.id, 'player1', true);
        final doc = await docRef.get();
        expect(doc.data()!['responses']['player1'], true);
      });

      test('overwrites existing response', () async {
        final docRef = await firestore.collection('kidAvailability').add(
          TestModelFactory.createAvailabilitySlot(responses: {'player1': false}).toJson(),
        );

        await service.respond(docRef.id, 'player1', true);
        final doc = await docRef.get();
        expect(doc.data()!['responses']['player1'], true);
      });
    });

    group('removeResponse', () {
      test('removes response entry from nested map', () async {
        final docRef = await firestore.collection('kidAvailability').add(
          TestModelFactory.createAvailabilitySlot(responses: {'player1': true}).toJson(),
        );

        await service.removeResponse(docRef.id, 'player1');
        final doc = await docRef.get();
        final responses = doc.data()!['responses'] as Map<String, dynamic>;
        expect(responses.containsKey('player1'), false);
      });
    });

    group('toggleSlotActive', () {
      test('updates isActive to false', () async {
        final docRef = await firestore.collection('kidAvailability').add(
          TestModelFactory.createAvailabilitySlot(isActive: true).toJson(),
        );

        await service.toggleSlotActive(docRef.id, false);
        final doc = await docRef.get();
        expect(doc.data()!['isActive'], false);
      });

      test('updates isActive to true', () async {
        final docRef = await firestore.collection('kidAvailability').add(
          TestModelFactory.createAvailabilitySlot(isActive: false).toJson(),
        );

        await service.toggleSlotActive(docRef.id, true);
        final doc = await docRef.get();
        expect(doc.data()!['isActive'], true);
      });
    });
  });
}
