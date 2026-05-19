# Repository Test Template

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dumbdumb_flutter_app/app/assets/exporter/importer_app_structural_component.dart';

// ---------------------------------------------------------------------------
// Mock declarations — one per file, outside main()
// ---------------------------------------------------------------------------
class MockFeatureServices extends Mock implements FeatureServices {}

void main() {
  // -------------------------------------------------------------------------
  // Setup
  // -------------------------------------------------------------------------
  late MockFeatureServices mockServices;
  late FeatureRepository repository;

  setUp(() {
    mockServices = MockFeatureServices();
    repository = FeatureRepository(services: mockServices);
  });

  // -------------------------------------------------------------------------
  // Shared fixtures
  // -------------------------------------------------------------------------
  const featureJson = {
    'id': 1,
    'title': 'Test Feature',
    // ... add all fields from FeatureModel
  };

  final errorJson = {
    'message': 'Not found',
    'code': '404',
    'status': false,
  };

  // -------------------------------------------------------------------------
  // Group: FeatureRepository
  // -------------------------------------------------------------------------
  group('FeatureRepository', () {
    // -----------------------------------------------------------------------
    // getFeature — success path
    // -----------------------------------------------------------------------
    group('getFeature', () {
      test('returns MyResponse.complete with a mapped FeatureModel on success', () async {
        when(() => mockServices.getFeature(any()))
            .thenAnswer((_) async => MyResponse.complete(featureJson));

        final result = await repository.getFeature(1);

        expect(result.status, equals(ResponseStatus.complete));
        expect(result.data, isA<FeatureModel>());
        expect(result.data?.id, equals(1));
        expect(result.data?.title, equals('Test Feature'));
      });

      test('calls services with the correct id', () async {
        when(() => mockServices.getFeature(any()))
            .thenAnswer((_) async => MyResponse.complete(featureJson));

        await repository.getFeature(42);

        verify(() => mockServices.getFeature(42)).called(1);
      });
    });

    // -----------------------------------------------------------------------
    // getFeature — error path
    // -----------------------------------------------------------------------
    group('getFeature — error', () {
      test('passes through the original error MyResponse unchanged', () async {
        when(() => mockServices.getFeature(any()))
            .thenAnswer((_) async => MyResponse.error(errorJson));

        final result = await repository.getFeature(1);

        expect(result.status, equals(ResponseStatus.error));
        expect(result.error, equals(errorJson));
        // data must be null on error
        expect(result.data, isNull);
      });
    });

    // -----------------------------------------------------------------------
    // getFeature — edge cases
    // -----------------------------------------------------------------------
    group('getFeature — edge cases', () {
      test('handles null data in complete response without crashing', () async {
        when(() => mockServices.getFeature(any()))
            .thenAnswer((_) async => MyResponse.complete(null));

        final result = await repository.getFeature(1);

        // Depending on repository logic: either null data or a default model
        expect(result.status, equals(ResponseStatus.complete));
        expect(result.data, isNull);
      });

      test('handles empty JSON map in complete response', () async {
        when(() => mockServices.getFeature(any()))
            .thenAnswer((_) async => MyResponse.complete(<String, dynamic>{}));

        final result = await repository.getFeature(1);

        expect(result.status, equals(ResponseStatus.complete));
        // All FeatureModel fields should fall back to defaults from DynamicParsing
        expect(result.data, isNotNull);
        expect(result.data?.id, equals(0));   // default for int
        expect(result.data?.title, equals('')); // default for string
      });
    });
  });
}
```

## Notes

- **`MyResponse.complete(json)`**: Pass the raw JSON map — the Repository is responsible for mapping it to a domain model.
- **`MyResponse.error(errorJson)`**: Repositories must pass the original response through unchanged — do not rethrow or wrap errors.
- **Never test HTTP calls here**: That belongs to the Services layer and is covered by API/integration tests.
- **`DynamicParsing` defaults**: Always verify that missing fields fall back to the correct default values (empty string, 0, false) rather than throwing.
- **Inject Services via constructor**: Production Repositories must accept an optional `services` parameter:

```dart
class FeatureRepository {
  final FeatureServices _featureServices;

  FeatureRepository({FeatureServices? services})
      : _featureServices = services ?? FeatureServices();
}
```

## MyResponse Status Reference

| Status | Meaning |
|---|---|
| `ResponseStatus.initial` | Not yet loaded |
| `ResponseStatus.loading` | In flight |
| `ResponseStatus.complete` | Success — `data` is populated |
| `ResponseStatus.error` | Failure — `error` is populated |
| `ResponseStatus.consumed` | Already handled by the UI |
