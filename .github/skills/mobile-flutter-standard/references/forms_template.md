# Forms Template

Use this template for any screen that contains a form with user input and a submit action.

## File: `lib/app/view/<feature_name>_page.dart`

```dart
import 'package:dumbdumb_flutter_app/app/assets/exporter/importer_app_general.dart';
import 'package:dumbdumb_flutter_app/app/assets/exporter/importer_app_screens.dart';
import 'package:dumbdumb_flutter_app/app/assets/exporter/importer_app_structural_component.dart';
import 'package:dumbdumb_flutter_app/app/assets/exporter/importer_routing.dart';

class FeatureFormPage extends BaseStatefulPage {
  const FeatureFormPage({super.key});

  @override
  State<StatefulWidget> createState() => _FeatureFormPageState();
}

class _FeatureFormPageState extends BaseStatefulState<FeatureFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _fieldOneController = TextEditingController();
  final _fieldTwoController = TextEditingController();

  // Always dispose every controller — no exceptions
  @override
  void dispose() {
    _fieldOneController.dispose();
    _fieldTwoController.dispose();
    super.dispose();
  }

  @override
  AppBar appbar() => AppBar(title: const Text('Form Title'));

  @override
  Widget body() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Form(
        key: _formKey,
        // Validate on interaction — not on every keystroke
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: AppSpacing.lg),
            // Always use AppTextField — never raw TextField or TextFormField
            AppTextField(
              controller: _fieldOneController,
              label: 'Field One',
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              validator: validateRequired,   // validators from app/utils/ only
            ),
            SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _fieldTwoController,
              label: 'Field Two',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              validator: validateEmail,      // validators from app/utils/ only
              onSubmitted: (_) => _onSubmitPressed(),
            ),
            SizedBox(height: AppSpacing.xl),
            // Always use AppButton — never raw ElevatedButton
            AppButton(
              label: 'Submit',
              onPressed: _onSubmitPressed,
            ),
          ],
        ),
      ),
    );
  }
}

// * ---------------------------- Actions ----------------------------
extension _Actions on _FeatureFormPageState {
  Future<void> _onSubmitPressed() async {
    // Validate form before calling ViewModel
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Use tryLoad — shows global loading overlay + handles errors automatically
    final success = await tryLoad(
      context,
      () => context.read<FeatureNameViewModel>().submit(
        fieldOne: _fieldOneController.text,
        fieldTwo: _fieldTwoController.text,
      ),
    );

    if ((success ?? false) && mounted) {
      context.goNamed(RouterName.someRoute.value);
    }
  }
}
```

---

## Form Rules

| Rule | Correct | Wrong |
|---|---|---|
| Text input | `AppTextField` | `TextField`, `TextFormField` |
| Button | `AppButton` | `ElevatedButton`, `TextButton` |
| Validation mode | `AutovalidateMode.onUserInteraction` | `AutovalidateMode.always` |
| Validators | from `app/utils/` | inline lambda |
| Submit call | `tryLoad(context, fn)` | raw `try/catch` |
| Controller cleanup | `dispose()` override | no dispose |
| Spacing | `AppSpacing.md` | `SizedBox(height: 16)` |

---

## Common Validators (from `app/utils/util.dart`)

```dart
validateRequired(value)   // must not be empty
validateEmail(value)      // must be valid email format
validatePhone(value)      // must be valid phone number
validatePassword(value)   // meets password policy
```

---

## ViewModel Submit Pattern

```dart
// In ViewModel
Future<bool> submit({required String fieldOne, required String fieldTwo}) async {
  final response = await FeatureNameRepository().createItem(
    fieldOne: fieldOne,
    fieldTwo: fieldTwo,
  );

  if (response.data is FeatureModel) {
    notifyListeners();
    return true;
  }

  notifyListeners();
  checkError(response);
  return false;
}
```
