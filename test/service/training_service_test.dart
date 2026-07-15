import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
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
      );

      await service.addTraining(t1);
      final list = await service.getTrainingsForMonth(DateTime(2024, 6, 1));
      expect(list.any((t) => t.className == 'June Class'), true);
    });

    test('getTrainingsForPlayersInMonth returns trainings for multiple players in month', () async {
      final t1 = TrainingModel(
        id: '',
        className: 'Class A',
        playerIds: ['p1'],
        date: DateTime(2024, 6, 5),
        dayOfWeek: 'Wednesday',
        venue: 'Desa',
        startTime: '10:00',
        classType: 'group',
        level: 'Beginner',
        durationMinutes: 60,
      );
      final t2 = TrainingModel(
        id: '',
        className: 'Class B',
        playerIds: ['p2'],
        date: DateTime(2024, 6, 10),
        dayOfWeek: 'Monday',
        venue: 'Desa',
        startTime: '10:00',
        classType: 'group',
        level: 'Beginner',
        durationMinutes: 60,
      );
      final t3 = TrainingModel(
        id: '',
        className: 'Class C',
        playerIds: ['p1', 'p2'],
        date: DateTime(2024, 6, 15),
        dayOfWeek: 'Saturday',
        venue: 'Desa',
        startTime: '10:00',
        classType: 'group',
        level: 'Beginner',
        durationMinutes: 60,
      );
      final t4 = TrainingModel(
        id: '',
        className: 'July Class',
        playerIds: ['p1'],
        date: DateTime(2024, 7, 5),
        dayOfWeek: 'Friday',
        venue: 'Desa',
        startTime: '10:00',
        classType: 'group',
        level: 'Beginner',
        durationMinutes: 60,
      );

      await service.addTraining(t1);
      await service.addTraining(t2);
      await service.addTraining(t3);
      await service.addTraining(t4);

      final list = await service.getTrainingsForPlayersInMonth(['p1', 'p2'], 2024, 6);

      expect(list.length, 3);
      expect(list.map((t) => t.className), containsAll(['Class A', 'Class B', 'Class C']));
      expect(list.map((t) => t.className), isNot(contains('July Class')));

      final dates = list.map((t) => t.date).toList();
      expect(dates, equals([...dates]..sort((a, b) => a.compareTo(b))));
    });

    test('getTrainingsForPlayersInMonth returns empty for empty playerIds', () async {
      final list = await service.getTrainingsForPlayersInMonth([], 2024, 6);
      expect(list, isEmpty);
    });

    test('getTrainingsForPlayersInMonth deduplicates trainings across players', () async {
      final t1 = TrainingModel(
        id: '',
        className: 'Shared Class',
        playerIds: ['p1', 'p2'],
        date: DateTime(2024, 6, 5),
        dayOfWeek: 'Wednesday',
        venue: 'Desa',
        startTime: '10:00',
        classType: 'group',
        level: 'Beginner',
        durationMinutes: 60,
      );

      await service.addTraining(t1);

      final list = await service.getTrainingsForPlayersInMonth(['p1', 'p2'], 2024, 6);

      expect(list.length, 1);
      expect(list.first.className, 'Shared Class');
    });
  });
}
