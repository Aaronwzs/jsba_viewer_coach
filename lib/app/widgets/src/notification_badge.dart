import 'dart:math';
import 'package:flutter/cupertino.dart';

class NotificationBadge extends StatelessWidget {
  const NotificationBadge(
    this.count, {
    super.key,
    this.maxCount = 99,
    this.showPlus = true,
  });

  final int count;
  final int maxCount;
  final bool showPlus;

  String get displayCount {
    if (count > maxCount && showPlus) {
      return '$maxCount+';
    }
    return count.toString();
  }

  int get digitCount => min(displayCount.length, 3);

  double _rightPositionMargin(int digits) {
    switch (digits) {
      case 1:
        return -4;
      case 2:
        return -8;
      case 3:
        return -10;
      default:
        return -4;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -8,
      right: _rightPositionMargin(digitCount),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: digitCount == 3 ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: digitCount == 3 ? BorderRadius.circular(14) : null,
          color: CupertinoColors.destructiveRed,
        ),
        child: Text(
          displayCount,
          style: const TextStyle(
            fontSize: 10,
            color: CupertinoColors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
