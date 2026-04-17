import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet, web }

class ResponsiveHelper {
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) return DeviceType.mobile;
    if (width < 900) return DeviceType.tablet;
    return DeviceType.web;
  }

  static bool get isMobilePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  static bool get isWebPlatform => kIsWeb;

  static int getQuickLinkColumns(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return 3;
      case DeviceType.tablet:
        return 4;
      case DeviceType.web:
        return 6;
    }
  }

  static double getHeroHeight(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) return 220;
    if (width < 900) return 260;
    return 300;
  }

  static double getHorizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) return 16;
    if (width < 900) return 24;
    return 48;
  }

  static double getMaxContentWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 900) return double.infinity;
    return 800;
  }

  static EdgeInsets getCardPadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return const EdgeInsets.all(16);
      case DeviceType.tablet:
        return const EdgeInsets.all(20);
      case DeviceType.web:
        return const EdgeInsets.all(24);
    }
  }

  static double getContentMaxWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) return double.infinity;
    if (width < 900) return 600;
    return 800;
  }

  static bool isWideScreen(BuildContext context) {
    return MediaQuery.sizeOf(context).width > 700;
  }
}
