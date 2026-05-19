---
name: mobile-flutter-test
description: "Use when writing, reviewing, or planning tests for Flutter code in this project. Triggers on: Flutter unit test, widget test, ViewModel test, Repository test, Service test, integration test, flutter test, test coverage, mock, stub, test plan for Flutter."
---

# Flutter Test Standards

All tests must follow the MVVM architecture defined in `#mobile-flutter-standard`. Load that skill first to understand the production layer structure before writing any tests.

---

## MANDATORY Request Process

Follow this process for EVERY test-writing task without exception:

1. **Plan** — List all layers to test, the test cases per layer, and which mocks are needed
2. **Present** — Show the plan in numbered, actionable steps
3. **Request Approval** — Ask "Do you want me to proceed?" and STOP
4. **Wait** — Do NOT write any code until the user explicitly approves
5. **Execute** — Implement only after written approval

---

## Required Packages

Add to `pubspec.yaml` under `dev_dependencies` if not already present:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.4
```

Run `flutter pub get` after adding.

---

## Test Pyramid — Flutter MVVM

```
                  [Integration]       ← minimal, critical user journeys only
               [Widget / Page Tests]  ← UI states: loading, error, empty, data
            [ViewModel Unit Tests]    ← state transitions, loading, errors
         [Repository Unit Tests]      ← MyResponse processing, success/error paths
      [Utility / Model Unit Tests]    ← pure functions, fromJson/toJson, validators
```

---

## File Structure & Naming

Mirror the `lib/` folder structure under `test/`:

```
test/
  app/
    model/          → {name}_model_test.dart
    repository/     → {name}_repository_test.dart
    viewmodel/      → {name}_view_model_test.dart
    view/           → {name}_page_test.dart
    utils/          → {name}_utils_test.dart
  router_test.dart
```

**Naming rules:**
- Test files: `{name}_{type}_test.dart` — e.g., `user_view_model_test.dart`
- Test class prefix: `Mock{Class}` — e.g., `MockUserRepository`
- Group by class: `group('UserViewModel', () { ... })`
- Test name describes behaviour: `test('fetchUser sets isLoading to true then false', ...)`

---

## 1. ViewModel Unit Tests

See full template: [viewmodel test template](./references/viewmodel_test_template.md)

**Rules:**
- Mock the Repository layer using `mocktail` — never mock the ViewModel itself
- Inject the mock Repository via the ViewModel constructor (production ViewModels MUST support injection for testability)
- Always test the full loading cycle: `isLoading = true` → response → `isLoading = false`
- Verify `notifyListeners()` is called using a `ChangeNotifier` listener or `addListener` spy
- Test each of: success response, `NormalErrorException`, `UrgentErrorException`
- Use `MyResponse.complete(data)` for success stubs, `MyResponse.error(errorMap)` for error stubs
- Do NOT use `flutter_test` pump/settle — ViewModels are pure Dart, use plain `test()` not `testWidgets()`

**Standard error map for `NormalErrorException`:**
```dart
final errorMap = {'message': 'Something went wrong', 'code': '400', 'status': false};
MyResponse.error(errorMap)
```

**Standard error map for `UrgentErrorException`:**
```dart
// Forbidden status triggers UrgentErrorException via ErrorModel.isForbidden
final errorMap = {'message': 'Forbidden', 'code': '403', 'status': false};
MyResponse.error(errorMap)
```

---

## 2. Repository Unit Tests

See full template: [repository test template](./references/repository_test_template.md)

**Rules:**
- Mock the Services class using `mocktail`
- Inject the mock Services via the Repository constructor (production Repositories MUST support injection)
- Test success path: `MyResponse.complete(rawJson)` → verify domain model is mapped correctly
- Test error path: `MyResponse.error(errorMap)` → verify the error response is passed through unchanged
- Test edge cases: `null` data, empty list, missing JSON fields
- Do NOT test HTTP behaviour — that belongs to the Services layer (not unit tested)
- Verify `DynamicParsing` fields are mapped — check the domain model has the correct values

---

## 3. Widget / Page Tests

See full template: [widget test template](./references/widget_test_template.md)

**Rules:**
- Wrap the page under test in a `ChangeNotifierProvider` supplying a real or fake ViewModel
- Prefer a **fake ViewModel** (manual stub class) over `mocktail` for widget tests — easier to control state
- Use `testWidgets()` and `WidgetTester` for all widget/page tests
- Pump with `tester.pumpWidget(...)` then `tester.pump()` to let async builds settle
- Test these UI states for every screen: **loading**, **error**, **empty**, **data populated**
- Use `find.byType(CircularProgressIndicator)` or the project's loading widget to assert loading state
- Use `find.text(...)` and `find.byType(...)` for assertions — never rely on widget keys unless they are `Key('...')` constants
- Do NOT test GoRouter navigation in widget tests — verify only that the correct method was called on the ViewModel
- Call `tester.pumpAndSettle()` only when testing animations; prefer `tester.pump()` to avoid flakiness

---

## 4. Model Unit Tests

**Rules:**
- Test `fromJson` with a complete valid map — verify all fields are mapped
- Test `fromJson` with missing/null fields — verify defaults are applied, no crash
- Test `toJson` → `fromJson` round-trip — result should equal the original model
- Use plain `test()` — no Flutter framework needed

---

## 5. Utility Unit Tests

**Rules:**
- Test every validator in `app/utils/` with valid, invalid, and edge-case inputs
- Test date formatters, parsers, and string helpers
- Use plain `test()` — no Flutter framework needed

---

## 6. Mock Setup with Mocktail

```dart
import 'package:mocktail/mocktail.dart';

// Declare once per test file, outside main()
class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockUserRepository mockRepository;

  setUp(() {
    mockRepository = MockUserRepository();
  });

  // Register fallback values for custom types if needed
  setUpAll(() {
    registerFallbackValue(MyResponse.initial());
  });
}
```

**Stub patterns:**
```dart
// Async return
when(() => mockRepository.getUser(any())).thenAnswer((_) async => MyResponse.complete(userJson));

// Throw
when(() => mockRepository.getUser(any())).thenThrow(Exception('network error'));

// Verify call
verify(() => mockRepository.getUser(42)).called(1);
```

---

## 7. Making Production Code Testable

Every ViewModel and Repository **must** accept injected dependencies for testability. Follow this pattern:

**ViewModel:**
```dart
class UserViewModel extends BaseViewModel {
  final UserRepository _userRepository;

  // Default constructor uses real implementation; test constructor injects mock
  UserViewModel({UserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepository();
}
```

**Repository:**
```dart
class UserRepository {
  final UserServices _userServices;

  UserRepository({UserServices? userServices})
      : _userServices = userServices ?? UserServices();
}
```

If the production constructor does NOT already support injection, add the optional named parameter before writing tests. This is the only production code change permitted when adding tests.

---

## 8. Test Data Builders

Create reusable test data in `test/fixtures/` to keep test files clean:

```
test/
  fixtures/
    user_fixture.dart       → userJson, userModel, userListJson
    product_fixture.dart
```

**Pattern:**
```dart
// test/fixtures/user_fixture.dart
const Map<String, dynamic> userJson = {
  'id': 1,
  'name': 'Test User',
  'email': 'test@example.com',
};

UserModel get userModel => UserModel.fromJson(userJson);
```

---

## 9. Coverage Requirements

| Layer | Minimum coverage |
|---|---|
| ViewModel | 90% — all public methods |
| Repository | 80% — success + error paths |
| Model | 100% — fromJson/toJson |
| Utils/Validators | 100% |
| Pages/Widgets | Best effort — loading, error, data states |

Run coverage:
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## Quality Gates

Run these before every PR:

```bash
dart analyze                              # zero warnings, zero errors
flutter test                              # all tests pass
flutter test --coverage                   # check coverage report
```

---

## CRITICAL REMINDERS

1. **Never mock the ViewModel in widget tests** — use a fake ViewModel (a real subclass with controlled state) for deterministic UI testing.
2. **Never call `tester.pumpAndSettle()` as default** — it hides async timing bugs. Use `tester.pump()` explicitly.
3. **Never write `expect(true, true)`** — every assertion must test real output against expected output.
4. **Always test the error paths** — `NormalErrorException` and `UrgentErrorException` both need test cases.
5. **Always inject dependencies** — ViewModels and Repositories must support constructor injection before they can be tested.
6. **Never import test files from `lib/`** — test helpers and fixtures live only under `test/`.
7. **Never share state between tests** — use `setUp()` to reinitialize mocks and ViewModels for every test.
8. **Group related tests** — use `group('ClassName', () { group('methodName', () { ... }) })` for readable output.9. **Never assert on hardcoded strings in widget tests** — use `S.current.keyName` when finding text that came from a translation key (e.g. `find.text(S.current.loginButtonLabel)`). This keeps tests aligned with the ARB files and breaks if a key is removed.