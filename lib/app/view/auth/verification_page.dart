import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jsba_app/app/widgets/auth_template.dart';
import 'package:jsba_app/app/assets/router/app_router.dart';

@RoutePage()
class VerificationPage extends StatelessWidget {
  const VerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthTemplate(
      title: 'Email Verification',
      subtitle: 'Please verify your email address',
      children: [
        Column(
          children: [
            const Icon(
              Icons.mark_email_read,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            Text(
              'A verification link has been sent to your email. Please check your inbox and click the link to verify your account.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Verification email resent'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Resend Email'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                context.router.root.replace(const LoginLandingRoute());
              },
              child: const Text('Back to Login'),
            ),
          ],
        ),
      ],
    );
  }
}
