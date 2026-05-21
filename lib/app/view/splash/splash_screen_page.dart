import 'package:auto_route/auto_route.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    final authVM = context.read<AuthViewModel>();
    
    try {
      final user = authVM.getCurrentUser();
      if (user != null) {
        await authVM.loadUser(user.uid);

        if (!mounted) return;
        
        if (authVM.isLoggedIn) {
          // Start listening to notifications for this user
          context.read<NotificationViewModel>().startListening(user!.uid);

          if (authVM.isCoach) {
            context.router.replaceAll([const CoachMainRoute()]);
          } else {
            context.router.replaceAll([const ParentMainRoute()]);
          }
          return;
        }
      }
      
      if (!mounted) return;
      context.router.replace(const AcademyDashboardRoute());
    } catch (e) {
      if (!mounted) return;
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
