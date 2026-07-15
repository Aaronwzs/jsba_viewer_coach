import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Colors, Icons, Scaffold, MaterialPageRoute, Icon;
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/assets/router/app_router.dart';
import 'package:jsba_app/app/view/shared/faq_page.dart';

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
      routes: [
        ParentDashboardRoute(),
        MyReportsRoute(),
        CourtBookingsRoute(),
        ParentBillingRoute(),
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
      child: GNav(
        onTabChange: tabRouter.setActiveIndex,
        selectedIndex: tabRouter.activeIndex,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        tabBackgroundColor: AppTheme.primaryColor,
        color: AppTheme.primaryColor.withValues(alpha: 0.7),
        activeColor: Colors.white,
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.012,
          vertical: 10,
        ),
        gap: 6,
        tabs: const [
          GButton(icon: Icons.home, text: 'Home'),
          GButton(icon: Icons.assessment, text: 'My Reports'),
          GButton(icon: Icons.sports_tennis, text: 'Bookings'),
          GButton(icon: Icons.receipt_long, text: 'Billing'),
          GButton(icon: Icons.settings, text: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildFaqButton() {
    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const FaqPage())),
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
        child: Icon(
          Icons.quiz_outlined,
          color: CupertinoColors.white,
          size: 24,
        ),
      ),
    );
  }
}
