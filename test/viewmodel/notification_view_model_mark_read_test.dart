import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/model/notification_item_model.dart';
import 'package:jsba_app/app/viewmodel/notification_view_model.dart';

/// Tests for [NotificationViewModel.markAsReadByReference] — the
/// "tap a push notification" path. The push data payload only contains the
/// entity reference (referenceCollection + referenceId), not the Firestore
/// document ID, so we need to find the matching notification by reference.
void main() {
  group('NotificationViewModel.markAsReadByReference', () {
    late FakeFirebaseFirestore firestore;
    late NotificationViewModel vm;
    const userId = 'user1';
    final now = DateTime(2024, 6, 15, 10, 0, 0);

    Future<void> seed() async {
      // Two notifications about the same invoice (e.g. invoice updated twice)
      final userRef = firestore.collection('users').doc(userId);
      await userRef.collection('notifications').add({
        'type': 'invoice',
        'title': 'Invoice updated',
        'body': 'See new total',
        'referenceId': 'invoice-abc',
        'referenceCollection': 'invoices',
        'isRead': false,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 1))),
      });
      await userRef.collection('notifications').add({
        'type': 'invoice',
        'title': 'Invoice updated (again)',
        'body': 'Total changed',
        'referenceId': 'invoice-abc',
        'referenceCollection': 'invoices',
        'isRead': false,
        'createdAt': Timestamp.fromDate(now),
      });
      // A different invoice — should NOT be affected.
      await userRef.collection('notifications').add({
        'type': 'invoice',
        'title': 'Other invoice',
        'body': 'Unrelated',
        'referenceId': 'invoice-xyz',
        'referenceCollection': 'invoices',
        'isRead': false,
        'createdAt': Timestamp.fromDate(now),
      });
    }

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      await seed();
      vm = NotificationViewModel(db: firestore);
      vm.startListening(userId);
      // Wait for the initial stream emission to populate _notifications.
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    tearDown(() {
      vm.dispose();
    });

    test('marks every unread notification matching the reference as read',
        () async {
      expect(vm.notifications.length, 3);
      expect(
        vm.notifications.where((n) => !n.isRead).length,
        3,
        reason: 'All three seeded notifications should start unread',
      );

      await vm.markAsReadByReference(
        referenceCollection: 'invoices',
        referenceId: 'invoice-abc',
      );

      // Both matching notifications are now read locally
      final matching = vm.notifications
          .where((n) => n.referenceId == 'invoice-abc')
          .toList();
      expect(matching, hasLength(2));
      expect(matching.every((n) => n.isRead), isTrue,
          reason: 'Both notifications about invoice-abc should be marked read');

      // The unrelated notification is still unread
      final other = vm.notifications
          .where((n) => n.referenceId == 'invoice-xyz')
          .toList();
      expect(other, hasLength(1));
      expect(other.first.isRead, isFalse);

      // And in Firestore, all three docs should reflect the new state
      final persisted = await firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();
      final byRef = <String, bool>{};
      for (final doc in persisted.docs) {
        final data = doc.data();
        byRef[data['referenceId'] as String] = data['isRead'] as bool;
      }
      expect(byRef['invoice-abc'], isTrue,
          reason: 'Both invoice-abc docs in Firestore should be isRead=true');
      expect(byRef['invoice-xyz'], isFalse,
          reason: 'invoice-xyz should be untouched');
    });

    test('is a no-op when userId is null', () async {
      final fresh = NotificationViewModel(db: firestore);
      // Don't call startListening — _userId stays null
      await fresh.markAsReadByReference(
        referenceCollection: 'invoices',
        referenceId: 'invoice-abc',
      );
      // No exception, no state change. Just verify the seeded data is intact.
      final persisted = await firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();
      expect(persisted.docs.every((d) => d.data()['isRead'] == false), isTrue);
      fresh.dispose();
    });

    test('is a no-op when referenceCollection is null/empty', () async {
      await vm.markAsReadByReference(referenceCollection: '', referenceId: 'x');
      await vm.markAsReadByReference(referenceCollection: null, referenceId: 'x');
      final persisted = await firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();
      expect(persisted.docs.every((d) => d.data()['isRead'] == false), isTrue);
    });

    test('is a no-op when referenceId is null/empty', () async {
      await vm.markAsReadByReference(referenceCollection: 'invoices', referenceId: '');
      await vm.markAsReadByReference(referenceCollection: 'invoices', referenceId: null);
      final persisted = await firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();
      expect(persisted.docs.every((d) => d.data()['isRead'] == false), isTrue);
    });
  });

  group('NotificationItemModel equality helpers', () {
    // Sanity check that the model exposes the fields the ViewModel relies on.
    test('round-trips referenceId and referenceCollection', () {
      final model = NotificationItemModel(
        id: 'n1',
        type: 'invoice',
        title: 't',
        body: 'b',
        referenceId: 'invoice-abc',
        referenceCollection: 'invoices',
        createdAt: DateTime(2024, 1, 1),
      );
      expect(model.referenceId, 'invoice-abc');
      expect(model.referenceCollection, 'invoices');
      expect(model.isRead, isFalse);

      final read = model.copyWith(isRead: true);
      expect(read.isRead, isTrue);
      expect(read.referenceId, 'invoice-abc',
          reason: 'copyWith must not drop unrelated fields');
    });
  });
}
