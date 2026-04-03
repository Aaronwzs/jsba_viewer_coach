# Feedback & Bugs Page Enhancement Design

**Date:** 2026-04-04
**Status:** Approved

## Overview

Enhance the "Report a Bug" and "Send Feedback" bottom sheet forms with a modern, intuitive section card layout. Each form field is wrapped in a styled card with an icon, bold title, and helper text above the input — replacing the plain `labelText`/`hintText` approach.

## Current State

- Both forms use basic `TextFormField` with `labelText` and `hintText`
- No visual grouping or hierarchy between fields
- Forms are functional but lack polish and visual appeal
- Data model and Firebase service are working correctly — no changes needed there

## Design Decisions

### Approach: Inline Section Cards

Each field is wrapped in a `_FormSectionCard` widget that provides:
- Icon in a tinted circular container (left-aligned)
- Bold title text next to the icon
- Helper/subtitle text below the title
- Input field below the title row with subtle styling
- Card container: white background, 12px border radius, soft shadow

### Why This Approach

- Clean, scannable, modern feel
- Works well within bottom sheet constraints
- Easy to implement with existing Flutter patterns
- No changes to data model or service layer needed

## Visual Structure

### Section Card Anatomy

```
┌──────────────────────────────────────┐
│  ┌───┐                               │
│  │ 🐛│  Bug Title                    │  ← Icon + Title row
│  └───┘  Give a short descriptive name│  ← Helper text
│                                      │
│  ┌──────────────────────────────────┐│
│  │ App crashes when opening...      ││  ← TextFormField
│  └──────────────────────────────────┘│
└──────────────────────────────────────┘
```

### Card Styling Constants

| Property | Value |
|----------|-------|
| Background | `Colors.white` |
| Border radius | `12px` |
| Shadow color | `Colors.black.withValues(alpha: 0.06)` |
| Shadow blur | `8` |
| Shadow offset | `Offset(0, 2)` |
| Icon container size | `40x40` |
| Icon container border radius | `20px` (circle) |
| Icon tint background | `color.withValues(alpha: 0.1)` |
| Card padding | `16px` |
| Spacing between cards | `16px` |

### Typography

| Element | Size | Weight | Color |
|---------|------|--------|-------|
| Section title | 15px | `FontWeight.w600` | `Colors.black87` |
| Helper text | 12px | `FontWeight.normal` | `Colors.grey[600]` |
| Input text | 14px | `FontWeight.normal` | `Colors.black87` |

## Bug Report Form Sections

| # | Section | Icon | Field | Lines | Required |
|---|---------|------|-------|-------|----------|
| 1 | Bug Title | `Icons.bug_report_outlined` | `title` | 1 | Yes |
| 2 | Steps to Reproduce | `Icons.format_list_numbered` | `stepsToReproduce` | 3 | Yes |
| 3 | Expected Behavior | `Icons.check_circle_outline` | `expectedBehavior` | 2 | Yes |
| 4 | Actual Behavior | `Icons.error_outline` | `actualBehavior` | 2 | Yes |
| 5 | Screenshot (Optional) | `Icons.add_a_photo_outlined` | `_screenshot` (File) | N/A | No |

### Color Theme (Bug Form)

- Icon color: `Colors.red`
- Icon container tint: `Colors.red.withValues(alpha: 0.1)`
- Submit button: `AppTheme.primaryColor` (green)

## Feedback Form Sections

| # | Section | Icon | Field | Lines | Required |
|---|---------|------|-------|-------|----------|
| 1 | Category | `Icons.category_outlined` | `_selectedCategory` (ChoiceChip) | N/A | Yes |
| 2 | Feedback Title | `Icons.title` | `title` | 1 | Yes |
| 3 | Description | `Icons.description_outlined` | `description` | 5 | Yes |

### Color Theme (Feedback Form)

- Icon color: `AppTheme.primaryColor` (green)
- Icon container tint: `AppTheme.primaryColor.withValues(alpha: 0.1)`
- Submit button: `AppTheme.primaryColor` (green)

## Files to Modify

### 1. `lib/app/view/shared/widgets/bug_report_form.dart`

**Changes:**
- Add `_FormSectionCard` widget class (private to the file or shared)
- Replace each `TextFormField` with a `_FormSectionCard` wrapping the field
- Update screenshot picker to use the same card style
- Keep all existing logic: validation, submission, device info, error handling

### 2. `lib/app/view/shared/widgets/feedback_form.dart`

**Changes:**
- Add `_FormSectionCard` widget class (private to the file or shared)
- Replace category selection, title, and description fields with section cards
- Keep all existing logic: validation, submission, device info, error handling

### 3. No changes needed

- `feedback_report_page.dart` — Selection page stays the same
- `feedback_model.dart` — Data model stays the same
- `feedback_service.dart` — Service stays the same
- `device_info_helper.dart` — Utility stays the same

## Firebase Collection Structure

```
feedback/ (collection)
  └── {auto-generated-doc-id}/ (document)
        ├── type: "bug" | "feedback"
        ├── category: "general" | "suggestion" | "complaint" | "praise" | null
        ├── title: string (required)
        ├── description: string (required)
        ├── stepsToReproduce: string | null
        ├── expectedBehavior: string | null
        ├── actualBehavior: string | null
        ├── screenshotUrl: string | null
        ├── userId: string (required)
        ├── deviceInfo: {
        │     model: string,
        │     osVersion: string,
        │     appVersion: string
        │   }
        ├── createdAt: Timestamp
        └── status: "pending" | "reviewed" | "resolved"
```

### Write Flow (unchanged)

1. User fills out form and taps submit
2. Form validates via `_formKey.currentState!.validate()`
3. `EasyLoading.show(status: 'Submitting...')`
4. Collect device info via `DeviceInfoHelper.getDeviceInfo()`
5. Create `FeedbackModel` with form data
6. Call `FeedbackService().submitFeedback(feedback)`
7. Firestore writes to `feedback` collection via `.add()`
8. Show success/error SnackBar
9. Call `onSuccess()` to close bottom sheet

## `_FormSectionCard` Widget Specification

```dart
class FormSectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String helperText;
  final Widget child;

  const FormSectionCard({
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
                    Text(title, style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    )),
                    const SizedBox(height: 2),
                    Text(helperText, style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    )),
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

### Input Field Styling Inside Cards

When used inside a `FormSectionCard`, the `TextFormField` should have:
- No `labelText` (title is in the card header)
- `hintText` kept for placeholder guidance
- `border: OutlineInputBorder()` with light gray border
- `contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)`
- `filled: true, fillColor: Color(0xFFF9FAFB)` (very light gray background)

## Input Validation Messages

| Field | Validation Rule | Error Message |
|-------|----------------|---------------|
| Title | Not empty | "Please enter a title" |
| Steps to Reproduce | Not empty | "Please describe the steps" |
| Expected Behavior | Not empty | "Please describe expected behavior" |
| Actual Behavior | Not empty | "Please describe what happened" |
| Description (Feedback) | Not empty | "Please enter a description" |

## Implementation Notes

- The `_FormSectionCard` can be extracted to a shared file if desired, but keeping it private to each form file is simpler and avoids cross-file dependencies
- All existing submit logic, error handling, and device info collection remain unchanged
- The screenshot picker card should use the same card structure but with the image preview replacing the input field
- Category selection in the feedback form should be placed inside a card with the icon/title header, with ChoiceChips as the child widget
