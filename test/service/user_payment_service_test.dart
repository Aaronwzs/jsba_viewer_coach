import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:jsba_app/app/service/user_payment_service.dart';
import 'package:jsba_app/app/model/user_payment_model.dart';

void main() {
  group('UserPaymentService - full flow', () {
    late FakeFirebaseFirestore firestore;
    late UserPaymentService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = UserPaymentService(firestore: firestore);
    });

    test('retrieves payments for a player by playerId', () async {
      // Simulate an existing userPayment doc with current month
      final now = DateTime.now();
      final key =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';

      await firestore.collection('userPayments').add({
        'playerId': 'p1',
        'playerName': 'Alice',
        'parentId': 'parent1',
        'amount': 100.0,
        'currency': 'RM',
        'paymentMethod': 'bank',
        'paymentStatus': 'pending',
        'receiptUrls': [],
        'billingPeriodKey': key,
        'createdAt': now,
        'playerIds': [],
      });

      final payments = await service.getUserPaymentsForPlayerIds(['p1']);
      expect(payments.length, 1);
      expect(payments.first.playerName, 'Alice');
    });

    test('getUserPaymentsForPeriod filters by month', () async {
      final now = DateTime.now();
      final currentKey =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
      final lastMonth = DateTime(now.year, now.month - 1);
      final lastKey =
          '${lastMonth.year.toString().padLeft(4, '0')}-${lastMonth.month.toString().padLeft(2, '0')}';

      await firestore.collection('userPayments').add({
        'playerId': 'p1',
        'playerName': 'Alice',
        'parentId': 'parent1',
        'amount': 100.0,
        'currency': 'RM',
        'paymentMethod': 'bank',
        'paymentStatus': 'pending',
        'receiptUrls': [],
        'billingPeriodKey': currentKey,
        'createdAt': now,
        'playerIds': [],
      });

      await firestore.collection('userPayments').add({
        'playerId': 'p1',
        'playerName': 'Alice',
        'parentId': 'parent1',
        'amount': 50.0,
        'currency': 'RM',
        'paymentMethod': 'bank',
        'paymentStatus': 'pending',
        'receiptUrls': [],
        'billingPeriodKey': lastKey,
        'createdAt': lastMonth,
        'playerIds': [],
      });

      final current = await service.getUserPaymentsForPeriod(['p1'], now.year, now.month);
      expect(current.length, 1);
      expect(current.first.amount, 100.0);

      final last = await service.getUserPaymentsForPeriod(['p1'], lastMonth.year, lastMonth.month);
      expect(last.length, 1);
      expect(last.first.amount, 50.0);
    });

    test('returns empty when no payments exist', () async {
      final payments = await service.getUserPaymentsForPlayerIds(['nonexistent']);
      expect(payments, isEmpty);
    });

    test('getUserPaymentsForPeriod returns records for July 2026 (2026-07)',
        () async {
      await firestore.collection('userPayments').add({
        'playerId': 'p1',
        'playerName': 'Alice',
        'parentId': 'parent1',
        'amount': 100.0,
        'currency': 'RM',
        'paymentMethod': 'bank',
        'paymentStatus': 'pending',
        'billingPeriodKey': '2026-07',
        'createdAt': DateTime(2026, 7, 15),
        'playerIds': [],
      });
      await firestore.collection('userPayments').add({
        'playerId': 'p1',
        'playerName': 'Alice',
        'parentId': 'parent1',
        'amount': 50.0,
        'currency': 'RM',
        'paymentMethod': 'bank',
        'paymentStatus': 'pending',
        'billingPeriodKey': '2026-06',
        'createdAt': DateTime(2026, 6, 15),
        'playerIds': [],
      });

      final july =
          await service.getUserPaymentsForPeriod(['p1'], 2026, 7);
      expect(july.length, 1);
      expect(july.first.billingPeriodKey, '2026-07');

      final june =
          await service.getUserPaymentsForPeriod(['p1'], 2026, 6);
      expect(june.length, 1);
      expect(june.first.billingPeriodKey, '2026-06');
    });

    test('reads period key from alternate "periodKey" field name', () async {
      await firestore.collection('userPayments').add({
        'playerId': 'p1',
        'playerName': 'Alice',
        'parentId': 'parent1',
        'amount': 100.0,
        'currency': 'RM',
        'paymentMethod': 'bank',
        'paymentStatus': 'pending',
        'periodKey': '2026-07', // backend stores it under `periodKey`
        'createdAt': DateTime(2026, 7, 15),
        'playerIds': [],
      });

      final july =
          await service.getUserPaymentsForPeriod(['p1'], 2026, 7);
      expect(july.length, 1);
      expect(july.first.billingPeriodKey, '2026-07');
    });
  });
}
