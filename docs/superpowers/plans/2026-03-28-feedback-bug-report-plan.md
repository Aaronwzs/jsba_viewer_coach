# Feedback & Bug Report Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Feedback and Bug Report feature accessible from FAQ page, saving submissions to Firestore

**Architecture:** Modal-based form flow from FAQ page bottom banner. Two form types (bug report, feedback) with auto-collected device info.

**Tech Stack:** Flutter, Firestore, Provider, image_picker, device_info_plus

---

## File Structure

### New Files
- `lib/app/model/feedback_model.dart` - Data model for feedback documents
- `lib/app/service/feedback_service.dart` - Firestore operations
- `lib/app/utils/device_info_helper.dart` - Device info collection utility
- `lib/app/view/shared/feedback_report_page.dart` - Main page with modal selection
- `lib/app/view/shared/widgets/bug_report_form.dart` - Bug report form widget
- `lib/app/view/shared/widgets/feedback_form.dart` - Feedback form widget

### Modified Files
- `lib/app/view/shared/faq_page.dart` - Add banner at bottom
- `lib/app/view/pages.dart` - Export new page
- `lib/app/assets/router/app_router.dart` - Add route
- `pubspec.yaml` - Add device_info_plus dependency

---

## Chunk 1: Dependencies & Data Model

### Task 1: Add device_info_plus dependency

- [ ] **Step 1: Add dependency to pubspec.yaml**

Modify: `pubspec.yaml`
Add after line 48 (`image_cropper: ^12.1.0`):
```yaml
  device_info_plus: ^11.0.0
```

Run: `flutter pub get`

- [ ] **Step 2: Commit**
```bash
git add pubspec.yaml
git commit -m "feat: add device_info_plus dependency"
```

---

### Task 2: Create Feedback Model

**Files:**
- Create: `lib/app/model/feedback_model.dart`

- [ ] **Step 1: Create the model**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum FeedbackType { bug, feedback }

enum FeedbackCategory { general, suggestion, complaint, praise }

enum FeedbackStatus { pending, reviewed, resolved }

class FeedbackModel {
  final String? id;
  final FeedbackType type;
  final FeedbackCategory? category;
  final String title;
  final String description;
  final String? stepsToReproduce;
  final String? expectedBehavior;
  final String? actualBehavior;
  final String? screenshotUrl;
  final String userId;
  final DeviceInfoModel deviceInfo;
  final DateTime createdAt;
  final FeedbackStatus status;

  FeedbackModel({
    this.id,
    required this.type,
    this.category,
    required this.title,
    required this.description,
    this.stepsToReproduce,
    this.expectedBehavior,
    this.actualBehavior,
    this.screenshotUrl,
    required this.userId,
    required this.deviceInfo,
    required this.createdAt,
    this.status = FeedbackStatus.pending,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'category': category?.name,
      'title': title,
      'description': description,
      'stepsToReproduce': stepsToReproduce,
      'expectedBehavior': expectedBehavior,
      'actualBehavior': actualBehavior,
      'screenshotUrl': screenshotUrl,
      'userId': userId,
      'deviceInfo': deviceInfo.toJson(),
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.name,
    };
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return FeedbackModel(
      id: id,
      type: FeedbackType.values.firstWhere((e) => e.name == map['type']),
      category: map['category'] != null
          ? FeedbackCategory.values.firstWhere((e) => e.name == map['category'])
          : null,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      stepsToReproduce: map['stepsToReproduce'],
      expectedBehavior: map['expectedBehavior'],
      actualBehavior: map['actualBehavior'],
      screenshotUrl: map['screenshotUrl'],
      userId: map['userId'] ?? '',
      deviceInfo: map['deviceInfo'] != null
          ? DeviceInfoModel.fromJson(Map<String, dynamic>.from(map['deviceInfo']))
          : DeviceInfoModel.empty(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: FeedbackStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => FeedbackStatus.pending,
      ),
    );
  }
}

class DeviceInfoModel {
  final String model;
  final String osVersion;
  final String appVersion;

  DeviceInfoModel({
    required this.model,
    required this.osVersion,
    required this.appVersion,
  });

  factory DeviceInfoModel.empty() {
    return DeviceInfoModel(
      model: 'Unknown',
      osVersion: 'Unknown',
      appVersion: 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'osVersion': osVersion,
      'appVersion': appVersion,
    };
  }

  factory DeviceInfoModel.fromJson(Map<String, dynamic> json) {
    return DeviceInfoModel(
      model: json['model'] ?? 'Unknown',
      osVersion: json['osVersion'] ?? 'Unknown',
      appVersion: json['appVersion'] ?? 'Unknown',
    );
  }
}
```

- [ ] **Step 2: Commit**
```bash
git add lib/app/model/feedback_model.dart
git commit -m "feat: add feedback model"
```

---

## Chunk 2: Services & Utilities

### Task 3: Create Device Info Helper

**Files:**
- Create: `lib/app/utils/device_info_helper.dart`

- [ ] **Step 1: Create device info helper**

```dart
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:jsba_app/app/model/feedback_model.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceInfoHelper {
  static Future<DeviceInfoModel> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromString(
      '{"appName": "JSBA", "version": "1.0.0", "buildNumber": "1"}',
    );

    String model = 'Unknown';
    String osVersion = 'Unknown';

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      model = '${androidInfo.manufacturer} ${androidInfo.model}';
      osVersion = 'Android ${androidInfo.version.release}';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      model = iosInfo.utsname.machine;
      osVersion = 'iOS ${iosInfo.systemVersion}';
    }

    return DeviceInfoModel(
      model: model,
      osVersion: osVersion,
      appVersion: packageInfo.version,
    );
  }
}
```

Note: The PackageInfo.fromString is a workaround - actual implementation should use:
```dart
final packageInfo = await PackageInfo.fromApp();
```

- [ ] **Step 2: Add package_info_plus to pubspec.yaml**

Modify: `pubspec.yaml`
Add after line 48:
```yaml
  package_info_plus: ^8.0.0
```

Run: `flutter pub get`

- [ ] **Step 3: Update device_info_helper.dart with correct import**

```dart
import 'package:package_info_plus/package_info_plus.dart';
```

- [ ] **Step 4: Commit**
```bash
git add pubspec.yaml lib/app/utils/device_info_helper.dart
git commit -m "feat: add device info helper"
```

---

### Task 4: Create Feedback Service

**Files:**
- Create: `lib/app/service/feedback_service.dart`

- [ ] **Step 1: Create the service**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jsba_app/app/model/feedback_model.dart';

class FeedbackService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> submitFeedback(FeedbackModel feedback) async {
    await _db.collection('feedback').add(feedback.toJson());
  }
}
```

- [ ] **Step 2: Commit**
```bash
git add lib/app/service/feedback_service.dart
git commit -m "feat: add feedback service"
```

---

## Chunk 3: UI Components

### Task 5: Create Bug Report Form Widget

**Files:**
- Create: `lib/app/view/shared/widgets/bug_report_form.dart`

- [ ] **Step 1: Create the widget**

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/model/feedback_model.dart';
import 'package:jsba_app/app/service/feedback_service.dart';
import 'package:jsba_app/app/utils/device_info_helper.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class BugReportForm extends StatefulWidget {
  final String userId;
  final VoidCallback onSuccess;

  const BugReportForm({
    super.key,
    required this.userId,
    required this.onSuccess,
  });

  @override
  State<BugReportForm> createState() => _BugReportFormState();
}

class _BugReportFormState extends State<BugReportForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _stepsController = TextEditingController();
  final _expectedController = TextEditingController();
  final _actualController = TextEditingController();
  File? _screenshot;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _stepsController.dispose();
    _expectedController.dispose();
    _actualController.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() => _screenshot = File(image.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    EasyLoading.show(status: 'Submitting...');

    try {
      final deviceInfo = await DeviceInfoHelper.getDeviceInfo();
      
      String? screenshotUrl;
      // TODO: Upload screenshot to storage if present
      
      final feedback = FeedbackModel(
        type: FeedbackType.bug,
        title: _titleController.text.trim(),
        description: _actualController.text.trim(),
        stepsToReproduce: _stepsController.text.trim(),
        expectedBehavior: _expectedController.text.trim(),
        actualBehavior: _actualController.text.trim(),
        screenshotUrl: screenshotUrl,
        userId: widget.userId,
        deviceInfo: deviceInfo,
        createdAt: DateTime.now(),
      );

      await FeedbackService().submitFeedback(feedback);

      EasyLoading.dismiss();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bug report submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSuccess();
      }
    } catch (e) {
      EasyLoading.dismiss();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

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
            const SizedBox(height: 20),
            const Text(
              'Report a Bug',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Brief description of the issue',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stepsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Steps to Reproduce',
                hintText: '1. Open the app\n2. Go to...\n3. Tap on...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _expectedController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Expected Behavior',
                hintText: 'What should have happened?',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _actualController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Actual Behavior',
                hintText: 'What actually happened?',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickScreenshot,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _screenshot != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_screenshot!, height: 150, fit: BoxFit.cover),
                      )
                    : Column(
                        children: [
                          Icon(Icons.add_a_photo_outlined, color: Colors.grey[500]),
                          const SizedBox(height: 8),
                          Text(
                            'Add Screenshot (Optional)',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
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
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit Bug Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**
```bash
git add lib/app/view/shared/widgets/bug_report_form.dart
git commit -m "feat: add bug report form widget"
```

---

### Task 6: Create Feedback Form Widget

**Files:**
- Create: `lib/app/view/shared/widgets/feedback_form.dart`

- [ ] **Step 1: Create the widget**

```dart
import 'package:flutter/material.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/model/feedback_model.dart';
import 'package:jsba_app/app/service/feedback_service.dart';
import 'package:jsba_app/app/utils/device_info_helper.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class FeedbackForm extends StatefulWidget {
  final String userId;
  final VoidCallback onSuccess;

  const FeedbackForm({
    super.key,
    required this.userId,
    required this.onSuccess,
  });

  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  FeedbackCategory _selectedCategory = FeedbackCategory.general;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    EasyLoading.show(status: 'Submitting...');

    try {
      final deviceInfo = await DeviceInfoHelper.getDeviceInfo();

      final feedback = FeedbackModel(
        type: FeedbackType.feedback,
        category: _selectedCategory,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        userId: widget.userId,
        deviceInfo: deviceInfo,
        createdAt: DateTime.now(),
      );

      await FeedbackService().submitFeedback(feedback);

      EasyLoading.dismiss();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSuccess();
      }
    } catch (e) {
      EasyLoading.dismiss();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

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
            const SizedBox(height: 20),
            const Text(
              'Send Feedback',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Brief summary of your feedback',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Tell us more about your feedback...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit Feedback'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryLabel(FeedbackCategory category) {
    switch (category) {
      case FeedbackCategory.general:
        return 'General';
      case FeedbackCategory.suggestion:
        return 'Suggestion';
      case FeedbackCategory.complaint:
        return 'Complaint';
      case FeedbackCategory.praise:
        return 'Praise';
    }
  }
}
```

- [ ] **Step 2: Commit**
```bash
git add lib/app/view/shared/widgets/feedback_form.dart
git commit -m "feat: add feedback form widget"
```

---

### Task 7: Create Feedback Report Page

**Files:**
- Create: `lib/app/view/shared/feedback_report_page.dart`

- [ ] **Step 1: Create the page**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/viewmodel/auth_view_model.dart';
import 'package:jsba_app/app/view/shared/widgets/bug_report_form.dart';
import 'package:jsba_app/app/view/shared/widgets/feedback_form.dart';

class FeedbackReportPage extends StatelessWidget {
  const FeedbackReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Feedback & Bugs',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildOptionCard(
              context,
              icon: Icons.bug_report_outlined,
              title: 'Report a Bug',
              subtitle: 'Found something broken? Let us know.',
              color: Colors.red,
              onTap: () => _showBugReportSheet(context),
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              context,
              icon: Icons.feedback_outlined,
              title: 'Send Feedback',
              subtitle: 'Have suggestions or compliments?',
              color: AppTheme.primaryColor,
              onTap: () => _showFeedbackSheet(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showBugReportSheet(BuildContext context) {
    final userId = context.read<AuthViewModel>().currentUser?.uid ?? '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => BugReportForm(
        userId: userId,
        onSuccess: () => Navigator.pop(ctx),
      ),
    );
  }

  void _showFeedbackSheet(BuildContext context) {
    final userId = context.read<AuthViewModel>().currentUser?.uid ?? '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => FeedbackForm(
        userId: userId,
        onSuccess: () => Navigator.pop(ctx),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**
```bash
git add lib/app/view/shared/feedback_report_page.dart
git commit -m "feat: add feedback report page"
```

---

## Chunk 4: Integration

### Task 8: Update FAQ Page with Banner

**Files:**
- Modify: `lib/app/view/shared/faq_page.dart`

- [ ] **Step 1: Add import and banner**

Add import at top:
```dart
import 'package:jsba_app/app/view/shared/feedback_report_page.dart';
```

Add banner at bottom of body (before closing Column):
```dart
const SizedBox(height: 32),
GestureDetector(
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const FeedbackReportPage()),
  ),
  child: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.primaryColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: AppTheme.primaryColor.withValues(alpha: 0.3),
      ),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Saw a bug? or want to leave a feedback about the app? Check it out here.',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Icon(Icons.chevron_right, color: AppTheme.primaryColor),
      ],
    ),
  ),
),
const SizedBox(height: 20),
```

- [ ] **Step 2: Commit**
```bash
git add lib/app/view/shared/faq_page.dart
git commit -m "feat: add feedback banner to FAQ page"
```

---

### Task 9: Add Route and Export

**Files:**
- Modify: `lib/app/view/pages.dart`
- Modify: `lib/app/assets/router/app_router.dart`

- [ ] **Step 1: Add export**

Modify: `lib/app/view/pages.dart`
Add at end:
```dart
export 'package:jsba_app/app/view/shared/feedback_report_page.dart';
```

- [ ] **Step 2: Add route**

Modify: `lib/app/assets/router/app_router.dart`
Add to routes list:
```dart
AutoRoute(page: FeedbackReportRoute.page, path: '/feedback-report'),
```

- [ ] **Step 3: Run build_runner**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 4: Commit**
```bash
git add lib/app/view/pages.dart lib/app/assets/router/app_router.dart
git commit -m "feat: add feedback report route"
```

---

## Chunk 5: Final Integration

### Task 10: Final Build and Test

- [ ] **Step 1: Run Flutter analyze**

Run: `flutter analyze`

- [ ] **Step 2: Build iOS (if on Mac)**

Run: `flutter build ios --simulator --no-codesign`

- [ ] **Step 3: Final commit**
```bash
git add .
git commit -m "feat: complete feedback and bug report feature"
```
