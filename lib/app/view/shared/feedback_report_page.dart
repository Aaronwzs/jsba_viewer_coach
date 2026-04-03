import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/viewmodel/auth_view_model.dart';
import 'package:jsba_app/app/view/shared/widgets/bug_report_form.dart';
import 'package:jsba_app/app/view/shared/widgets/feedback_form.dart';

@RoutePage()
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
              onTap: () => _navigateToBugForm(context),
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              context,
              icon: Icons.feedback_outlined,
              title: 'Send Feedback',
              subtitle: 'Have suggestions or compliments?',
              color: AppTheme.primaryColor,
              onTap: () => _navigateToFeedbackForm(context),
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
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
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

  void _navigateToBugForm(BuildContext context) {
    String userId = '';
    try {
      userId = context.read<AuthViewModel>().currentUser?.uid ?? 'anonymous';
    } catch (e) {
      userId = 'anonymous';
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => BugReportPage(userId: userId)),
    );
  }

  void _navigateToFeedbackForm(BuildContext context) {
    String userId = '';
    try {
      userId = context.read<AuthViewModel>().currentUser?.uid ?? 'anonymous';
    } catch (e) {
      userId = 'anonymous';
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => FeedbackPage(userId: userId)),
    );
  }
}

class BugReportPage extends StatelessWidget {
  final String userId;

  const BugReportPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Report a Bug',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BugReportForm(
        userId: userId,
        onSuccess: () => Navigator.pop(context),
      ),
    );
  }
}

class FeedbackPage extends StatelessWidget {
  final String userId;

  const FeedbackPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Send Feedback',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FeedbackForm(
        userId: userId,
        onSuccess: () => Navigator.pop(context),
      ),
    );
  }
}
