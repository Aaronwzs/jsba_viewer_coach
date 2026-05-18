import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/service/coach_payout_service.dart';
import 'package:jsba_app/app/model/coach_payout_model.dart';

void main() {
  group('CoachPayoutService', () {
    late FakeFirebaseFirestore firestore;
    late CoachPayoutService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = CoachPayoutService(firestore: firestore);
    });

    test('getPayoutsForCoachMonth returns payouts for coach in given month', () async {
      final now = DateTime.now();
      await firestore.collection('coachPayouts').add({
        'coachId': 'coach1',
        'coachRatesId': 'rate1',
        'periodKey': '2024-06',
        'trainingIds': <String>[],
        'createdAt': Timestamp.fromDate(now),
        'generatedAt': Timestamp.fromDate(now),
      });

      final payouts = await service.getPayoutsForCoachMonth('coach1', 2024, 6);
      expect(payouts.length, 1);
      expect(payouts.first.coachId, 'coach1');
      expect(payouts.first.periodKey, '2024-06');
    });

    test('getPayoutsForCoachMonth returns empty list when no matches', () async {
      final payouts = await service.getPayoutsForCoachMonth('coach1', 2024, 6);
      expect(payouts, isEmpty);
    });

    test('getPayoutsForCoachMonth filters by coachId', () async {
      final now = DateTime.now();
      await firestore.collection('coachPayouts').add({
        'coachId': 'coach1',
        'coachRatesId': 'rate1',
        'periodKey': '2024-06',
        'trainingIds': <String>[],
        'createdAt': Timestamp.fromDate(now),
        'generatedAt': Timestamp.fromDate(now),
      });
      await firestore.collection('coachPayouts').add({
        'coachId': 'coach2',
        'coachRatesId': 'rate2',
        'periodKey': '2024-06',
        'trainingIds': <String>[],
        'createdAt': Timestamp.fromDate(now),
        'generatedAt': Timestamp.fromDate(now),
      });

      final coach1Payouts = await service.getPayoutsForCoachMonth('coach1', 2024, 6);
      expect(coach1Payouts.length, 1);
      expect(coach1Payouts.first.coachId, 'coach1');

      final coach2Payouts = await service.getPayoutsForCoachMonth('coach2', 2024, 6);
      expect(coach2Payouts.length, 1);
      expect(coach2Payouts.first.coachId, 'coach2');
    });

    test('getPayoutsForCoachMonth filters by periodKey', () async {
      final now = DateTime.now();
      await firestore.collection('coachPayouts').add({
        'coachId': 'coach1',
        'coachRatesId': 'rate1',
        'periodKey': '2024-06',
        'trainingIds': <String>[],
        'createdAt': Timestamp.fromDate(now),
        'generatedAt': Timestamp.fromDate(now),
      });
      await firestore.collection('coachPayouts').add({
        'coachId': 'coach1',
        'coachRatesId': 'rate1',
        'periodKey': '2024-07',
        'trainingIds': <String>[],
        'createdAt': Timestamp.fromDate(now),
        'generatedAt': Timestamp.fromDate(now),
      });

      final junePayouts = await service.getPayoutsForCoachMonth('coach1', 2024, 6);
      expect(junePayouts.length, 1);
      expect(junePayouts.first.periodKey, '2024-06');
    });

    test('getPayoutById returns payout when exists', () async {
      final now = DateTime.now();
      final docRef = await firestore.collection('coachPayouts').add({
        'coachId': 'coach1',
        'coachRatesId': 'rate1',
        'periodKey': '2024-06',
        'trainingIds': <String>[],
        'createdAt': Timestamp.fromDate(now),
        'generatedAt': Timestamp.fromDate(now),
      });

      final payout = await service.getPayoutById(docRef.id);
      expect(payout, isNotNull);
      expect(payout!.coachId, 'coach1');
      expect(payout.id, docRef.id);
    });

    test('getPayoutById returns null for missing payout', () async {
      final payout = await service.getPayoutById('nonexistent');
      expect(payout, isNull);
    });
  });
}
