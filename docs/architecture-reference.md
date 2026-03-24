# Project Architecture Reference (Solarvest-based)

## Directory Structure

```
lib/
├── app/
│   ├── assets/
│   │   ├── constants/           # App constants, enums
│   │   ├── exporter/            # Centralized export files
│   │   ├── router/              # Auto Route configuration
│   │   ├── styles/              # Theme, colors, palettes
│   │   └── assets.g.dart        # Generated assets
│   ├── model/                   # Data models
│   ├── repository/              # Repository layer (data transformation)
│   ├── service/                 # API services (HTTP calls)
│   ├── utils/                   # Utility classes
│   ├── view/                    # UI screens
│   │   ├── pages/               # Page definitions
│   │   └── app.dart             # Root widget
│   ├── viewmodel/               # ViewModels (state management)
│   └── widgets/                 # Reusable widgets
├── firebase_options.dart
└── main.dart
```

## Architecture Layers

### 1. Model Layer
- Data models with JSON serialization
- Located in `app/model/`
- Each model: `model_name.dart`, `model_name.g.dart`, `model_name.freezed.dart`

### 2. Service Layer
- HTTP/API calls to backend
- Extends `BaseServices`
- Uses Dio for HTTP requests
- Located in `app/service/`

### 3. Repository Layer
- Transforms service data to models
- Business logic layer
- Located in `app/repository/`

### 4. ViewModel Layer
- Extends `BaseViewModel` + `ChangeNotifier`
- State management with Provider
- Business logic for screens
- Located in `app/viewmodel/`

### 5. View Layer
- UI screens (Pages)
- Uses Auto Route for navigation
- Located in `app/view/`

---

## Key Patterns

### Export System
Use exporter files to centralize imports:

```dart
// importer_app_general.dart - General exports
export 'package:flutter/material.dart';
export 'package:provider/provider.dart';
export 'package:com_vestechenergy_app/app/model/models.dart';

// importer_routing.dart - Routing exports
// importer_app_structural_component.dart - Structural component exports
```

### ViewModel Pattern
```dart
class UserViewModel extends BaseViewModel {
  final repository = UserRepository(userServices: UserServices());
  
  Future<void> login() async {
    final response = await repository.login(...);
    checkError(response);
    notifyListeners();
  }
}
```

### Service Pattern
```dart
class UserServices extends BaseServices {
  Future<MyResponse> login(...) async {
    return callAPI(HttpRequestType.post, path, postBody: data);
  }
}
```

### Repository Pattern
```dart
class UserRepository {
  UserRepository({required UserServices userServices}) : _userServices = userServices;
  
  Future<MyResponse> login(...) async {
    final response = await _userServices.login(...);
    // Transform response to model
    if (response.data is Map && response.error == null) {
      final result = ResultModel.fromJson(...).result;
      return MyResponse.complete(result);
    }
    return response;
  }
}
```

### Provider Setup
In `app_options.dart`:
```dart
List<SingleChildWidget> providerAssets() => [
  ChangeNotifierProvider(create: (_) => AppTheme()),
  ChangeNotifierProvider(create: (_) => UserViewModel()),
  ChangeNotifierProvider(create: (_) => AppViewModel()),
];
```

### Router Setup
```dart
@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(initial: true, page: RootNavigatorRoute.page, children: [
      AutoRoute(page: SplashScreenRoute.page, initial: true),
      AutoRoute(page: LoginRoute.page),
      AutoRoute(page: DashboardRoute.page, children: [...]),
    ]),
  ];
}
```

---

## Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.0
  auto_route: ^9.0.0
  dio: ^5.0.0
  flutter_form_builder: ^9.0.0
  freezed_annotation: ^2.4.0
  json_annotation: ^4.8.0
  firebase_core: ^3.0.0
  cloud_firestore: ^5.0.0
  firebase_auth: ^5.0.0

dev_dependencies:
  build_runner: ^2.4.0
  freezed: ^2.4.0
  json_serializable: ^6.7.0
  auto_route_generator: ^9.0.0
```
