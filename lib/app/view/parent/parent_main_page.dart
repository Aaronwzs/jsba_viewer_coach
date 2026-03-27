import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Colors, Icons, Scaffold, AlertDialog, TextButton, showDialog;
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/assets/router/app_router.dart';

@RoutePage()
class ParentMainPage extends StatefulWidget {
  const ParentMainPage({super.key});

  @override
  State<ParentMainPage> createState() => _ParentMainPageState();
}

class _ParentMainPageState extends State<ParentMainPage> {
  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
      routes: const [
        ParentDashboardRoute(),
        MyReportsRoute(),
        CourtBookingsRoute(),
        ParentInvoicesRoute(),
        SettingsRoute(),
      ],
      builder: (context, child) {
        final tabRouter = AutoTabsRouter.of(context);
        return PopScope(
          canPop: false,
          child: Scaffold(
            body: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                child,
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: MediaQuery.paddingOf(context).bottom > 0
                          ? 0
                          : 20,
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildMainNavigationBar(tabRouter)),
                        const SizedBox(width: 12),
                        _buildFaqButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainNavigationBar(TabsRouter tabRouter) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 32,
            color: AppTheme.primaryColor.withValues(alpha: 0.24),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context,
            index: 0,
            icon: Icons.home,
            label: 'Home',
            tabRouter: tabRouter,
          ),
          _buildNavItem(
            context,
            index: 1,
            icon: Icons.assessment,
            label: 'My Reports',
            tabRouter: tabRouter,
          ),
          _buildNavItem(
            context,
            index: 2,
            icon: Icons.sports_tennis,
            label: 'Bookings',
            tabRouter: tabRouter,
          ),
          _buildNavItem(
            context,
            index: 3,
            icon: Icons.receipt_long,
            label: 'Billing',
            tabRouter: tabRouter,
          ),
          _buildNavItem(
            context,
            index: 4,
            icon: Icons.person,
            label: 'Profile',
            tabRouter: tabRouter,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required TabsRouter tabRouter,
  }) {
    final isSelected = tabRouter.activeIndex == index;

    return GestureDetector(
      onTap: () => tabRouter.setActiveIndex(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? CupertinoColors.white
                  : AppTheme.primaryColor.withValues(alpha: 0.6),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: isSelected
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqButton() {
    return GestureDetector(
      onTap: () => _showFaqDialog(context),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: AppTheme.primaryColor.withValues(alpha: 0.30),
            ),
          ],
        ),
        child: const Icon(
          CupertinoIcons.question_circle,
          color: CupertinoColors.white,
          size: 24,
        ),
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
              Text(
                'Q: How do I register my child?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'A: Download the app and create an account to register your child.',
              ),
              SizedBox(height: 12),
              Text(
                'Q: What age groups do you accept?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('A: We accept students from 5 years old and above.'),
              SizedBox(height: 12),
              Text(
                'Q: Do you offer trial sessions?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('A: Yes! We offer a free trial session for new students.'),
              SizedBox(height: 12),
              Text(
                'Q: What should my child bring?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'A: Sports attire, badminton racket (optional), and water bottle.',
              ),
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
}
