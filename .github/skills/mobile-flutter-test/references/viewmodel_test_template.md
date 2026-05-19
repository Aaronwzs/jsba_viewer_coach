# ViewModel Test Template

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dumbdumb_flutter_app/app/assets/exporter/importer_app_structural_component.dart';

// ---------------------------------------------------------------------------
// Mock declarations — one per file, outside main()
// ---------------------------------------------------------------------------
class MockFeatureRepository extends Mock implements FeatureRepository {}

void main() {
  // -------------------------------------------------------------------------
  // Setup
  // -------------------------------------------------------------------------
  late MockFeatureRepository mockRepository;
  late FeatureViewModel viewModel;

  setUpAll(() {
    // Register fallback values for any custom types used in argument matchers
    // registerFallbackValue(SomeCustomObject());
  });

  setUp(() {
    mockRepository = MockFeatureRepository();
    viewModel = FeatureViewModel(repository: mockRepository);
  });

  tearDown(() {
    viewModel.dispose();
  });

  // -------------------------------------------------------------------------
  // Group: FeatureViewModel
  // -------------------------------------------------------------------------
  group('FeatureViewModel', () {
    // -----------------------------------------------------------------------
    // fetchFeature — success path
    // -----------------------------------------------------------------------
    group('fetchFeature', () {
      const featureJson = {
        'id': 1,
        'title': 'Test Feature',
        // ... add all fields from FeatureModel
      };

      test('sets isLoading true then false on success', () async {
        when(() => mockRepository.getFeature(any()))
            .thenAnswer((_) async => MyResponse.complete(featureJson));

        final loadingStates = <bool>[];
        viewModel.addListener(() => loadingStates.add(viewModel.isLoading));

        await viewModel.fetchFeature(1);

        expect(loadingStates, [true, false]);
      });

      test('populates feature data on success', () async {
        when(() => mockRepository.getFeature(any()))
            .thenAnswer((_) async => MyResponse.complete(featureJson));

        await viewModel.fetchFeature(1);

        expect(viewModel.feature, isNotNull);
        expect(viewModel.feature?.id, equals(1));
        expect(viewModel.feature?.title, equals('Test Feature'));
      });

      test('calls repository with the correct id', () async {
        when(() => mockRepository.getFeature(any()))
            .thenAnswer((_) async => MyResponse.complete(featureJson));

        await viewModel.fetchFeature(42);

        verify(() => mockRepository.getFeature(42)).called(1);
      });
    });

    // -----------------------------------------------------------------------
    // fetchFeature — error path (NormalErrorException)
    // -----------------------------------------------------------------------
    group('fetchFeature — NormalErrorException', () {
      final errorJson = {
        'message': 'Feature not found',
        'code': '404',
        'status': false,
      };

      test('resets isLoading to false on error', () async {
        when(() => mockRepository.getFeature(any()))
            .thenAnswer((_) async => MyResponse.error(errorJson));

        final loadingStates = <bool>[];
        viewModel.addListener(() => loadingStates.add(viewModel.isLoading));

        try {
          await viewModel.fetchFeature(1);
        } on NormalErrorException {
          // expected
        }

        expect(loadingStates.last, isFalse);
      });

      test('throws NormalErrorException on API error response', () async {
        when(() => mockRepository.getFeature(any()))
            .thenAnswer((_) async => MyResponse.error(errorJson));

        expect(
          () => viewModel.fetchFeature(1),
          throwsA(isA<NormalErrorException>()),
        );
      });
    });

    // -----------------------------------------------------------------------
    // fetchFeature — UrgentErrorException (session expired / 403)
    // -----------------------------------------------------------------------
    group('fetchFeature — UrgentErrorException', () {
      final forbiddenJson = {
        'message': 'Forbidden',
        'code': '403',
        'status': false,
        'isForbidden': true, // adjust to match ErrorModel.isForbidden logic
      };

      test('throws UrgentErrorException on forbidden error response', () async {
        when(() => mockRepository.getFeature(any()))
            .thenAnswer((_) async => MyResponse.error(forbiddenJson));

        expect(
          () => viewModel.fetchFeature(1),
          throwsA(isA<UrgentErrorException>()),
        );
      });
    });
  });
}
```

## Notes

- **`isLoading` listener pattern**: Add a listener before calling the async method, collect booleans, assert the sequence.
- **`throwsA(isA<T>())`**: Preferred over `expect(..., throws)` — type-safe and readable.
- **`verify(...).called(1)`**: Always verify that the repository was called with the exact expected arguments.
- **`viewModel.dispose()`** in `tearDown`: Prevents listener leaks between tests.
- **No `tester.pump()`**: ViewModels are plain Dart — no Flutter widget environment needed.

## Loading Cycle Diagram

```
fetchFeature(id) called
  │
  ├── _isLoading = true  → notifyListeners()   ← listener records [true]
  │
  ├── await repository.getFeature(id)
  │
  ├── _isLoading = false
  ├── _feature = response.data
  ├── notifyListeners()                         ← listener records [false]
  │
  └── checkError(response)  ← throws if error
```
