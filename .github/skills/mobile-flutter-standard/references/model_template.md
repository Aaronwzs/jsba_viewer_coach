# Model Template

Use this template when creating any new data model in the Flutter project.

## File: `lib/app/model/<feature_name>_model.dart`

```dart
import 'package:dumbdumb_flutter_app/app/assets/exporter/importer_app_general.dart';

class FeatureModel {
  // Declare all fields as nullable unless guaranteed by the API contract
  String? id;
  String? name;
  String? description;
  int? status;
  bool? isActive;
  String? createdDate;

  // Named constructor for creating instances manually
  FeatureModel({
    this.id,
    this.name,
    this.description,
    this.status,
    this.isActive,
    this.createdDate,
  });

  // Named constructor for deserialising from JSON
  // Always use DynamicParsing for safe parsing — never cast directly
  FeatureModel.fromJson(Map<String, dynamic> json) {
    id = DynamicParsing(json['id']).parseString();
    name = DynamicParsing(json['name']).parseString();
    description = DynamicParsing(json['description']).parseString();
    status = int.tryParse(json['status'].toString()) ?? 0;
    isActive = DynamicParsing(json['isActive']).parseBool();
    createdDate = DynamicParsing(json['createdDate']).parseString();
  }

  // Serialise to JSON for API requests or local storage
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['description'] = description;
    data['status'] = status;
    data['isActive'] = isActive;
    data['createdDate'] = createdDate;
    return data;
  }
}
```

---

## Nested Model Example

When a model contains a nested object or list:

```dart
class OrderModel {
  String? orderId;
  UserModel? customer;          // nested object
  List<OrderItemModel>? items;  // nested list

  OrderModel({this.orderId, this.customer, this.items});

  OrderModel.fromJson(Map<String, dynamic> json) {
    orderId = DynamicParsing(json['orderId']).parseString();

    // Nested object — check for null before mapping
    customer = json['customer'] != null
        ? UserModel.fromJson(json['customer'])
        : null;

    // Nested list — check for null and cast safely
    if (json['items'] != null) {
      items = (json['items'] as List)
          .map((item) => OrderItemModel.fromJson(item))
          .toList();
    }
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['orderId'] = orderId;
    data['customer'] = customer?.toJson();
    data['items'] = items?.map((item) => item.toJson()).toList();
    return data;
  }
}
```

---

## DynamicParsing — Type-Safe Parsing Reference

Always use `DynamicParsing` for JSON field parsing. Never use direct casts like `json['field'] as String`.

| Type | Usage |
|---|---|
| `String?` | `DynamicParsing(json['field']).parseString()` |
| `bool?` | `DynamicParsing(json['field']).parseBool()` |
| `int?` | `int.tryParse(json['field'].toString()) ?? 0` |
| `double?` | `double.tryParse(json['field'].toString())` |
| Nested object | `json['field'] != null ? MyModel.fromJson(json['field']) : null` |
| List | `(json['field'] as List).map((e) => MyModel.fromJson(e)).toList()` |

---

## After creating a model, do ALL of these:

### Export from the correct barrel file

In `lib/app/assets/exporter/importer_app_structural_component.dart`:

```dart
export 'package:dumbdumb_flutter_app/app/model/feature_model.dart';
```

If it belongs to a sub-folder (e.g. `model/network/` or `model/common/`), export from there accordingly.

---

## Key Rules

- All fields should be **nullable** (`String?`, `int?`) unless the API guarantees the field is always present
- Always implement both `fromJson` and `toJson` — even if `toJson` is not immediately needed
- Never cast JSON values directly (`json['field'] as String`) — always use `DynamicParsing` for null safety
- Keep models as pure data classes — no business logic, no API calls inside models
- Separate API response models from domain models if the API shape differs from what the UI needs
