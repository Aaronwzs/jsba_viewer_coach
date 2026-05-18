import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/service/announcement_service.dart';

void main() {
  group('AnnouncementService', () {
    late FakeFirebaseFirestore firestore;
    late AnnouncementService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = AnnouncementService(firestore: firestore);
    });

    test('getAnnouncements returns pinned first and includes docs', () async {
      final now = DateTime.now();
      await firestore.collection('announcements').add({
        'title': 'Pinned',
        'content': 'Pinned content',
        'createdAt': Timestamp.fromDate(now.subtract(Duration(hours: 1))),
        'createdBy': 'u1',
        'isPinned': true,
      });

      await firestore.collection('announcements').add({
        'title': 'Normal',
        'content': 'Normal content',
        'createdAt': Timestamp.fromDate(now),
        'createdBy': 'u2',
        'isPinned': false,
        'expiresAt': Timestamp.fromDate(now.add(Duration(days: 1))),
      });

      final list = await service.getAnnouncements();
      expect(list.length, 2);
      expect(list.first.isPinned, true);
    });

    test('getActiveAnnouncements excludes expired', () async {
      final now = DateTime.now();
      await firestore.collection('announcements').add({
        'title': 'Expired',
        'content': 'Expired',
        'createdAt': Timestamp.fromDate(now.subtract(Duration(days: 2))),
        'createdBy': 'u3',
        'isPinned': false,
        'expiresAt': Timestamp.fromDate(now.subtract(Duration(days: 1))),
      });

      await firestore.collection('announcements').add({
        'title': 'Active',
        'content': 'Active',
        'createdAt': Timestamp.fromDate(now),
        'createdBy': 'u4',
        'isPinned': false,
      });

      final active = await service.getActiveAnnouncements();
      expect(active.any((a) => a.title == 'Expired'), false);
      expect(active.any((a) => a.title == 'Active'), true);
    });
  });
}
