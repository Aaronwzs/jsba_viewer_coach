import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:jsba_app/app/service/auth_service.dart';

void main() {
  group('AuthService', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth auth;
    late AuthService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      auth = MockFirebaseAuth(mockUser: MockUser(uid: 'test-uid', email: 'test@test.com'), signedIn: true);
      service = AuthService(auth: auth, firestore: firestore);
    });

    test('signInWithEmailAndPassword returns UserCredential', () async {
      final cred = await service.signInWithEmailAndPassword(
        'test@test.com',
        'password123',
      );

      expect(cred.user, isNotNull);
      expect(cred.user!.email, 'test@test.com');
      expect(cred.user!.uid, 'test-uid');
    });

    test('signOut clears currentUser', () async {
      await service.signInWithEmailAndPassword('test@test.com', 'password123');
      expect(auth.currentUser, isNotNull);

      await service.signOut();
      expect(auth.currentUser, isNull);
    });

    test('getCurrentUserRole returns role from Firestore', () async {
      await service.signInWithEmailAndPassword('test@test.com', 'password123');
      final uid = auth.currentUser!.uid;

      await firestore.collection('users').doc(uid).set({'role': 'admin'});

      final role = await service.getCurrentUserRole();
      expect(role, 'admin');
    });

    test('getCurrentUserRole returns null when no user is signed in', () async {
      final role = await service.getCurrentUserRole();
      expect(role, isNull);
    });

    test('createUserWithEmailAndPassword returns UserCredential', () async {
      final cred = await service.createUserWithEmailAndPassword(
        'new@test.com',
        'password123',
      );

      expect(cred.user, isNotNull);
    });
  });
}
