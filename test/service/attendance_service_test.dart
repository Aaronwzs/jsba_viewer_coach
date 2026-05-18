import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/service/attendance_service.dart';
import 'package:jsba_app/app/model/attendance_model.dart';

void main() {
  group('AttendanceService', () {
    late FakeFirebaseFirestore firestore;
    late AttendanceService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = AttendanceService(firestore: firestore);
    });

    test('createAttendanceBatch creates attendance docs', () async {
      await service.createAttendanceBatch('t1', ['p1', 'p2'], 10.0);

      final snapshot = await firestore.collection('attendances').get();
      expect(snapshot.docs.length, 2);
    });

    test('getAttendanceForTraining returns created records', () async {
      await service.createAttendanceBatch('t2', ['p3'], 5.0);
      final list = await service.getAttendanceForTraining('t2');
      expect(list.length, 1);
      final a = list.first;
      expect(a.trainingId, 't2');
      expect(a.amountCharge, 5.0);
    });

    test('batchUpdateAttendance updates records', () async {
      await service.createAttendanceBatch('t3', ['p4'], 7.5);
      final list = await service.getAttendanceForTraining('t3');
      final updated = list.map((a) => AttendanceModel(
        id: a.id,
        trainingId: a.trainingId,
        playerId: a.playerId,
        coachId: a.coachId,
        attendanceStatus: 'present',
        amountCharge: a.amountCharge,
        reasonCharge: a.reasonCharge,
        coachComments: 'ok',
        createdAt: a.createdAt,
      )).toList();

      await service.batchUpdateAttendance(updated);
      final after = await service.getAttendanceForTraining('t3');
      expect(after.first.attendanceStatus, 'present');
      expect(after.first.coachComments, 'ok');
    });
  });
}
