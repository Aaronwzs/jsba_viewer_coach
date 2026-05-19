# Widget / Page Test Template

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dumbdumb_flutter_app/app/assets/exporter/importer_app_structural_component.dart';
import 'package:dumbdumb_flutter_app/app/assets/exporter/importer_app_screens.dart';

// ---------------------------------------------------------------------------
// Fake ViewModel — manual stub with controlled state.
// Prefer this over mocktail for widget tests: easier to drive UI states.
// ---------------------------------------------------------------------------
class FakeFeatureViewModel extends ChangeNotifier implements FeatureViewModel {
  @override
  bool isLoading = false;

  @override
  FeatureModel? feature;

  @override
  String? errorMessage;

  // Call this in tests to simulate a successful data load
  void simulateLoaded(FeatureModel data) {
    isLoading = false;
    feature = data;
    errorMessage = null;
    notifyListeners();
  }

  // Call this in tests to simulate a loading state
  void simulateLoading() {
    isLoading = true;
    feature = null;
    errorMessage = null;
    notifyListeners();
  }

  // Call this in tests to simulate an error state
  void simulateError(String message) {
    isLoading = false;
    feature = null;
    errorMessage = message;
    notifyListeners();
  }

  // Stub any ViewModel methods called from the page
  @override
  Future<void> fetchFeature(int id) async {
    // No-op by default — call simulateLoaded/simulateError to drive state
  }
}

// ---------------------------------------------------------------------------
// Helper: wrap the page under test with required providers and MaterialApp
// ---------------------------------------------------------------------------
Widget buildTestPage(FakeFeatureViewModel viewModel) {
  return MaterialApp(
    home: ChangeNotifierProvider<FeatureViewModel>.value(
      value: viewModel,
      child: const FeaturePage(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late FakeFeatureViewModel viewModel;

  setUp(() {
    viewModel = FakeFeatureViewModel();
  });

  group('FeaturePage', () {
    // -----------------------------------------------------------------------
    // Loading state
    // -----------------------------------------------------------------------
    testWidgets('shows loading indicator when isLoading is true', (tester) async {
      viewModel.simulateLoading();

      await tester.pumpWidget(buildTestPage(viewModel));
      await tester.pump(); // single frame — do NOT use pumpAndSettle for loading

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(FeatureContentWidget), findsNothing);
    });

    // -----------------------------------------------------------------------
    // Data state
    // -----------------------------------------------------------------------
    testWidgets('shows feature data when loaded successfully', (tester) async {
      final feature = FeatureModel.fromJson({
        'id': 1,
        'title': 'Test Feature',
        // ... add all required fields
      });

      await tester.pumpWidget(buildTestPage(viewModel));
      viewModel.simulateLoaded(feature);
      await tester.pump();

      expect(find.text('Test Feature'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    // -----------------------------------------------------------------------
    // Empty state
    // -----------------------------------------------------------------------
    testWidgets('shows empty state when feature is null and not loading', (tester) async {
      // Default FakeFeatureViewModel has feature = null, isLoading = false
      await tester.pumpWidget(buildTestPage(viewModel));
      await tester.pump();

      // Adjust finder to match the actual empty state widget in this screen
      expect(find.byKey(const Key('feature_empty_state')), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Error state
    // -----------------------------------------------------------------------
    testWidgets('shows error message when an error occurs', (tester) async {
      viewModel.simulateError('Feature not found');

      await tester.pumpWidget(buildTestPage(viewModel));
      await tester.pump();

      expect(find.text('Feature not found'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Interaction
    // -----------------------------------------------------------------------
    testWidgets('tapping action button calls fetchFeature on ViewModel', (tester) async {
      bool fetchCalled = false;
      // Override the stub to track the call
      final trackingViewModel = FakeFeatureViewModel();
      // Note: if you need to verify method calls, use mocktail on the ViewModel
      // and cast — or add a flag property to FakeFeatureViewModel.

      await tester.pumpWidget(buildTestPage(trackingViewModel));
      await tester.pump();

      await tester.tap(find.byKey(const Key('feature_action_button')));
      await tester.pump();

      // Verify the expected side effect (e.g., loading started)
      // expect(trackingViewModel.isLoading, isTrue);
    });
  });
}
```

## Notes

- **Fake ViewModel over mocktail**: A manual `FakeFeatureViewModel extends ChangeNotifier` is cleaner for widget tests. You control state directly by calling `simulateLoaded()`, `simulateLoading()`, `simulateError()`. Reserve mocktail for asserting exact method calls.
- **`tester.pump()` over `tester.pumpAndSettle()`**: Use `pump()` for most tests. Only use `pumpAndSettle()` when testing an animation that must complete.
- **Do NOT test navigation**: GoRouter navigation requires a full router setup that's out of scope for widget tests. Assert ViewModel method calls instead.
- **`buildTestPage` helper**: Keep this at the top of each test file. It eliminates duplicated Provider/MaterialApp boilerplate across `testWidgets` calls.
- **`Key` constants**: Add `const Key('...')` to important widgets in production pages to make them reliably findable in tests.

## UI State Summary

| State | `isLoading` | `feature` | Expected UI |
|---|---|---|---|
| Loading | `true` | `null` | `CircularProgressIndicator` visible |
| Data | `false` | populated | Feature content visible |
| Empty | `false` | `null` | Empty state widget visible |
| Error | `false` | `null` | Error message visible |
