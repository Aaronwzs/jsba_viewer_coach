import 'package:flutter/material.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';

class AppBarTitle extends StatelessWidget implements PreferredSizeWidget {
  const AppBarTitle({
    super.key,
    this.title = 'JuniorShuttlers',
    this.icon = Icons.sports_tennis,
    this.blackBackButton = false,
    this.actions,
    this.showBackButton = true,
  });

  final String title;
  final IconData icon;
  final bool blackBackButton;
  final List<Widget>? actions;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
