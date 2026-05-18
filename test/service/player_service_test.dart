import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/service/player_service.dart';
import 'package:jsba_app/app/model/player_model.dart';

void main() {
  group('PlayerService', () {
    late FakeFirebaseFirestore firestore;
    late PlayerService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = PlayerService(firestore: firestore);
    });

    test('createPlayer and getPlayersByParentId', () async {
      final player = PlayerModel(
        id: '',
        name: 'Alice',
        age: 10,
        level: 'Beginner',
        phone: '123',
        createdAt: DateTime.now(),
        isActive: true,
        parentId: 'parent1',
      );

      final id = await service.createPlayer(player);
      expect(id.isNotEmpty, true);

      final list = await service.getPlayersByParentId('parent1');
      expect(list.any((p) => p.name == 'Alice'), true);
    });

    test('getPlayerNames and getPlayerImages', () async {
      final docRef = await firestore.collection('players').add({
        'name': 'Bob',
        'imageUrl': 'http://img',
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      final names = await service.getPlayerNames([docRef.id]);
      expect(names[docRef.id], 'Bob');

      final imgs = await service.getPlayerImages([docRef.id]);
      expect(imgs[docRef.id], 'http://img');
    });
  });
}
