import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/model/user_payment_model.dart';
import 'package:jsba_app/app/utils/starter_handler.dart' as starter_handler;

class UserPaymentService {
  final FirebaseFirestore _db;

  UserPaymentService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _collection => _db.collection('userPayments');

  String _monthKey(int year, int month) {
    final y = year.toString().padLeft(4, '0');
    final m = month.toString().padLeft(2, '0');
    return '$y-$m';
  }

  Future<List<UserPaymentModel>> getUserPaymentsForPlayerIds(
    List<String> playerIds,
  ) async {
    if (playerIds.isEmpty) return [];

    final seen = <String>{};
    final payments = <UserPaymentModel>[];
    final chunks = _chunkList(playerIds, 30);

    for (final chunk in chunks) {
      // Query by single playerId field
      try {
        final byPlayerId = await _collection
            .where('playerId', whereIn: chunk)
            .get();

        for (final doc in byPlayerId.docs) {
          if (seen.add(doc.id)) {
            payments.add(UserPaymentModel.fromMap(
              doc.data() as Map<String, dynamic>,
              id: doc.id,
            ));
          }
        }
      } catch (_) {}

      // Query by playerIds array (family billing — only if field exists)
      try {
        final byPlayerIds = await _collection
            .where('playerIds', arrayContainsAny: chunk)
            .get();

        for (final doc in byPlayerIds.docs) {
          if (seen.add(doc.id)) {
            payments.add(UserPaymentModel.fromMap(
              doc.data() as Map<String, dynamic>,
              id: doc.id,
            ));
          }
        }
      } catch (_) {}
    }

    payments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return payments;
  }

  List<List<String>> _chunkList(List<String> list, int chunkSize) {
    final chunks = <List<String>>[];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(i, i + chunkSize > list.length ? list.length : i + chunkSize));
    }
    return chunks;
  }

  Future<List<UserPaymentModel>> getUserPaymentsForPeriod(
    List<String> playerIds,
    int year,
    int month,
  ) async {
    final key = _monthKey(year, month);
    final allPayments = await getUserPaymentsForPlayerIds(playerIds);
    // Filter strictly by the billing period key.
    return allPayments
        .where((p) => p.billingPeriodKey == key)
        .toList();
  }

  Future<UserPaymentModel?> getUserPaymentById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return UserPaymentModel.fromMap(
      doc.data() as Map<String, dynamic>,
      id: doc.id,
    );
  }

  Future<String> createUserPayment(UserPaymentModel payment) async {
    final docRef = await _collection.add(payment.toJson());
    return docRef.id;
  }

  Future<void> submitPayment({
    required UserPaymentModel payment,
    required String userId,
  }) async {
    final docRef = await _collection.add(payment.toJson());

    starter_handler.notificationService.sendNotificationToUserIds(
      userIds: [userId],
      type: 'userPayment',
      title: 'Payment Submitted',
      body:
          'Payment of ${payment.currency} ${payment.amount.toStringAsFixed(2)} for ${payment.playerName} has been submitted for confirmation.',
      referenceId: docRef.id,
      referenceCollection: 'userPayments',
    );
  }

  Future<void> cancelPayment(String id) async {
    await _collection.doc(id).delete();
  }

  /// Sets the payment proof on a user payment by populating the [uploadProof]
  /// field and moving the payment into the `pending` (awaiting approval) state.
  /// Used by the parent billing flow (distinct from the coach payout proof).
  Future<void> uploadUserPaymentProof({
    required String id,
    required String url,
  }) async {
    await _collection.doc(id).update({
      'uploadProof': url,
      'paymentStatus': 'pending',
    });
  }

  Future<void> markPaymentApproved({
    required String id,
    required String approvedBy,
  }) async {
    await _collection.doc(id).update({
      'paymentStatus': 'approved',
      'approvedAt': Timestamp.fromDate(DateTime.now()),
      'approvedBy': approvedBy,
    });

    final doc = await _collection.doc(id).get();
    final data = doc.data() as Map<String, dynamic>?;
    if (data != null) {
      final parentId = data['parentId'] as String? ?? '';
      if (parentId.isNotEmpty) {
        starter_handler.notificationService.sendNotificationToUserIds(
          userIds: [parentId],
          type: 'userPayment',
          title: 'Payment Approved',
          body:
              'Your payment of ${data['currency'] ?? 'RM'} ${(data['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'} has been approved.',
          referenceId: id,
          referenceCollection: 'userPayments',
        );
      }
    }
  }

  Future<void> markPaymentRejected({
    required String id,
    required String approvedBy,
    String? reason,
  }) async {
    await _collection.doc(id).update({
      'paymentStatus': 'rejected',
      'approvedAt': Timestamp.fromDate(DateTime.now()),
      'approvedBy': approvedBy,
      'notes': reason,
    });

    final doc = await _collection.doc(id).get();
    final data = doc.data() as Map<String, dynamic>?;
    if (data != null) {
      final parentId = data['parentId'] as String? ?? '';
      if (parentId.isNotEmpty) {
        starter_handler.notificationService.sendNotificationToUserIds(
          userIds: [parentId],
          type: 'userPayment',
          title: 'Payment Rejected',
          body:
              'Your payment of ${data['currency'] ?? 'RM'} ${(data['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'} was rejected${reason != null ? ': $reason' : ''}.',
          referenceId: id,
          referenceCollection: 'userPayments',
        );
      }
    }
  }
}
