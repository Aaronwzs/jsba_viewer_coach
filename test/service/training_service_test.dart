import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/service/training_service.dart';
import 'package:jsba_app/app/model/training_model.dart';

void main() {
  group('TrainingService', () {
    late FakeFirebaseFirestore firestore;
    late TrainingService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = TrainingService(firestore: firestore);
    });

    test('addTraining and getTrainingById', () async {
      final training = TrainingModel(
        id: '',
        className: 'Class A',
        playerIds: [],
        date: DateTime(2024, 6, 10),
        dayOfWeek: 'Monday',
        venue: 'Desa Petaling',
        startTime: '09:00',
        classType: 'group',
        level: 'Beginner',
        durationMinutes: 60,
        price: 10.0,
      );

      final id = await service.addTraining(training);
      expect(id.isNotEmpty, true);

      final fetched = await service.getTrainingById(id);
      expect(fetched, isNotNull);
      expect(fetched!.className, 'Class A');
    });

    test('getTrainingsForMonth returns items within month', () async {
      final t1 = TrainingModel(
        id: '',
        className: 'June Class',
        playerIds: [],
        date: DateTime(2024, 6, 5),
        dayOfWeek: 'Wednesday',
        venue: 'Desa',
        startTime: '10:00',
        classType: 'group',
        level: 'Beginner',
        durationMinutes: 60,
        price: 12.0,
      );

      await service.addTraining(t1);
      final list = await service.getTrainingsForMonth(DateTime(2024, 6, 1));
      expect(list.any((t) => t.className == 'June Class'), true);
    });
  });
}
