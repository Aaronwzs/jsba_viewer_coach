# ViewModel Template

Use this template when creating any new ViewModel in the Flutter project.

## File: `lib/app/viewmodel/<feature_name>_view_model.dart`

```dart
import 'package:dumbdumb_flutter_app/app/assets/exporter/importer_app_structural_component.dart';

/// ViewModel as a connector between View and the data layer.
/// Separates business logic from UI.
/// One ViewModel class may serve multiple View classes.
class FeatureNameViewModel extends BaseViewModel {
  // Private backing fields with public getters
  List<FeatureModel> get items => _items;
  List<FeatureModel> _items = [];

  bool get isLoading => _isLoading;
  bool _isLoading = false;

  final FeatureNameRepository _repository = FeatureNameRepository();

  /// Fetch a list from the repository.
  Future<void> fetchData() async {
    // Set loading true FIRST, notify UI before the await
    _isLoading = true;
    notifyListeners();

    final response = await _repository.getItems();

    if (response.data is List) {
      _items = (response.data as List)
          .map((e) => FeatureModel.fromJson(e))
          .toList();
    }

    _isLoading = false;
    // Always call notifyListeners() BEFORE checkError()
    // so the UI updates even when an error is about to be thrown
    notifyListeners();
    checkError(response);
  }

  /// Example mutation method — returns bool for use with tryLoad.
  Future<bool> doSomething() async {
    final response = await _repository.performAction();

    if (response.data == true) {
      notifyListeners();
      return true;
    }

    notifyListeners();
    checkError(response);
    return false;
  }
}
```

## After creating the ViewModel, do ALL of these:

### 1. Export from the structural component barrel

In `lib/app/assets/exporter/importer_app_structural_component.dart`:

```dart
export 'package:dumbdumb_flutter_app/app/viewmodel/feature_name_view_model.dart';
```

### 2. Register as a Provider

In `lib/app/assets/app_options.dart` → `providerAssets()`:

```dart
ChangeNotifierProvider(create: (_) => FeatureNameViewModel()),
```

## Key Rules

- Always extends `BaseViewModel` (which mixes in `ChangeNotifier`)
- Private fields with public getters: `SomeType? get field => _field;`
- Set `_isLoading = true` + `notifyListeners()` at the **start** of any async fetch
- Reset `_isLoading = false` before the final `notifyListeners()` call
- Call `notifyListeners()` **before** `checkError(response)` — ensures the UI gets the latest data even when an error is thrown
- `checkError()` throws `UrgentErrorException` (403/401) or `NormalErrorException` — the View catches these via `tryLoad`/`tryCatch`
- Do NOT call `showDialog`, `Navigator.push`, or access `BuildContext` in a ViewModel
- One ViewModel can be shared by multiple screens — keep it feature-scoped, not page-scoped
- Expose the minimum state the screen needs — no raw model lists if the screen only needs a count

## Loading State Pattern

```dart
// In ViewModel
Future<void> fetchData() async {
  _isLoading = true;
  notifyListeners();          // ← UI shows loader immediately

  final response = await _repository.getItems();
  // ... process response ...

  _isLoading = false;
  notifyListeners();          // ← UI hides loader, shows data
  checkError(response);       // ← throws if error, after UI has updated
}
```

```dart
// In View — load on screen open
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    tryCatch(context, () => context.read<FeatureNameViewModel>().fetchData());
  });
}

// In View — respond to isLoading
Widget body() {
  final isLoading = context.select((FeatureNameViewModel vm) => vm.isLoading);
  if (isLoading) return const AppLoader();
  // ... rest of body
}
```

## Error Flow

```
ViewModel.fetchData()
  ├── Sets _isLoading = true, notifyListeners()
  ├── Awaits repository
  ├── Processes data into typed fields
  ├── Sets _isLoading = false, notifyListeners()  ← UI updates with data
  └── checkError(response)
        ├── No error → no-op
        ├── NormalErrorException → caught by tryCatch/tryLoad → shows error dialog
        └── UrgentErrorException → caught by tryCatch/tryLoad → shows dialog + logout
```
