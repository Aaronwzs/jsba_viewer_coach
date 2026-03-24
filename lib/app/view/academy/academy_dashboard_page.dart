import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/widgets/bottom_nav_bar.dart';
import 'package:url_launcher/url_launcher.dart';

@RoutePage()
class AcademyDashboardPage extends StatelessWidget {
  const AcademyDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBanner(context),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to JSBA',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Junior Sports Badminton Academy',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'About The Academy',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'JSBA is a premier badminton academy dedicated to nurturing young talent and developing skilled players. '
                      'Our expert coaches provide professional training for players of all skill levels, from beginners to competitive athletes.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondaryColor,
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 24),
                    _buildQuickLinks(context),
                    const SizedBox(height: 24),
                    _buildContactCard(context),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
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
          _showFaqDialog(context);
        },
        selectedColor: AppTheme.primaryColor,
        unselectedColor: AppTheme.primaryColor,
        backgroundColor: Colors.white,
        items: const [],
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.8),
            AppTheme.secondaryColor,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Icon(
              Icons.sports_tennis,
              size: 180,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -20,
            child: Icon(
              Icons.circle,
              size: 100,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.sports_tennis,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'JSBA',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Badminton Academy',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Kuala Lumpur, Malaysia',
                        style: TextStyle(color: Colors.white, fontSize: 12),
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

  Widget _buildQuickLinks(BuildContext context) {
    final links = [
      {'icon': Icons.info_outline, 'label': 'About Us', 'onTap': () => _showInfoDialog(context, 'About Us', 'JSBA is a premier badminton academy established in 2015. We are committed to developing young talent through professional coaching and state-of-the-art facilities.')},
      {'icon': Icons.sports_tennis, 'label': 'Programs', 'onTap': () => _showInfoDialog(context, 'Programs', 'We offer various programs including:\n\n• Beginners Course\n• Intermediate Training\n• Advanced Coaching\n• Private Lessons\n• Holiday Camps')},
      {'icon': Icons.calendar_today, 'label': 'Schedule', 'onTap': () => _showInfoDialog(context, 'Schedule', 'Our training sessions are available:\n\n• Monday - Friday: 4PM - 9PM\n• Saturday - Sunday: 9AM - 6PM\n\nBook your slot through the app!')},
      {'icon': Icons.location_on_outlined, 'label': 'Location', 'onTap': () => _launchMaps()},
      {'icon': Icons.phone_outlined, 'label': 'Contact', 'onTap': () => _showContactDialog(context)},
      {'icon': Icons.photo_library_outlined, 'label': 'Gallery', 'onTap': () => _showInfoDialog(context, 'Gallery', 'Check out our photo gallery on social media!')},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Links',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: links.length,
          itemBuilder: (context, index) {
            final link = links[index];
            return _buildLinkCard(
              context,
              icon: link['icon'] as IconData,
              label: link['label'] as String,
              onTap: link['onTap'] as VoidCallback,
            );
          },
        ),
      ],
    );
  }

  Widget _buildLinkCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.headset_mic, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                'Get In Touch',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Have questions? Our team is here to help you.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showFaqDialog(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                  child: const Text('FAQ'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showContactDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text('Contact Us'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
        title: const Text('Contact Us'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📞 Phone: +60 12-345 6789'),
            SizedBox(height: 8),
            Text('📧 Email: info@jsba.com.my'),
            SizedBox(height: 8),
            Text('📍 Location: KL Badminton Centre'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFaqDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Frequently Asked Questions'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Q: How do I register my child?',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('A: Download the app and create an account to register your child.'),
              SizedBox(height: 12),
              Text('Q: What age groups do you accept?',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('A: We accept students from 5 years old and above.'),
              SizedBox(height: 12),
              Text('Q: Do you offer trial sessions?',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('A: Yes! We offer a free trial session for new students.'),
              SizedBox(height: 12),
              Text('Q: What should my child bring?',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('A: Sports attire, badminton racket (optional), and water bottle.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchMaps() async {
    final Uri googleMapsUrl = Uri.parse('https://maps.google.com/?q=JSBA+Badminton+Academy+Kuala+Lumpur');
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }
}
