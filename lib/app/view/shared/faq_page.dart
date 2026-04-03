import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/view/shared/feedback_report_page.dart';

@RoutePage()
class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FAQ',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frequently Asked Questions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 24),
            _buildFaqItem(
              context,
              question: 'How do I register my child?',
              answer:
                  'Download the app and create an account to register your child.',
            ),
            _buildFaqItem(
              context,
              question: 'What age groups do you accept?',
              answer: 'We accept students from 5 years old and above.',
            ),
            _buildFaqItem(
              context,
              question: 'Do you offer trial sessions?',
              answer: 'Yes! We offer a free trial session for new students.',
            ),
            _buildFaqItem(
              context,
              question: 'What should my child bring?',
              answer:
                  'Sports attire, badminton racket (optional), and water bottle.',
            ),
            _buildFaqItem(
              context,
              question: 'How do I create a new session?',
              answer: 'Go to Sessions tab and tap the + button.',
            ),
            _buildFaqItem(
              context,
              question: 'How do I mark attendance?',
              answer: 'Navigate to the session and tap on attendance.',
            ),
            _buildFaqItem(
              context,
              question: 'How do I add a new player?',
              answer: 'Go to Players tab and tap Add Player.',
            ),
            _buildFaqItem(
              context,
              question: 'How do I record match results?',
              answer: 'Go to Sessions, select a session, and use Record Match.',
            ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(
    BuildContext context, {
    required String question,
    required String answer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Q: $question',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            'A: $answer',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
