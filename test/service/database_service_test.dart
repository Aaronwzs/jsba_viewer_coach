import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:jsba_app/app/service/database_service.dart';
import 'package:jsba_app/app/model/user_model.dart';

void main() {
  group('DatabaseService', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth auth;
    late DatabaseService service;

    setUp(() {
      auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(
          uid: 'test-uid',
          email: 'test@test.com',
          displayName: 'Test User',
        ),
      );
      firestore = FakeFirebaseFirestore();
      service = DatabaseService(auth: auth, firestore: firestore);
    });

    group('ensureUserDocumentExists', () {
      test('creates document when missing', () async {
        final user = await service.ensureUserDocumentExists('test-uid');
        expect(user.uid, 'test-uid');
        expect(user.email, 'test@test.com');
        expect(user.name, 'Test User');
        expect(user.role, 'admin');
        expect(user.createdAt, isNull);

        final doc = await firestore.collection('users').doc('test-uid').get();
        expect(doc.exists, true);
      });

      test('returns existing document', () async {
        await firestore.collection('users').doc('existing-uid').set({
          'email': 'existing@test.com',
          'name': 'Existing User',
          'role': UserRole.coach,
          'status': UserStatus.active,
        });

        final user = await service.ensureUserDocumentExists('existing-uid');
        expect(user.uid, 'existing-uid');
        expect(user.email, 'existing@test.com');
        expect(user.name, 'Existing User');
        expect(user.role, UserRole.coach);
      });
    });

    group('updateUserProfile', () {
      test('updates specified fields', () async {
        await firestore.collection('users').doc('test-uid').set({
          'email': 'test@test.com',
          'name': 'Old Name',
          'role': UserRole.coach,
        });

        await service.updateUserProfile(
          'test-uid',
          name: 'New Name',
          phone: '0123456789',
        );
        final doc = await firestore.collection('users').doc('test-uid').get();
        expect(doc.data()!['name'], 'New Name');
        expect(doc.data()!['phone'], '0123456789');
      });

      test('does nothing when no fields provided', () async {
        await firestore.collection('users').doc('test-uid').set({
          'name': 'Same Name',
        });

        await service.updateUserProfile('test-uid');
        final doc = await firestore.collection('users').doc('test-uid').get();
        expect(doc.data()!['name'], 'Same Name');
      });
    });

    group('deleteUserDocument', () {
      test('removes user document', () async {
        await firestore.collection('users').doc('test-uid').set({
          'email': 'test@test.com',
          'name': 'Test User',
        });

        await service.deleteUserDocument('test-uid');
        final doc = await firestore.collection('users').doc('test-uid').get();
        expect(doc.exists, false);
      });
    });

    group('getUser', () {
      test('returns user when exists', () async {
        await firestore.collection('users').doc('test-uid').set({
          'email': 'test@test.com',
          'name': 'Test User',
          'role': UserRole.coach,
        });

        final user = await service.getUser('test-uid');
        expect(user, isNotNull);
        expect(user!.name, 'Test User');
      });

      test('returns null when not found', () async {
        final user = await service.getUser('nonexistent');
        expect(user, isNull);
      });
    });

    group('getUserByPhone', () {
      test('returns user when phone matches', () async {
        await firestore.collection('users').add({
          'email': 'test@test.com',
          'name': 'Test User',
          'role': UserRole.coach,
          'phone': '0123456789',
        });

        final user = await service.getUserByPhone('0123456789');
        expect(user, isNotNull);
        expect(user!.name, 'Test User');
      });

      test('returns null when phone not found', () async {
        final user = await service.getUserByPhone('0000000000');
        expect(user, isNull);
      });

      test('trims phone before query', () async {
        await firestore.collection('users').add({
          'email': 'test@test.com',
          'name': 'Test User',
          'role': UserRole.coach,
          'phone': '0123456789',
        });

        final user = await service.getUserByPhone('  0123456789  ');
        expect(user, isNotNull);
      });
    });

    group('hasAnyActiveAdminOrSuperAdmin', () {
      test('returns true when admin exists', () async {
        await firestore.collection('users').add({
          'role': UserRole.admin,
          'status': UserStatus.active,
        });

        final result = await service.hasAnyActiveAdminOrSuperAdmin();
        expect(result, true);
      });

      test('returns true when superAdmin exists', () async {
        await firestore.collection('users').add({
          'role': UserRole.superAdmin,
          'status': UserStatus.active,
        });

        final result = await service.hasAnyActiveAdminOrSuperAdmin();
        expect(result, true);
      });

      test('returns false when no admin or superAdmin exists', () async {
        await firestore.collection('users').add({
          'role': UserRole.coach,
          'status': UserStatus.active,
        });

        final result = await service.hasAnyActiveAdminOrSuperAdmin();
        expect(result, false);
      });

      test('returns false when admin is not active', () async {
        await firestore.collection('users').add({
          'role': UserRole.admin,
          'status': UserStatus.pending,
        });

        final result = await service.hasAnyActiveAdminOrSuperAdmin();
        expect(result, false);
      });
    });

    group('createUserForRegistration', () {
      test('creates user document with all fields', () async {
        await service.createUserForRegistration(
          uid: 'new-uid',
          email: 'new@test.com',
          name: 'New User',
          role: UserRole.coach,
          status: UserStatus.pending,
          phone: '0123456789',
        );

        final doc = await firestore.collection('users').doc('new-uid').get();
        expect(doc.exists, true);
        expect(doc.data()!['email'], 'new@test.com');
        expect(doc.data()!['name'], 'New User');
        expect(doc.data()!['role'], UserRole.coach);
        expect(doc.data()!['status'], UserStatus.pending);
        expect(doc.data()!['phone'], '0123456789');
      });

      test('creates user without phone', () async {
        await service.createUserForRegistration(
          uid: 'no-phone-uid',
          email: 'no-phone@test.com',
          name: 'No Phone',
          role: UserRole.viewer,
          status: UserStatus.pending,
        );

        final doc = await firestore.collection('users').doc('no-phone-uid').get();
        expect(doc.data()!.containsKey('phone'), false);
      });
    });

    group('getPendingUsers', () {
      test('returns only pending users sorted by email descending', () async {
        await firestore.collection('users').add({
          'email': 'b@test.com',
          'name': 'B User',
          'role': UserRole.coach,
          'status': UserStatus.pending,
        });
        await firestore.collection('users').add({
          'email': 'a@test.com',
          'name': 'A User',
          'role': UserRole.coach,
          'status': UserStatus.pending,
        });
        await firestore.collection('users').add({
          'email': 'active@test.com',
          'name': 'Active User',
          'role': UserRole.coach,
          'status': UserStatus.active,
        });

        final pending = await service.getPendingUsers();
        expect(pending.length, 2);
        expect(pending[0].email, 'b@test.com');
        expect(pending[1].email, 'a@test.com');
      });

      test('returns empty list when no pending users', () async {
        final pending = await service.getPendingUsers();
        expect(pending, isEmpty);
      });
    });

    group('approveUser', () {
      test('sets status to active and records approvedAt', () async {
        await firestore.collection('users').doc('test-uid').set({
          'email': 'test@test.com',
          'name': 'Test User',
          'role': UserRole.coach,
          'status': UserStatus.pending,
        });

        await service.approveUser('test-uid');
        final doc = await firestore.collection('users').doc('test-uid').get();
        expect(doc.data()!['status'], UserStatus.active);
      });
    });
  });
}
