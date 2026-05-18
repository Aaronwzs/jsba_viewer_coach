import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/service/academy_settings_service.dart';
import 'package:jsba_app/app/model/academy_settings_model.dart';

void main() {
  group('AcademySettingsService', () {
    late FakeFirebaseFirestore firestore;
    late AcademySettingsService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = AcademySettingsService(firestore: firestore);
    });

    test('getSettings returns defaults when doc does not exist', () async {
      final settings = await service.getSettings();

      expect(settings.billingName, 'Junior Shuttlers Academy');
      expect(settings.venues, containsAll(['Desa Petaling', 'Midfields', 'Sky Condo', 'Yoke Nam']));
      expect(settings.defaultMaxPlayersPerCourt, 6);
      expect(settings.votingDeadlineTime, '18:00');

      final doc =
          await firestore.collection('academySettings').doc('academy_settings').get();
      expect(doc.exists, true);
    });

    test('getSettings returns parsed model when doc exists', () async {
      final now = DateTime.now();
      await firestore.collection('academySettings').doc('academy_settings').set({
        'venues': ['Venue A', 'Venue B'],
        'defaultMaxPlayersPerCourt': 8,
        'votingDeadlineTime': '20:00',
        'billingName': 'Custom Academy',
        'billingWebsite': 'https://custom.example.com',
        'billingEmail': 'billing@custom.example.com',
        'dueDateNote': 'Due in 14 days',
        'socialMedia': <String, String>{},
        'lastUpdated': Timestamp.fromDate(now),
      });

      final settings = await service.getSettings();

      expect(settings.billingName, 'Custom Academy');
      expect(settings.defaultMaxPlayersPerCourt, 8);
      expect(settings.votingDeadlineTime, '20:00');
      expect(settings.venues, ['Venue A', 'Venue B']);
      expect(settings.billingWebsite, 'https://custom.example.com');
      expect(settings.dueDateNote, 'Due in 14 days');
    });

    test('createSettings writes to firestore', () async {
      final settings = AcademySettingsModel(
        billingName: 'Test Academy',
        venues: ['Venue X'],
        defaultMaxPlayersPerCourt: 4,
        votingDeadlineTime: '19:00',
        billingWebsite: 'https://test.example.com',
        dueDateNote: 'Net 30',
      );

      await service.createSettings(settings);

      final doc =
          await firestore.collection('academySettings').doc('academy_settings').get();
      expect(doc.exists, true);
      expect(doc.data()!['billingName'], 'Test Academy');
      expect(doc.data()!['venues'], ['Venue X']);
      expect(doc.data()!['defaultMaxPlayersPerCourt'], 4);
      expect(doc.data()!['votingDeadlineTime'], '19:00');
    });
  });
}
