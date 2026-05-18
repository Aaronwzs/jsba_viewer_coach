import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:jsba_app/app/utils/shared_preference_handler.dart';
import 'package:jsba_app/app/viewmodel/app_view_model.dart';

class MockSharedPreferenceHandler extends Mock implements SharedPreferenceHandler {}

void main() {
  late MockSharedPreferenceHandler mockPrefs;

  setUp(() {
    mockPrefs = MockSharedPreferenceHandler();
  });

  group('constructor', () {
    test('loads user data from prefs', () {
      when(() => mockPrefs.getUserRole()).thenReturn('coach');
      when(() => mockPrefs.getUserId()).thenReturn('uid1');

      final viewModel = AppViewModel(prefs: mockPrefs);

      expect(viewModel.userRole, 'coach');
      expect(viewModel.userId, 'uid1');
      expect(viewModel.isCoach, true);
      expect(viewModel.isLoggedIn, true);
    });
  });

  group('login', () {
    test('login sets user fields and calls prefs setters', () async {
      when(() => mockPrefs.getUserRole()).thenReturn('');
      when(() => mockPrefs.getUserId()).thenReturn('');
      final viewModel = AppViewModel(prefs: mockPrefs);
      when(() => mockPrefs.setUserRole(any())).thenAnswer((_) async {});
      when(() => mockPrefs.setUserId(any())).thenAnswer((_) async {});

      await viewModel.login('parent', 'Test Name', 'parent@test.com', 'uid2');

      expect(viewModel.userRole, 'parent');
      expect(viewModel.userName, 'Test Name');
      expect(viewModel.userEmail, 'parent@test.com');
      expect(viewModel.userId, 'uid2');
      verify(() => mockPrefs.setUserRole('parent')).called(1);
      verify(() => mockPrefs.setUserId('uid2')).called(1);
    });
  });

  group('logout', () {
    test('logout clears fields and calls prefs.clearAll', () async {
      when(() => mockPrefs.getUserRole()).thenReturn('coach');
      when(() => mockPrefs.getUserId()).thenReturn('uid1');
      final viewModel = AppViewModel(prefs: mockPrefs);
      when(() => mockPrefs.clearAll()).thenAnswer((_) async {});

      await viewModel.logout();

      expect(viewModel.userRole, '');
      expect(viewModel.userName, '');
      expect(viewModel.userEmail, '');
      expect(viewModel.userId, '');
      verify(() => mockPrefs.clearAll()).called(1);
    });
  });

  group('isCoach', () {
    test('isCoach returns true when role is coach', () {
      when(() => mockPrefs.getUserRole()).thenReturn('coach');
      when(() => mockPrefs.getUserId()).thenReturn('uid1');
      final viewModel = AppViewModel(prefs: mockPrefs);

      expect(viewModel.isCoach, true);
      expect(viewModel.isParent, false);
    });
  });

  group('isParent', () {
    test('isParent returns true when role is parent', () {
      when(() => mockPrefs.getUserRole()).thenReturn('parent');
      when(() => mockPrefs.getUserId()).thenReturn('uid1');
      final viewModel = AppViewModel(prefs: mockPrefs);

      expect(viewModel.isParent, true);
      expect(viewModel.isCoach, false);
    });
  });

  group('isLoggedIn', () {
    test('isLoggedIn reflects userId presence', () {
      when(() => mockPrefs.getUserRole()).thenReturn('');
      when(() => mockPrefs.getUserId()).thenReturn('');
      final viewModel = AppViewModel(prefs: mockPrefs);

      expect(viewModel.isLoggedIn, false);
    });
  });
}
