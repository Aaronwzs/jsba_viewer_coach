import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Icons;
import 'bottom_nav_item.dart';
import 'notification_badge.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTabChanged,
    this.unreadCount,
    this.badgeIndex,
    this.showLoginButton = false,
    this.showFaqButton = false,
    this.onLoginPressed,
    this.onFaqPressed,
    this.selectedColor = const Color(0xFF7C4DFF),
    this.unselectedColor = const Color(0xFF7C4DFF),
    this.backgroundColor = CupertinoColors.white,
    Color? shadowColor,
    this.borderRadius = 100,
    this.iconSize = 24,
    this.horizontalPadding = 20,
    this.verticalPadding = 20,
    this.gap = 10,
  }) : shadowColor = shadowColor ?? const Color(0x3D7C4DFF);

  final List<BottomNavItem> items;
  final int selectedIndex;
  final ValueChanged<int>? onTabChanged;
  final int? unreadCount;
  final int? badgeIndex;
  final bool showLoginButton;
  final bool showFaqButton;
  final VoidCallback? onLoginPressed;
  final VoidCallback? onFaqPressed;
  final Color selectedColor;
  final Color unselectedColor;
  final Color backgroundColor;
  final Color shadowColor;
  final double borderRadius;
  final double iconSize;
  final double horizontalPadding;
  final double verticalPadding;
  final double gap;

  bool get showBadge =>
      unreadCount != null && unreadCount! > 0 && badgeIndex != null;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: MediaQuery.paddingOf(context).bottom > 0
              ? 0
              : verticalPadding,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (items.isNotEmpty)
              _buildMainNavigationBar(context)
            else if (showLoginButton)
              _buildLoginButton(context)
            else
              const SizedBox.shrink(),
            if (showLoginButton && items.isNotEmpty) SizedBox(width: gap + 8),
            if (showFaqButton) _buildFaqButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMainNavigationBar(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: backgroundColor,
          boxShadow: [BoxShadow(blurRadius: 32, color: shadowColor)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          mainAxisSize: MainAxisSize.min,
          children: _buildTabItems(context),
        ),
      ),
    );
  }

  List<Widget> _buildTabItems(BuildContext context) {
    final List<Widget> tabWidgets = [];

    for (int i = 0; i < items.length; i++) {
      if (i > 0) {
        tabWidgets.add(SizedBox(width: 4));
      }
      tabWidgets.add(_buildTabItem(context, i));
    }

    return tabWidgets;
  }

  Widget _buildTabItem(BuildContext context, int index) {
    final item = items[index];
    final isSelected = index == selectedIndex;

    return GestureDetector(
      onTap: () => onTabChanged?.call(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                item.buildIcon(
                  size: iconSize,
                  color: isSelected ? CupertinoColors.white : unselectedColor,
                ),
                if (showBadge && index == badgeIndex)
                  NotificationBadge(unreadCount!),
              ],
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
                          item.label,
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

  Widget _buildLoginButton(BuildContext context) {
    return GestureDetector(
      onTap: onLoginPressed,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: backgroundColor,
          boxShadow: [BoxShadow(blurRadius: 32, color: shadowColor)],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.person, size: iconSize, color: unselectedColor),
            const SizedBox(width: 10),
            Text(
              'Sign In',
              style: TextStyle(
                color: unselectedColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqButton(BuildContext context) {
    return GestureDetector(
      onTap: onFaqPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: selectedColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: selectedColor.withValues(alpha: 0.30),
            ),
          ],
        ),
        child: Icon(
          Icons.quiz_outlined,
          size: iconSize,
          color: CupertinoColors.white,
        ),
      ),
    );
  }
}
