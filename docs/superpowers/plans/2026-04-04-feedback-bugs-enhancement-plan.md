# Feedback & Bugs Form Enhancement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace plain labelText/hintText form fields with modern section cards featuring icons, titles, and helper text in both the Bug Report and Feedback forms.

**Architecture:** Extract a reusable `FormSectionCard` widget, then refactor both form widgets to wrap each input field in a section card. No changes to data model, service layer, or navigation.

**Tech Stack:** Flutter, Dart, Material 3, image_picker, flutter_easyloading

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `lib/app/view/shared/widgets/form_section_card.dart` | **Create** | Reusable `FormSectionCard` widget with icon, title, helper text, and child input |
| `lib/app/view/shared/widgets/bug_report_form.dart` | **Modify** | Replace plain TextFields with FormSectionCard wrappers, update input styling |
| `lib/app/view/shared/widgets/feedback_form.dart` | **Modify** | Replace plain TextFields with FormSectionCard wrappers, update input styling |

No changes needed to: `feedback_report_page.dart`, `feedback_model.dart`, `feedback_service.dart`, `device_info_helper.dart`.

---

### Task 1: Create FormSectionCard Widget

**Files:**
- Create: `lib/app/view/shared/widgets/form_section_card.dart`

- [ ] **Step 1: Create the FormSectionCard widget file**

Create `lib/app/view/shared/widgets/form_section_card.dart`:

```dart
import 'package:flutter/material.dart';

class FormSectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String helperText;
  final Widget child;

  const FormSectionCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.helperText,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      helperText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify no compilation errors**

Run: `flutter analyze lib/app/view/shared/widgets/form_section_card.dart`
Expected: No issues

- [ ] **Step 3: Commit**

```bash
git add lib/app/view/shared/widgets/form_section_card.dart
git commit -m "feat: add FormSectionCard reusable widget for enhanced forms"
```

---

### Task 2: Refactor Bug Report Form

**Files:**
- Modify: `lib/app/view/shared/widgets/bug_report_form.dart`

- [ ] **Step 1: Add import for FormSectionCard**

Add at the top of the file:
```dart
import 'package:jsba_app/app/view/shared/widgets/form_section_card.dart';
```

- [ ] **Step 2: Replace the build method's Column children with section cards**

Replace the entire `build` method body. The new structure wraps each field in a `FormSectionCard`:

```dart
@override
Widget build(BuildContext context) {
  return SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      MediaQuery.of(context).viewInsets.bottom + 20,
    ),
    child: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Report a Bug',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Help us fix issues by providing detailed information',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          FormSectionCard(
            icon: Icons.bug_report_outlined,
            iconColor: Colors.red,
            title: 'Bug Title',
            helperText: 'Give a short, descriptive name for the issue',
            child: TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'e.g., App crashes when opening settings',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Please enter a title' : null,
            ),
          ),
          const SizedBox(height: 16),
          FormSectionCard(
            icon: Icons.format_list_numbered,
            iconColor: Colors.red,
            title: 'Steps to Reproduce',
            helperText: 'Tell us exactly how to trigger this bug',
            child: TextFormField(
              controller: _stepsController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '1. Open the app\n2. Go to...\n3. Tap on...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                alignLabelWithHint: true,
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Please describe the steps'
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          FormSectionCard(
            icon: Icons.check_circle_outline,
            iconColor: Colors.red,
            title: 'Expected Behavior',
            helperText: 'What should have happened?',
            child: TextFormField(
              controller: _expectedController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g., The settings page should open normally',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                alignLabelWithHint: true,
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Please describe expected behavior'
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          FormSectionCard(
            icon: Icons.error_outline,
            iconColor: Colors.red,
            title: 'Actual Behavior',
            helperText: 'What actually happened instead?',
            child: TextFormField(
              controller: _actualController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g., The app froze and showed a black screen',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                alignLabelWithHint: true,
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Please describe what happened'
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          FormSectionCard(
            icon: Icons.add_a_photo_outlined,
            iconColor: Colors.red,
            title: 'Screenshot',
            helperText: 'Attach a screenshot to help us understand (optional)',
            child: GestureDetector(
              onTap: _pickScreenshot,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFFF9FAFB),
                ),
                child: _screenshot != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _screenshot!,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setState(() => _screenshot = null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 32,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to add a screenshot',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Submit Bug Report'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 3: Verify imports are correct**

Confirm the `FormSectionCard` import is present. Remove any imports that became unused from the replacement. The following should remain:
- `dart:io`
- `flutter/material.dart`
- `image_picker`
- `app_theme`
- `feedback_model`
- `feedback_service`
- `device_info_helper`
- `flutter_easyloading`
- `form_section_card.dart` (new)

- [ ] **Step 4: Verify no compilation errors**

Run: `flutter analyze lib/app/view/shared/widgets/bug_report_form.dart`
Expected: No issues

- [ ] **Step 5: Commit**

```bash
git add lib/app/view/shared/widgets/bug_report_form.dart
git commit -m "refactor: enhance bug report form with section cards and modern styling"
```

---

### Task 3: Refactor Feedback Form

**Files:**
- Modify: `lib/app/view/shared/widgets/feedback_form.dart`

- [ ] **Step 1: Read the current file to verify existing structure**

Read `lib/app/view/shared/widgets/feedback_form.dart` to confirm:
- Controller names match (`_titleController`, `_descriptionController`)
- `_getCategoryLabel(category)` method exists (it does — used by ChoiceChips)
- `_selectedCategory` state variable exists

- [ ] **Step 2: Add import for FormSectionCard**

Add at the top of the file:
```dart
import 'package:jsba_app/app/view/shared/widgets/form_section_card.dart';
```

- [ ] **Step 2: Replace the build method's Column children with section cards**

Replace the entire `build` method body:

```dart
@override
Widget build(BuildContext context) {
  return SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      MediaQuery.of(context).viewInsets.bottom + 20,
    ),
    child: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Send Feedback',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Share your thoughts to help us improve',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          FormSectionCard(
            icon: Icons.category_outlined,
            iconColor: AppTheme.primaryColor,
            title: 'Category',
            helperText: 'What type of feedback is this?',
            child: Wrap(
              spacing: 8,
              children: FeedbackCategory.values.map((category) {
                return ChoiceChip(
                  label: Text(_getCategoryLabel(category)),
                  selected: _selectedCategory == category,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = category);
                    }
                  },
                  selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: _selectedCategory == category
                        ? AppTheme.primaryColor
                        : Colors.black87,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          FormSectionCard(
            icon: Icons.title,
            iconColor: AppTheme.primaryColor,
            title: 'Feedback Title',
            helperText: 'A brief summary of your feedback',
            child: TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'e.g., Add dark mode support',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Please enter a title' : null,
            ),
          ),
          const SizedBox(height: 16),
          FormSectionCard(
            icon: Icons.description_outlined,
            iconColor: AppTheme.primaryColor,
            title: 'Description',
            helperText: 'Tell us more about your feedback',
            child: TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Provide details about your suggestion, concern, or compliment...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                alignLabelWithHint: true,
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Please enter a description'
                  : null,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Submit Feedback'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 3: Verify no compilation errors**

Run: `flutter analyze lib/app/view/shared/widgets/feedback_form.dart`
Expected: No issues

- [ ] **Step 5: Commit**

```bash
git add lib/app/view/shared/widgets/bug_report_form.dart
git commit -m "refactor: enhance bug report form with section cards and modern styling"
```

---

### Task 4: Full Analysis and Verification

**Files:**
- All modified files

- [ ] **Step 1: Run full flutter analyze**

Run: `flutter analyze`
Expected: No issues (only pre-existing issues in other files)

- [ ] **Step 2: Verify both forms compile and render correctly**

Run: `flutter build apk --debug` (or `flutter run` on a connected device/emulator)
Expected: Build succeeds, both forms open with section cards visible

- [ ] **Step 3: Final commit if any cleanup needed**

```bash
git status
```
If there are any remaining changes, commit them with an appropriate message.
