import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/assets/router/app_router.dart';
import 'package:jsba_app/app/utils/responsive_helper.dart';

@RoutePage()
class FirstTimeLoginPage extends StatefulWidget {
  const FirstTimeLoginPage({super.key});

  @override
  State<FirstTimeLoginPage> createState() => _FirstTimeLoginPageState();
}

class _FirstTimeLoginPageState extends State<FirstTimeLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = ResponsiveHelper.isWideScreen(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: isWide ? _buildWideLayout(context) : _buildMobileLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          _buildHeader(context, false),
          const SizedBox(height: 32),
          _buildForm(context),
        ],
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
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
                  _buildForm(context),
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
                    Icons.person_add,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'New Member?',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Register to join our academy',
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
        Text(
          'First Time Login',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: isWide ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your registered email to verify your account',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          textAlign: isWide ? TextAlign.center : TextAlign.start,
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
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
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  context.router.root.push(const VerificationRoute());
                }
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
              child: const Text('Continue'),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.router.maybePop(),
            child: const Text('Back to Login'),
          ),
        ],
      ),
    );
  }
}
