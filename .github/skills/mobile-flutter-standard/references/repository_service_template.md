# Repository & Service Template

Use this template when creating a new API feature that requires a Service (raw API call) and a Repository (business logic).

---

## Service — `lib/app/service/<feature_name>_services.dart`

The Service layer only makes raw HTTP calls. No business logic.

```dart
import 'package:dumbdumb_flutter_app/app/assets/exporter/importer_app_general.dart';
import 'package:dumbdumb_flutter_app/app/assets/exporter/importer_app_structural_component.dart';

class FeatureNameServices extends BaseServices {
  /// GET example
  Future<MyResponse> getFeatureData(String id) async {
    final String path = '$apiUrl/feature/$id';
    return callAPI(HttpRequestType.get, path);
  }

  /// POST example
  Future<MyResponse> createFeature({required String name, required String value}) async {
    final String path = '$apiUrl/feature';
    final postBody = {'name': name, 'value': value};
    return callAPI(HttpRequestType.post, path, postBody: postBody);
  }

  /// PUT example
  Future<MyResponse> updateFeature(String id, Map<String, dynamic> body) async {
    final String path = '$apiUrl/feature/$id';
    return callAPI(HttpRequestType.put, path, postBody: body);
  }

    /// GET with query parameters example
    Future<MyResponse> getFeatureList({int page = 0, int take = 20}) async {
      final String path = '$apiUrl/feature';
      return callAPI(HttpRequestType.get, path, queryParameters: {'page': page, 'take': take});
    }
  /// DELETE example
  Future<MyResponse> deleteFeature(String id) async {
    final String path = '$apiUrl/feature/$id';
    return callAPI(HttpRequestType.delete, path);
  }
}
```

**Service Rules:**

## Repository — `lib/app/repository/<feature_name>_repository.dart`

The Repository layer processes the raw `MyResponse` from Services and maps it to domain models.

```dart
import 'package:dumbdumb_flutter_app/app/assets/exporter/importer_app_general.dart';
import 'package:dumbdumb_flutter_app/app/assets/exporter/importer_app_structural_component.dart';

/// Repository class handles business logic for data access:
/// 1. Maps raw service responses to typed domain models
/// 2. Decides between cache data and live server data
/// 3. Combines multiple data sources into a single response
class FeatureNameRepository {
  final FeatureNameServices _featureNameServices = FeatureNameServices();

  Future<MyResponse> getFeatureData(String id) async {
    final response = await _featureNameServices.getFeatureData(id);

    if (response.data is Map<String, dynamic> && response.error == null) {
      return MyResponse.complete(FeatureModel.fromJson(response.data));
    }

    return response;
  }

  Future<MyResponse> createFeature({required String name, required String value}) async {
    final response = await _featureNameServices.createFeature(name: name, value: value);

    if (response.data is Map<String, dynamic> && response.error == null) {
      return MyResponse.complete(FeatureModel.fromJson(response.data));
    }

    return response;
  }
}
```

**Repository Rules:**
- Plain Dart class — no base class
- Instantiates its own Services: `final FeatureNameServices _featureNameServices = FeatureNameServices();`
- Always check `response.data is ExpectedType && response.error == null` before mapping
- Return `MyResponse.complete(mappedModel)` on success
- Return the original `response` on failure — never swallow errors
- Business logic lives here: caching decisions, data aggregation from multiple sources

---

## After creating, export both from the barrel file

In `lib/app/assets/exporter/importer_app_structural_component.dart`:

```dart
export 'package:dumbdumb_flutter_app/app/repository/feature_name_repository.dart';
export 'package:dumbdumb_flutter_app/app/service/feature_name_services.dart';
```

---

## Flow Summary

```
View
  └── tryLoad → ViewModel.doSomething()
        └── Repository.getFeatureData()
              └── Service.getFeatureData()  ← raw HTTP call, returns MyResponse
              Service returns MyResponse (raw JSON or error)
        Repository maps → MyResponse.complete(FeatureModel)
        ViewModel sets _field, notifyListeners(), checkError()
  View re-renders with new data
```
