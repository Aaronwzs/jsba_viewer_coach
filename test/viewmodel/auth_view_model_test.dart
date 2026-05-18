import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart' show UserCredential;
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:jsba_app/app/model/user_model.dart';
import 'package:jsba_app/app/service/auth_service.dart';
import 'package:jsba_app/app/service/database_service.dart';
import 'package:jsba_app/app/viewmodel/auth_view_model.dart';
import '../helpers/model_factories.dart';

class MockAuthService extends Mock implements AuthService {}
class MockDatabaseService extends Mock implements DatabaseService {}
class MockUserCredential extends Mock implements UserCredential {}

void main() {
  late MockAuthService mockAuthService;
  late MockDatabaseService mockDatabaseService;
  late AuthViewModel viewModel;
  late MockUser mockFirebaseUser;
  late MockUserCredential mockUserCredential;
  late UserModel testUser;

  setUp(() {
    mockAuthService = MockAuthService();
    mockDatabaseService = MockDatabaseService();
    viewModel = AuthViewModel(
      authService: mockAuthService,
      databaseService: mockDatabaseService,
    );
    mockFirebaseUser = MockUser(uid: 'test-uid', email: 'test@test.com');
    mockUserCredential = MockUserCredential();
    when(() => mockUserCredential.user).thenReturn(mockFirebaseUser);
    testUser = TestModelFactory.createUser(
      uid: 'test-uid',
      email: 'test@test.com',
      role: 'Coach',
    );
  });

  group('signIn', () {
    test('signIn returns true and sets currentUser on success', () async {
      when(() => mockAuthService.signInWithEmailAndPassword(any(), any()))
          .thenAnswer((_) async => mockUserCredential);
      when(() => mockDatabaseService.ensureUserDocumentExists(any()))
          .thenAnswer((_) async => testUser);

      final result = await viewModel.signIn('test@test.com', 'password');

      expect(result, true);
      expect(viewModel.currentUser, isNotNull);
      expect(viewModel.currentUser!.uid, 'test-uid');
      expect(viewModel.isLoggedIn, true);
      expect(viewModel.isCoach, true);
      expect(viewModel.isLoading, false);
    });

    test('signIn returns false on error', () async {
      when(() => mockAuthService.signInWithEmailAndPassword(any(), any()))
          .thenThrow(Exception('Invalid credentials'));

      final result = await viewModel.signIn('test@test.com', 'wrong');

      expect(result, false);
      expect(viewModel.currentUser, isNull);
      expect(viewModel.error, isNotNull);
      expect(viewModel.isLoading, false);
    });
  });

  group('register', () {
    test('register creates user and returns true', () async {
      when(() => mockAuthService.createUserWithEmailAndPassword(any(), any()))
          .thenAnswer((_) async => mockUserCredential);
      when(() => mockAuthService.updateDisplayName(any()))
          .thenAnswer((_) async {});
      when(() => mockDatabaseService.createUserForRegistration(
        uid: any(named: 'uid'),
        email: any(named: 'email'),
        name: any(named: 'name'),
        role: any(named: 'role'),
        status: any(named: 'status'),
      )).thenAnswer((_) async {});
      when(() => mockDatabaseService.getUser(any()))
          .thenAnswer((_) async => testUser);

      final result = await viewModel.register(
        'test@test.com', 'password123', 'Test User', 'Coach',
      );

      expect(result, true);
      expect(viewModel.currentUser, isNotNull);
      expect(viewModel.isLoading, false);
      verify(() => mockAuthService.updateDisplayName('Test User')).called(1);
    });
  });

  group('signOut', () {
    test('signOut clears currentUser', () async {
      when(() => mockAuthService.signInWithEmailAndPassword(any(), any()))
          .thenAnswer((_) async => mockUserCredential);
      when(() => mockDatabaseService.ensureUserDocumentExists(any()))
          .thenAnswer((_) async => testUser);
      await viewModel.signIn('test@test.com', 'password');
      expect(viewModel.isLoggedIn, true);

      when(() => mockAuthService.signOut()).thenAnswer((_) async {});
      await viewModel.signOut();

      expect(viewModel.currentUser, isNull);
      expect(viewModel.isLoggedIn, false);
      expect(viewModel.isLoading, false);
    });
  });

  group('updateUserName', () {
    test('updateUserName updates display name and DB', () async {
      when(() => mockAuthService.signInWithEmailAndPassword(any(), any()))
          .thenAnswer((_) async => mockUserCredential);
      when(() => mockDatabaseService.ensureUserDocumentExists(any()))
          .thenAnswer((_) async => testUser);
      await viewModel.signIn('test@test.com', 'password');

      final updatedUser = TestModelFactory.createUser(
        uid: 'test-uid', email: 'test@test.com', name: 'New Name', role: 'Coach',
      );
      when(() => mockAuthService.updateDisplayName(any()))
          .thenAnswer((_) async {});
      when(() => mockDatabaseService.updateUserProfile(
        any(), name: any(named: 'name'),
      )).thenAnswer((_) async {});
      when(() => mockDatabaseService.getUser(any()))
          .thenAnswer((_) async => updatedUser);

      final result = await viewModel.updateUserName('New Name');

      expect(result, true);
      expect(viewModel.currentUser!.name, 'New Name');
      verify(() => mockAuthService.updateDisplayName('New Name')).called(1);
    });
  });

  group('checkAuth', () {
    test('checkAuth loads user from DB when signed in', () async {
      when(() => mockAuthService.currentUser).thenReturn(mockFirebaseUser);
      when(() => mockDatabaseService.getUser('test-uid'))
          .thenAnswer((_) async => testUser);

      await viewModel.checkAuth();

      expect(viewModel.isLoading, false);
      expect(viewModel.currentUser, isNotNull);
      expect(viewModel.currentUser!.uid, 'test-uid');
    });

    test('checkAuth does nothing when not signed in', () async {
      when(() => mockAuthService.currentUser).thenReturn(null);

      await viewModel.checkAuth();

      expect(viewModel.isLoading, false);
      expect(viewModel.currentUser, isNull);
    });
  });

  group('sendPasswordResetEmail', () {
    test('sendPasswordResetEmail returns true on success', () async {
      when(() => mockAuthService.sendPasswordResetEmail(any()))
          .thenAnswer((_) async {});

      final result = await viewModel.sendPasswordResetEmail('test@test.com');

      expect(result, true);
      expect(viewModel.isLoading, false);
    });

    test('sendPasswordResetEmail returns false on error', () async {
      when(() => mockAuthService.sendPasswordResetEmail(any()))
          .thenThrow(Exception('Failed'));

      final result = await viewModel.sendPasswordResetEmail('test@test.com');

      expect(result, false);
      expect(viewModel.error, isNotNull);
      expect(viewModel.isLoading, false);
    });
  });

  group('phone OTP', () {
    test('requestPhoneOtp stores verification ID', () async {
      when(() => mockAuthService.verifyPhoneNumber(any()))
          .thenAnswer((_) async => 'verification-id-123');

      final result = await viewModel.requestPhoneOtp('+60123456789');

      expect(result, true);
      expect(viewModel.isLoading, false);
    });

    test('verifyPhoneOtp signs in and sets currentUser', () async {
      when(() => mockAuthService.verifyPhoneNumber(any()))
          .thenAnswer((_) async => 'vid-456');
      await viewModel.requestPhoneOtp('+60123456789');

      when(() => mockAuthService.signInWithPhoneCredential(
        verificationId: any(named: 'verificationId'),
        smsCode: any(named: 'smsCode'),
      )).thenAnswer((_) async => mockUserCredential);
      when(() => mockDatabaseService.ensureUserDocumentExists(any()))
          .thenAnswer((_) async => testUser);

      final result = await viewModel.verifyPhoneOtp('123456');

      expect(result, true);
      expect(viewModel.currentUser, isNotNull);
      expect(viewModel.currentUser!.uid, 'test-uid');
      expect(viewModel.isLoading, false);
    });
  });

  group('getters', () {
    test('clearError resets error', () async {
      when(() => mockAuthService.signInWithEmailAndPassword(any(), any()))
          .thenThrow(Exception('Some error'));
      await viewModel.signIn('test@test.com', 'password');
      expect(viewModel.error, isNotNull);

      viewModel.clearError();

      expect(viewModel.error, isNull);
    });

    test('initial state has no user and no loading', () {
      expect(viewModel.isLoggedIn, false);
      expect(viewModel.currentUser, isNull);
      expect(viewModel.isLoading, false);
      expect(viewModel.error, isNull);
    });
  });
}
