import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/model/feedback_model.dart';
import 'package:jsba_app/app/service/feedback_service.dart';
import 'package:jsba_app/app/utils/device_info_helper.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:jsba_app/app/view/shared/widgets/form_section_card.dart';

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
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
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

      final feedback = FeedbackModel(
        type: FeedbackType.bug,
        title: _titleController.text.trim(),
        description: _actualController.text.trim(),
        stepsToReproduce: _stepsController.text.trim(),
        expectedBehavior: _expectedController.text.trim(),
        actualBehavior: _actualController.text.trim(),
        screenshotUrl: null,
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
    } catch (e, stackTrace) {
      EasyLoading.dismiss();
      print('Bug report submission error: $e');
      print('Stack trace: $stackTrace');
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
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Please enter a title'
                    : null,
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
              helperText:
                  'Attach a screenshot to help us understand (optional)',
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
}
