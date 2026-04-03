import 'package:flutter/material.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/model/feedback_model.dart';
import 'package:jsba_app/app/service/feedback_service.dart';
import 'package:jsba_app/app/utils/device_info_helper.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:jsba_app/app/view/shared/widgets/form_section_card.dart';

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
    } catch (e, stackTrace) {
      EasyLoading.dismiss();
      print('Feedback submission error: $e');
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
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Please enter a title'
                    : null,
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
                  hintText:
                      'Provide details about your suggestion, concern, or compliment...',
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
