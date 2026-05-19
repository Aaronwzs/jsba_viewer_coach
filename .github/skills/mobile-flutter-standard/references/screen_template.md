# Screen Template

Use this template when creating any new screen/page in the Flutter project.

## File: `lib/app/view/<feature_name>_page.dart`

```dart
import 'package:dumbdumb_flutter_app/app/assets/exporter/importer_app_general.dart';
import 'package:dumbdumb_flutter_app/app/assets/exporter/importer_app_screens.dart';
import 'package:dumbdumb_flutter_app/app/assets/exporter/importer_app_structural_component.dart';
import 'package:dumbdumb_flutter_app/app/assets/exporter/importer_routing.dart';

class FeatureNamePage extends BaseStatefulPage {
  const FeatureNamePage({super.key});

  @override
  State<StatefulWidget> createState() => _FeatureNamePageState();
}

class _FeatureNamePageState extends BaseStatefulState<FeatureNamePage> {
  @override
  void initState() {
    super.initState();
    // Trigger data fetch AFTER first build — never call context.watch/select here
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  // Dispose all controllers to prevent memory leaks
  @override
  void dispose() {
    // _someController.dispose();
    super.dispose();
  }

  @override
  AppBar appbar() {
    return AppBar(
      title: const Text('Feature Name'),
    );
  }

  @override
  Widget body() {
    // Use context.select to subscribe to a single field (scoped rebuild)
    final isLoading = context.select((FeatureNameViewModel vm) => vm.isLoading);
    final items = context.select((FeatureNameViewModel vm) => vm.items);

    if (isLoading) return const AppLoader();
    if (items.isEmpty) return const EmptyView();

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => FeatureItemCard(item: items[index]),
    );
  }

  // Override only if this screen needs a FAB
  // @override
  // Widget floatingActionButton() => FloatingActionButton(
  //   heroTag: UniqueKey(),
  //   onPressed: _onFabPressed,
  //   child: const Icon(Icons.add),
  // );

  // Override only if this screen needs a bottom nav bar
  // @override
  // Widget? bottomNavigationBar() => ...
}

// * ---------------------------- Actions ----------------------------
extension _Actions on _FeatureNamePageState {
  // All button handlers, API calls, and navigation belong here.
  // Use tryLoad for user-triggered mutations (shows loading spinner).
  // Use tryCatch for background/silent fetches (no spinner).

  Future<void> _loadInitialData() async {
    await tryCatch(context, () => context.read<FeatureNameViewModel>().fetchData());
  }

  Future<void> _onSubmitPressed() async {
    final success = await tryLoad(context, () => context.read<FeatureNameViewModel>().doSomething());
    if ((success ?? false) && mounted) {
      context.goNamed(RouterName.someRoute.value);
    }
  }
}
```

## After creating the screen, do ALL FOUR of these:

### 1. Add the route path — `lib/app/assets/router/app_router.dart`

```dart
// In _AppRouterPath enum:
featureName('/feature-name'),

// In GoRouter routes list:
GoRoute(
  path: _AppRouterPath.featureName.value,
  name: RouterName.featureName.value,
  builder: (context, state) => const FeatureNamePage(),
),
```

### 2. Add the route name — `RouterName` enum (in `base_router.dart`)

```dart
featureName('featureName'),
```

### 3. Register the ViewModel — `lib/app/assets/app_options.dart`

```dart
ChangeNotifierProvider(create: (_) => FeatureNameViewModel()),
```

### 4. Export the screen — `lib/app/assets/exporter/importer_app_screens.dart`

```dart
export 'package:dumbdumb_flutter_app/app/view/feature_name_page.dart';
```

## Key Rules

- Do NOT override `build()` — `BaseStatefulState` owns the `Scaffold`
- `body()` is the only required override
- Always use `heroTag: UniqueKey()` on every `FloatingActionButton`
- Check `mounted` after every `await` before calling `context` or navigating
- Use `context.read<VM>()` inside event handlers — never triggers rebuild
- Use `context.select((VM vm) => vm.field)` to subscribe to a single field
- Use `context.watch<VM>()` only when the full VM should trigger rebuild
- Use `Consumer<VM>` for scoped rebuilds of a specific subtree
- Never use raw `TextField` — always `AppTextField`
- Never use raw `ElevatedButton` — always `AppButton`
- Always `dispose()` every controller

## `BaseStatefulState` Override Reference

| Method | Default | Override when |
|---|---|---|
| `appbar()` | `null` | Screen needs a custom AppBar |
| `body()` | **Required** | Always |
| `backgroundColor()` | `scaffoldBackgroundColor` | Screen has a different background |
| `floatingActionButton()` | `null` | Screen has a FAB |
| `bottomNavigationBar()` | `null` | Screen has a bottom nav bar |
| `extendBodyBehindAppBar()` | `false` | Transparent/floating AppBar |
| `topSafeAreaEnabled()` | `true` | Screen intentionally goes behind status bar |
