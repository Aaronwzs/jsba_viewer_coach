import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/assets/router/app_router.dart';
import 'package:jsba_app/app/widgets/bottom_nav_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class _C {
  static const primary = Color(0xFF1B6B45);
  static const primaryLight = Color(0xFFEBF5EF);
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF4F8F5);
  static const textDark = Color(0xFF1A2E23);
  static const textMid = Color(0xFF2E4A39);
  static const textMuted = Color(0xFF5A6B62);
  static const border = Color(0x1A1B6B45);
  static const neutral200 = Color(0xFFE8E8E8);
  static const neutral400 = Color(0xFF888888);
  static const whatsapp = Color(0xFF25D366);
}

@RoutePage()
class AcademyDashboardPage extends StatelessWidget {
  const AcademyDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeroBanner(),
              const _OverlapAboutCard(),
              const SizedBox(height: 20),
              _QuickLinksSection(context),
              const SizedBox(height: 20),
              _ContactCard(context),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: 0,
        onTabChanged: (index) {},
        showLoginButton: true,
        showFaqButton: true,
        onLoginPressed: () {
          context.router.pushNamed('/login-landing');
        },
        onFaqPressed: () {
          context.router.push(const FaqRoute());
        },
        selectedColor: AppTheme.primaryColor,
        unselectedColor: AppTheme.primaryColor,
        backgroundColor: Colors.white,
        items: const [],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      color: _C.primary,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: -80,
            top: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                  width: 40,
                ),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -40,
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
          Positioned(
            right: 22,
            top: 36,
            child: Icon(
              Icons.sports_tennis,
              size: 90,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 0.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'JSBA',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            height: 1,
                          ),
                        ),
                        Text(
                          'Badminton Academy',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.55),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Welcome to\nJSBA',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 10,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Kuala Lumpur, Malaysia',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlapAboutCard extends StatelessWidget {
  const _OverlapAboutCard();

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _C.border, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: _C.primary.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ABOUT THE ACADEMY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _C.primary,
                  letterSpacing: 0.8,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'JSBA is a premier badminton academy dedicated to nurturing young talent '
                'and developing skilled players. Our expert coaches provide professional '
                'training for players of all skill levels, from beginners to competitive athletes.',
                style: TextStyle(
                  fontSize: 12,
                  color: _C.textMuted,
                  height: 1.65,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _QuickLinksSection(BuildContext context) {
  final links = [
    _QuickLinkData(
      icon: Icons.person_outline,
      label: 'About Us',
      onTap: () => _showInfoDialog(
        context,
        'About Us',
        'JSBA is a premier badminton academy established in 2015. We are committed to '
            'developing young talent through professional coaching and state-of-the-art facilities.',
      ),
    ),
    _QuickLinkData(
      icon: Icons.format_list_bulleted,
      label: 'Programs',
      onTap: () => _showInfoDialog(
        context,
        'Programs',
        'We offer various programs including:\n\n'
            '• Beginners Course\n'
            '• Intermediate Training\n'
            '• Advanced Coaching\n'
            '• Private Lessons\n'
            '• Holiday Camps',
      ),
    ),
    _QuickLinkData(
      icon: Icons.calendar_today_outlined,
      label: 'Schedule',
      onTap: () => _showInfoDialog(
        context,
        'Schedule',
        'Our training sessions are available:\n\n'
            '• Monday - Friday: 4PM - 9PM\n'
            '• Saturday - Sunday: 9AM - 6PM\n\n'
            'Book your slot through the app!',
      ),
    ),
    _QuickLinkData(
      icon: Icons.location_on_outlined,
      label: 'Location',
      onTap: () => _launchMaps(),
    ),
    _QuickLinkData(
      icon: Icons.phone_outlined,
      label: 'Contact',
      onTap: () => _showContactDialog(context),
    ),
    _QuickLinkData(
      icon: Icons.grid_view_outlined,
      label: 'Gallery',
      onTap: () => _showInfoDialog(
        context,
        'Gallery',
        'Check out our photo gallery on social media!',
      ),
    ),
  ];

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Links',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _C.textDark,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 9,
            crossAxisSpacing: 9,
            childAspectRatio: 1,
          ),
          itemCount: links.length,
          itemBuilder: (context, index) {
            final link = links[index];
            return _QuickLinkCard(data: link);
          },
        ),
      ],
    ),
  );
}

class _QuickLinkData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickLinkData({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _QuickLinkCard extends StatelessWidget {
  final _QuickLinkData data;

  const _QuickLinkCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _C.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _C.border, width: 0.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _C.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(data.icon, color: _C.primary, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                data.label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _C.textMid,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _ContactCard(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.06),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 22,
              color: _C.neutral400,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Get in touch',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _C.textDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Have questions about programs, schedules, or enrolment? Our team is ready to help.',
            style: TextStyle(fontSize: 13, color: _C.neutral400, height: 1.6),
          ),
          const SizedBox(height: 24),
          const Divider(height: 0.5, thickness: 0.5, color: _C.neutral200),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _launchWhatsApp(),
              icon: const Icon(
                Icons.chat_bubble,
                size: 18,
                color: Colors.white,
              ),
              label: const Text('Contact us on WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Center(
            child: Text(
              'Typically replies within a few hours',
              style: TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
            ),
          ),
        ],
      ),
    ),
  );
}

void _showInfoDialog(BuildContext context, String title, String content) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, color: _C.textDark),
      ),
      content: Text(
        content,
        style: const TextStyle(color: _C.textMuted, height: 1.6),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: _C.primary),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

void _showContactDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Contact Us',
        style: TextStyle(fontWeight: FontWeight.w700, color: _C.textDark),
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📞 Phone: +60 18-970 9776'),
          SizedBox(height: 8),
          Text('📧 Email: info@jsba.com.my'),
          SizedBox(height: 8),
          Text('📍 Location: KL Badminton Centre'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: _C.primary),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

Future<void> _launchMaps() async {
  final Uri url = Uri.parse(
    'https://maps.google.com/?q=JSBA+Badminton+Academy+Kuala+Lumpur',
  );
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

Future<void> _launchWhatsApp() async {
  final String phoneNumber = '+60189709776';
  final String message = 'Hello JSBA';

  final Uri waUrl = Uri.parse(
    'whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}',
  );

  if (await canLaunchUrl(waUrl)) {
    await launchUrl(waUrl, mode: LaunchMode.externalApplication);
  } else {
    final Uri webUrl = Uri.parse(
      'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}',
    );
    await launchUrl(webUrl, mode: LaunchMode.externalApplication);
  }
}
