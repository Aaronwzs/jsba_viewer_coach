import 'package:flutter/cupertino.dart';

class BottomNavItem {
  const BottomNavItem({
    required this.label,
    this.iconData,
    this.assetPath,
    this.assetWidth,
    this.assetHeight,
  }) : assert(
          iconData != null || assetPath != null,
          'Either iconData or assetPath must be provided',
        );

  final String label;

  final IconData? iconData;

  final String? assetPath;

  final double? assetWidth;

  final double? assetHeight;

  bool get isAsset => assetPath != null;

  bool get isIcon => iconData != null;

  Widget buildIcon({
    double? size,
    Color? color,
  }) {
    if (isAsset && assetPath != null) {
      return Image.asset(
        assetPath!,
        width: assetWidth ?? size ?? 24,
        height: assetHeight ?? size ?? 24,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            CupertinoIcons.question_circle,
            size: size ?? 24,
            color: color,
          );
        },
      );
    }

    return Icon(
      iconData,
      size: size ?? 24,
      color: color,
    );
  }
}
