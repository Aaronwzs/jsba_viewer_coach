import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jsba_app/app/viewmodel/auth_view_model.dart';
import 'package:jsba_app/app/viewmodel/notification_view_model.dart';
import 'package:jsba_app/app/assets/router/app_router.dart';

@RoutePage()
class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // On web, never stay on splash for more than 5 seconds. This prevents
    // the app from being stuck if Firestore/Firebase hangs on startup.
    if (kIsWeb) {
      Timer(const Duration(seconds: 5), () {
        if (!_navigated && mounted) {
          _navigated = true;
          context.router.replaceAll([const AcademyDashboardRoute()]);
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    final authVM = context.read<AuthViewModel>();

    try {
      final user = authVM.getCurrentUser();

      if (user != null) {
        // Wrap loadUser in a timeout so Firestore can't hang forever on web
        try {
          await authVM.loadUser(user.uid).timeout(const Duration(seconds: 3));
        } on TimeoutException {
          // Firestore timed out — continue as logged out
        }

        if (!mounted || _navigated) return;

        if (authVM.isLoggedIn) {
          context.read<NotificationViewModel>().startListening(user!.uid);

          if (authVM.isCoach) {
            _navigated = true;
            context.router.replaceAll([const CoachMainRoute()]);
          } else {
            _navigated = true;
            context.router.replaceAll([const ParentMainRoute()]);
          }
          return;
        }
      }

      if (!mounted || _navigated) return;
      _navigated = true;
      context.router.replace(const AcademyDashboardRoute());
    } catch (e) {
      if (!mounted || _navigated) return;
      _navigated = true;
      context.router.replace(const AcademyDashboardRoute());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FractionallySizedBox(
              widthFactor: 0.45,
              child: Image.asset(
                'assets/images/jsba_logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
