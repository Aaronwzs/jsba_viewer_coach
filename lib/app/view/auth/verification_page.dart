import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/assets/router/app_router.dart';
import 'package:jsba_app/app/utils/responsive_helper.dart';
import 'package:jsba_app/app/viewmodel/auth_view_model.dart';

@RoutePage()
class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  Timer? _pollingTimer;

  // Timeout tracking (5 minutes)
  static const int _timeoutSeconds = 300;
  final DateTime _pageLoadTime = DateTime.now();
  bool _hasTimedOut = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Polling
  // ---------------------------------------------------------------------------

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) return;

      // Check 1: Is the user still logged in to Firebase Auth?
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _pollingTimer?.cancel();
        if (mounted) _showNotAuthenticatedDialog();
        return;
      }

      // Check 2: Has the verification window expired (> 5 minutes)?
      final elapsed = DateTime.now().difference(_pageLoadTime);
      if (elapsed.inSeconds >= _timeoutSeconds && !_hasTimedOut) {
        _pollingTimer?.cancel();
        if (mounted) {
          setState(() => _hasTimedOut = true);
          _showTimeoutDialog();
        }
        return;
      }

      // Refresh the countdown display
      if (mounted) setState(() {});

      // Check 3: Is the email now verified?
      final authVM = context.read<AuthViewModel>();
      final isVerified = await authVM.checkEmailVerification();
      if (isVerified) {
        _pollingTimer?.cancel();
        if (mounted) _onVerified(authVM);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Verified — navigate to the correct dashboard based on role
  // ---------------------------------------------------------------------------

  void _onVerified(AuthViewModel authVM) {
    // Reload the user model from Firestore so role info is fresh
    final uid = authVM.getCurrentUser()?.uid;
    if (uid != null) {
      authVM.loadUser(uid);
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Email Verified!'),
        content: const Text(
          'Your email has been verified successfully.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (!mounted) return;

              // Navigate to the appropriate dashboard
              if (authVM.isCoach) {
                context.router.replaceAll([const CoachMainRoute()]);
              } else {
                context.router.replaceAll([const ParentMainRoute()]);
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Not-authenticated dialog
  // ---------------------------------------------------------------------------

  void _showNotAuthenticatedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Text(
          'Your session is no longer valid. '
          'Please sign in again to continue.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (mounted) {
                context.router.replaceAll([const AcademyDashboardRoute()]);
              }
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Timeout dialog
  // ---------------------------------------------------------------------------

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Verification Timeout'),
        content: const Text(
          'Email verification took longer than 5 minutes. '
          'Your verification link may have expired.\n\n'
          'Please sign in again to resend a new verification email.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (mounted) {
                context.router.replaceAll([const AcademyDashboardRoute()]);
              }
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isWide = ResponsiveHelper.isWideScreen(context);
    final authVM = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: isWide
            ? _buildWideLayout(context, authVM)
            : _buildMobileLayout(context, authVM),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Layout helpers
  // ---------------------------------------------------------------------------

  Widget _buildMobileLayout(BuildContext context, AuthViewModel authVM) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              _buildContent(context, false, authVM),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, AuthViewModel authVM) {
    return Row(
      children: [
        Expanded(flex: 5, child: _buildLeftPanel(context)),
        Expanded(
          flex: 4,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [_buildContent(context, true, authVM)],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeftPanel(BuildContext context) {
    return Container(
      color: AppTheme.primaryColor,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: -100,
            top: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 60,
                ),
              ),
            ),
          ),
          Positioned(
            left: -50,
            bottom: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 40,
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.mark_email_read,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Check Your Email',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Verification link on the way',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Main content
  // ---------------------------------------------------------------------------

  Widget _buildContent(
    BuildContext context,
    bool isWide,
    AuthViewModel authVM,
  ) {
    // Compute remaining time for the countdown
    final elapsed = DateTime.now().difference(_pageLoadTime);
    final remaining = _timeoutSeconds - elapsed.inSeconds;
    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;
    final timeLeft = remaining > 0
        ? '${minutes}m ${seconds.toString().padLeft(2, '0')}s'
        : '0m 00s';

    return Column(
      crossAxisAlignment: isWide
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          'Email Verification',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: isWide ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.mark_email_read, size: 60, color: Colors.green),
        ),
        const SizedBox(height: 24),
        Text(
          'A verification link has been sent to your email.',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: Colors.grey[700], height: 1.5),
          textAlign: isWide ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 8),
        Text(
          'Please check your inbox and click the link to verify your account.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.grey[600]),
          textAlign: isWide ? TextAlign.center : TextAlign.start,
        ),

        // ---- Countdown indicator ----
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: remaining < 60
                ? Colors.orange.shade50
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: remaining < 60
                  ? Colors.orange.shade200
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                remaining < 60
                    ? Icons.timer_off_rounded
                    : Icons.timer_outlined,
                size: 18,
                color: remaining < 60
                    ? Colors.orange.shade700
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                _hasTimedOut
                    ? 'Verification expired'
                    : 'Auto-verifying in $timeLeft',
                style: TextStyle(
                  fontSize: 13,
                  color: remaining < 60
                      ? Colors.orange.shade700
                      : Colors.grey.shade600,
                  fontWeight: remaining < 60 ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // ---- Resend button ----
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: authVM.isLoading
                ? null
                : () async {
                    final ok =
                        await context.read<AuthViewModel>().sendEmailVerification();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? 'Verification email resent.'
                              : (context.read<AuthViewModel>().error ??
                                    'Failed to resend email verification.'),
                        ),
                        backgroundColor: ok ? null : Colors.red,
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: authVM.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Resend Email'),
          ),
        ),
        const SizedBox(height: 16),

        // ---- Back to Login ----
        TextButton(
          onPressed: () =>
              context.router.root.replace(const LoginLandingRoute()),
          child: const Text('Back to Login'),
        ),
      ],
    );
  }
}
