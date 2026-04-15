import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jsba_app/app/viewmodel/auth_view_model.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/assets/router/app_router.dart';
import 'package:jsba_app/app/utils/responsive_helper.dart';

@RoutePage()
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authVM = context.read<AuthViewModel>();
    final success = await authVM.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      final user = authVM.currentUser;
      if (user?.role == 'Coach') {
        context.router.replaceAll([const CoachMainRoute()]);
      } else {
        context.router.replaceAll([const ParentMainRoute()]);
      }
    } else if (mounted && authVM.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authVM.error!), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final isWide = ResponsiveHelper.isWideScreen(context);

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

  Widget _buildMobileLayout(BuildContext context, AuthViewModel authVM) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          _buildHeader(context, false),
          const SizedBox(height: 32),
          _buildForm(context, authVM),
        ],
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildHeader(context, true),
                  const SizedBox(height: 32),
                  _buildForm(context, authVM),
                ],
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
          Positioned(
            right: -30,
            bottom: 50,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 25,
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
                    Icons.sports_tennis,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sign in to continue your journey',
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

  Widget _buildHeader(BuildContext context, bool isWide) {
    return Column(
      children: [
        if (!isWide) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.sports_tennis,
              size: 48,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          'Welcome Back',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: isWide ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to your account to continue',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          textAlign: isWide ? TextAlign.center : TextAlign.start,
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, AuthViewModel authVM) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Please enter your email';
              if (!value.contains('@')) return 'Please enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Please enter your password';
              return null;
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.router.push(const ResetPasswordRoute()),
              child: const Text('Forgot Password?'),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: authVM.isLoading ? null : _login,
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
                  : const Text('Sign In'),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: TextStyle(color: Colors.grey[600]),
              ),
              TextButton(
                onPressed: () =>
                    context.router.push(const FirstTimeLoginRoute()),
                child: const Text('Register Now'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
