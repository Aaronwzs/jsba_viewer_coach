import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jsba_app/app/viewmodel/auth_view_model.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
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
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_tennis,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            Text(
              'JSBA',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Badminton Academy',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
