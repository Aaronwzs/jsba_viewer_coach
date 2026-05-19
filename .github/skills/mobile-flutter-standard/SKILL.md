---
name: mobile-flutter-standard
description: "Use when creating, reviewing, or modifying Flutter code in this project. Triggers on: new screen, new page, new ViewModel, new repository, new service, new model, new widget, Flutter feature, Flutter coding standard, Flutter MVVM, add route, register provider."
---

# Flutter Coding Standards

This project follows a strict **MVVM architecture with Provider** for state management. All new code must follow these patterns exactly. Refer to the templates below for each layer.

---

## MANDATORY Request Process

Follow this process for EVERY coding task without exception:

1. **Plan** — Generate a complete implementation plan covering all layers needed
2. **Present** — Show the plan in numbered, actionable steps
3. **Request Approval** — Ask "Do you want me to proceed?" and STOP
4. **Wait** — Do NOT write any code until the user explicitly approves
5. **Execute** — Implement only after written approval

### Phase Plan Structure

Break every feature into three phases. Complete and confirm each phase before starting the next.

**Phase 1 — Model + Service + Repository**
- Define `{Feature}Model` with `fromJson`/`toJson`
- Define `{Feature}Services` extending `BaseServices`
- Define `{Feature}Repository` processing `MyResponse`
- Confirm: `dart analyze` passes with zero errors

**Phase 2 — ViewModel**
- Define `{Feature}ViewModel` extending `BaseViewModel`
- Implement all data-fetch and mutation methods
- Expose minimum required state — no raw model exposure
- Confirm: `dart analyze` passes with zero errors

**Phase 3 — Screen + Widgets**
- Build `{Feature}Page` extending `BaseStatefulPage`
- Override `body()` only — never `build()`
- Use only `AppTextField`, `AppButton`, and components from `app/widgets/` — never raw `TextField` or `ElevatedButton`
- Wire loading, empty, and error states
- Final check: `dart analyze` and `flutter test` both pass

---

## Architecture Overview

```
View (UI)
  └── calls → ViewModel (via Provider)
        └── calls → Repository (business logic)
              └── calls → Service (raw API)
                    └── returns → MyResponse
Model (data classes, shared across all layers)
```

## Layer Rules — Quick Reference

| Layer | Extends | File location | Naming |
|---|---|---|---|
| Page | `BaseStatefulPage` | `lib/app/view/` | `*_page.dart` |
| State | `BaseStatefulState<PageName>` | same file as Page | `_*PageState` |
| ViewModel | `BaseViewModel` | `lib/app/viewmodel/` | `*_view_model.dart` |
| Repository | (none) | `lib/app/repository/` | `*_repository.dart` |
| Service | `BaseServices` | `lib/app/service/` | `*_services.dart` |
| Model | (none) | `lib/app/model/` | `*_model.dart` |
| Widget | `StatelessWidget` / `StatefulWidget` | `lib/app/widgets/` | `*_widget.dart` |

---

## 1. Creating a New Screen

See full template: [screen template](./references/screen_template.md)

**Rules:**
- Page class extends `BaseStatefulPage`, State extends `BaseStatefulState<PageName>`
- Always override `body()` — required
- Override `appbar()`, `floatingActionButton()`, `bottomNavigationBar()` only if needed (they return `null` by default)
- Do NOT override `build()` — the base class owns the `Scaffold` structure
- Extract all action methods (button handlers, API calls) into a **private extension** on the State class at the bottom of the file
- Use `context.read<VM>()` inside actions (no rebuild needed)
- Use `context.select((VM vm) => vm.field)` to watch a specific field
- Use `context.watch<VM>()` only when the full VM needs to trigger rebuilds
- Use `Consumer<VM>` builder pattern for scoped rebuilds within a subtree
- Use `tryLoad(context, fn)` to call ViewModel methods that should show a loading indicator
- Use `tryCatch(context, fn)` to call ViewModel methods silently (no loading spinner)
- After `tryLoad`/`tryCatch`, always check `mounted` before navigating
- Always `dispose()` every `TextEditingController`, `ScrollController`, or `AnimationController` in `dispose()`
- Never call `context.watch` or `context.select` inside `initState` — use `WidgetsBinding.instance.addPostFrameCallback` to trigger data-fetch after first build

**After creating a screen:**
1. Add a route in `lib/app/assets/router/app_router.dart`
2. Add the route name to the `RouterName` enum
3. Register the ViewModel in `providerAssets()` in `lib/app/assets/app_options.dart`
4. Export the screen from `lib/app/assets/exporter/importer_app_screens.dart`

---

## 2. Creating a New ViewModel

See full template: [viewmodel template](./references/viewmodel_template.md)

**Rules:**
- Extends `BaseViewModel` (which extends `ChangeNotifier`)
- Private backing fields with public getters: `UserModel? get user => _user;`
- Set `_isLoading = true` and call `notifyListeners()` at the START of a fetch; reset at the end
- Call `notifyListeners()` before `checkError()` to ensure UI updates before exception is thrown
- Call `checkError(response)` after processing — it throws `NormalErrorException` or `UrgentErrorException`
- Do NOT show dialogs or navigate inside a ViewModel — that belongs in the View layer
- One ViewModel can serve multiple pages

---

## 3. Creating a New Repository

See full template: [repository and service template](./references/repository_service_template.md)

**Rules:**
- Plain Dart class, no base class required
- Instantiates its own `Services` class: `final XyzServices _xyzServices = XyzServices();`
- Processes `MyResponse` from the Service layer: checks `response.data` type, maps to domain models
- Returns `MyResponse.complete(model)` on success, passes the original `response` on error
- Owns all business logic: deciding whether to use cache vs live data, combining multiple sources

---

## 4. Creating a New Service

See full template: [repository and service template](./references/repository_service_template.md)

**Rules:**
- Extends `BaseServices`
- Only makes raw API calls using `callAPI(HttpRequestType.method, path, postBody: body)`
- Use `queryParameters:` for GET query params — never append them to the URL string manually
- No business logic — just path, method, and body
- Uses `apiUrl` getter for the base URL (from `BaseServices`)
- Use `noAuth: true` only for public endpoints that don't require authentication

---

## 5. Creating a New Model

See full template: [model template](./references/model_template.md)

**Rules:**
- Always implement `fromJson(Map<String, dynamic> json)` named constructor
- Always implement `toJson()` returning `Map<String, dynamic>`
- Use `DynamicParsing(json['field']).parseString()` / `.parseBool()` for safe JSON parsing — never cast directly
- Use `int.tryParse(json['field'].toString()) ?? 0` for int fields that may come as strings
- Use string-backed enums with `fromJson` factory for domain enum fields
- Export the new model from the appropriate barrel file in `lib/app/assets/exporter/`

---

## 6. Imports — Barrel File Rules

Always import using the barrel exporter files, never direct file imports:

| Barrel file | Contains |
|---|---|
| `importer_app_general.dart` | Flutter SDK, shared utilities, theme, constants |
| `importer_app_structural_component.dart` | All MVVM layers: models, repositories, services, viewmodels, Provider |
| `importer_app_screens.dart` | All page/screen classes |
| `importer_routing.dart` | GoRouter, RouterName, route helpers |

When you add a new model, repository, service, viewmodel, or screen — **export it from the correct barrel file**.
**Never** import these files directly — always go through the barrel.

---

## 7. Routing

- All routes are defined in `lib/app/assets/router/app_router.dart` using `GoRouter`
- Route paths are in the private `_AppRouterPath` enum
- Route names are in the `RouterName` enum
- Navigate using `context.goNamed(RouterName.xxx.value)` or `context.go()` — never `Navigator.push`
- Pass only primitive IDs in route parameters — fetch full data in the target screen's ViewModel
- For deep links, use path parameters (e.g. `/deeplink/:deeplinkId`)
- Auth guard lives in the GoRouter `redirect` callback — never duplicate in individual screens

---

## 8. Provider Registration

- All ViewModels must be registered as `ChangeNotifierProvider` in `providerAssets()` in `lib/app/assets/app_options.dart`
- Providers are registered at the root level (`MultiProvider` in `app.dart`) so they are accessible everywhere
- Never call `notifyListeners()` inside a widget `build()` method — causes infinite rebuild loops

---

## 9. Error Handling

| Exception | Meaning | Handling |
|---|---|---|
| `UrgentErrorException` | Session expired / 401/403 | Shows dialog + triggers logout |
| `NormalErrorException` | API business error | Shows error dialog |
| General exception | Unexpected error | Shows generic error dialog |

- Throw from ViewModel using `checkError(response)` or explicitly via `throw NormalErrorException('message')`
- Catch in View using `tryLoad` or `tryCatch` — never wrap ViewModel calls in raw `try/catch` in the UI
- Never call `checkError` directly in a View — only in ViewModels

---

## 10. Environment & Flavors

- Two environments: `staging`, `production`
- App flavor set at build time via `appFlavor`
- Use `EnvironmentType.fromAppFlavor(appFlavor)` to get current environment
- Environment-specific config lives in `env/` folder and accessed via `EnvValues`
- Never commit `env/*.json` files with real credentials to git — inject via CI/CD

---

## 11. Forms

See full template: [forms template](./references/forms_template.md)

- Always use `AppTextField` — never raw `TextField` or `TextFormField` outside App-wrappers
- Always use `AppButton` — never raw `ElevatedButton`, `TextButton`, or `OutlinedButton`
- Check `app/widgets/` and `adaptive_widgets_flutter` before building any UI component from scratch
- Use `GlobalKey<FormState>` for form validation
- Use `AutovalidateMode.onUserInteraction` — not `always`
- Use validators from `app/utils/` — never write validation logic inline
- Always `dispose()` every `TextEditingController` in `dispose()`
- Use `tryLoad` for form submit — shows global loader and handles errors automatically

---

## 12. UI & Styling

- **Never hardcode colours** — always use `context.theme.colorScheme.*` or `context.theme.appColors.*`
- **Never hardcode font sizes** — always use `context.theme.textTheme.*`
- **Never use raw pixel spacing literals** — use `AppSpacing.xs / sm / md / lg / xl / xxl` constants
- Use `tabletMode()` extension on `EdgeInsets` for tablet-aware padding
- Before building any new component, check `adaptive_widgets_flutter` package first
- When implementing from Figma: map every element to an existing widget before writing code; flag unmatched elements as `⚠️ MISSING COMPONENT`

---

## 13. Naming Conventions

| Concept | Format | Example |
|---|---|---|
| Files | `{name}_{type}.dart` | `user_model.dart`, `login_page.dart` |
| Classes | PascalCase | `UserModel`, `LoginPage` |
| ViewModel | PascalCase + `ViewModel` | `ProductViewModel` |
| Services | PascalCase + `Services` | `ProductServices` |
| Repository | PascalCase + `Repository` | `ProductRepository` |
| Variables / params | camelCase | `userId`, `accessToken` |
| Constants class | `abstract final class` PascalCase | `AppRoutes`, `AppSpacing` |
| Enum | PascalCase, values camelCase | `UserStatus.active` |
| Assets | snake_case | `ic_profile.svg`, `img_banner.png` |
| Route paths | kebab-case | `/product-list/:id` |
| ARB keys | camelCase | `loginTitle`, `errorEmailInvalid` |

---

## 14. Internationalisation (i18n)

All user-visible strings **must** be defined in the ARB translation files and accessed via `S.current.keyName`. Hardcoding display strings directly in Dart files is forbidden.

**Translation files location:**
```
lib/l10n/intl_en.arb    ← primary (English)
lib/l10n/intl_es.arb    ← secondary (add matching key for every new entry)
lib/generated/l10n.dart ← generated S class — DO NOT edit manually
```

**Workflow — adding a new string:**
1. Add the key and value to `lib/l10n/intl_en.arb`:
   ```json
   "loginButtonLabel": "Sign In",
   "@loginButtonLabel": {
     "description": "Label on the main login button"
   }
   ```
2. Add the **same key** to every other ARB file (`intl_es.arb`, etc.) with the translated value
3. Run `flutter gen-l10n` (or rebuild — Flutter Intl auto-generates on save if the plugin is active)
4. Use `S.current.loginButtonLabel` in code

**ARB key naming:**
- camelCase — `loginButtonLabel`, `errorEmailInvalid`, `profilePageTitle`
- Suffix with the context — `*Title`, `*Label`, `*Hint`, `*Message`, `*Button`
- Be descriptive and unique — never reuse a key for semantically different strings

**What counts as a display string (must go in ARB):**
- Any `Text(...)` value visible to the user
- Any `title:`, `label:`, `hint:`, `hintText:`, `labelText:`, `tooltip:`, `message:`, `errorText:`, `helperText:`, `text:` parameter passed to a widget
- Error messages, dialog titles, button labels, placeholder text, snackbar messages
- `AppTextField` label/hint, `AppButton` text

**What does NOT need to be in ARB:**
- Route path strings: `'/home'`, `'/user/:id'`
- `Key('...')` widget key names
- Log messages, debug strings, assert messages
- Technical strings that are never rendered as UI text
- `dart:` / `package:` import paths

**Usage pattern:**
```dart
// ✅ Correct
Text(S.current.loginButtonLabel)
AppTextField(label: S.current.emailLabel, hint: S.current.emailHint)
AppButton(text: S.current.submitButton, onPressed: _submit)

// ❌ Wrong — hardcoded display strings
Text('Sign In')
AppTextField(label: 'Email', hint: 'Enter your email')
AppButton(text: 'Submit', onPressed: _submit)
```

---

## 15. Quality Gates

Run these before every PR:

```bash
dart analyze                              # zero warnings, zero errors
dart format --set-exit-if-changed .
flutter test                              # all tests pass
```

---

## CRITICAL REMINDERS

These are the most common mistakes. Violating any of these will cause bugs or failed code reviews.

1. **Never extend `StatefulWidget` directly for screens.** All screens must extend `BaseStatefulPage` and override `body()`. This ensures jailbreak detection, force update, and maintenance mode are applied everywhere.
2. **Never put business logic or API calls in a widget.** All API calls go through `tryLoad`/`tryCatch` calling a ViewModel method.
3. **Never call `context.watch` or `context.select` inside `initState`.** Use `WidgetsBinding.instance.addPostFrameCallback` to trigger data fetches after the first build.
4. **Never create a new `Dio()` instance in a service.** Always use the `dio` getter from `BaseServices`.
5. **Never use `Navigator.push` or `Navigator.pushNamed`.** Always use `context.go()` or `context.push()` from `go_router`.
6. **Never call `notifyListeners()` from inside a `build()` method.** Only call it after state has been updated in an async handler.
7. **Always `dispose()` every controller.** `TextEditingController`, `ScrollController`, `AnimationController`, `PagingController` — all must be disposed.
8. **Always export new screens to `importer_app_screens.dart` and register new ViewModels in `providerAssets()`.** Missing either will make them inaccessible.
9. **Always use `AppTextField` and `AppButton` — never raw `TextField` or `ElevatedButton`.**
10. **Never access `SharedPreferences` directly.** Always use `SharedPreferenceHandler()`.
11. **Never write date formatting, validation, or parsing logic inline.** All utilities come from `app/utils/`.
12. **Always run `dart analyze` before raising a PR.** Zero warnings, zero errors.
13. **Never commit `env/*.json`, `key.properties`, `.p12`, or `.mobileprovision` to git.**
14. **Never hardcode display strings.** Every user-visible string — labels, titles, hints, button text, error messages — must be defined in `lib/l10n/intl_en.arb` (and all other ARB files) and accessed via `S.current.keyName`. Use `flutter gen-l10n` after adding new keys.
