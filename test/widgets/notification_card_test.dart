import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jsba_app/app/widgets/notification_card.dart';
import '../helpers/model_factories.dart';

/// Wraps the widget under test in a MaterialApp + Scaffold so it can paint
/// without throwing missing-ancestor errors.
Widget _harness(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: Column(children: [child]),
      ),
    ),
  );
}

/// All ScaleTransitions that come from this widget (not the framework).
Finder findPulse() => find.byKey(NotificationCard.pulseKey);

void main() {
  group('NotificationCard (detailed)', () {
    testWidgets('unread shows bold title and a pulsing icon', (tester) async {
      final notif = TestModelFactory.createNotification(
        isRead: false,
        title: 'New invoice',
        type: 'invoice',
      );

      await tester.pumpWidget(_harness(NotificationCard(notification: notif)));

      // Title is bold for unread
      final titleWidget = tester.widget<Text>(find.text('New invoice'));
      expect(titleWidget.style?.fontWeight, FontWeight.bold);

      // Pulse animation wrapper is present
      expect(findPulse(), findsOneWidget);

      // No 0.6 Opacity wrapper for unread cards
      final opacities = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .where((o) => o.opacity == 0.6);
      expect(opacities, isEmpty);
    });

    testWidgets('read wraps whole card in Opacity(0.6) and uses normal weight',
        (tester) async {
      final notif = TestModelFactory.createNotification(
        isRead: true,
        title: 'Old invoice',
        type: 'invoice',
      );

      await tester.pumpWidget(_harness(NotificationCard(notification: notif)));

      // Title is normal weight for read
      final titleWidget = tester.widget<Text>(find.text('Old invoice'));
      expect(titleWidget.style?.fontWeight, FontWeight.normal);

      // The 0.6 Opacity wrapper is present
      final opacities = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .where((o) => o.opacity == 0.6);
      expect(opacities, isNotEmpty);

      // No pulse animation for read cards
      expect(findPulse(), findsNothing);
    });

    testWidgets('unread shows type label chip (detailed only)',
        (tester) async {
      final notif = TestModelFactory.createNotification(
        isRead: false,
        type: 'invoice',
      );

      await tester.pumpWidget(_harness(NotificationCard(notification: notif)));

      // Detailed layout shows the human-readable type label
      expect(find.text('Invoice'), findsOneWidget);
    });

    testWidgets('pulse animation value changes when time advances',
        (tester) async {
      final notif = TestModelFactory.createNotification(isRead: false);

      await tester.pumpWidget(_harness(NotificationCard(notification: notif)));
      // pump once more so the AnimationController starts ticking
      await tester.pump();
      final transform = tester.widget<Transform>(
        find.descendant(
          of: findPulse(),
          matching: find.byType(Transform),
        ),
      );
      // Transform.scale wraps a Matrix4; extract scale on the diagonal.
      double scaleAt(Transform t) => t.transform.storage[0];
      final t0 = scaleAt(transform);

      // Advance by 750ms — half a cycle of the 1500ms pulse
      await tester.pump(const Duration(milliseconds: 750));
      final t1 = scaleAt(tester.widget<Transform>(
        find.descendant(
          of: findPulse(),
          matching: find.byType(Transform),
        ),
      ));

      expect(t1, isNot(equals(t0)),
          reason: 'Pulse animation value should change over time');
    });
  });

  group('NotificationCard (compact)', () {
    testWidgets('unread compact card does not show the type label',
        (tester) async {
      final notif = TestModelFactory.createNotification(
        isRead: false,
        type: 'invoice',
      );

      await tester.pumpWidget(_harness(
        NotificationCard(notification: notif, compact: true),
      ));

      // Compact layout omits the type chip
      expect(find.text('Invoice'), findsNothing);

      // Pulse is still present
      expect(findPulse(), findsOneWidget);
    });

    testWidgets('read compact card wraps card in Opacity(0.6)',
        (tester) async {
      final notif = TestModelFactory.createNotification(
        isRead: true,
        type: 'invoice',
      );

      await tester.pumpWidget(_harness(
        NotificationCard(notification: notif, compact: true),
      ));

      final opacities = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .where((o) => o.opacity == 0.6);
      expect(opacities, isNotEmpty);
    });
  });

  group('NotificationCard (interaction)', () {
    testWidgets('onTap fires when card is tapped', (tester) async {
      var taps = 0;
      final notif = TestModelFactory.createNotification();

      await tester.pumpWidget(_harness(NotificationCard(
        notification: notif,
        onTap: () => taps++,
      )));

      await tester.tap(find.byType(NotificationCard));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('transitioning from unread → read stops the pulse',
        (tester) async {
      var isRead = false;
      late StateSetter externalSetState;

      await tester.pumpWidget(_harness(
        StatefulBuilder(
          builder: (context, setState) {
            externalSetState = setState;
            return NotificationCard(
              notification: TestModelFactory.createNotification(isRead: isRead),
              key: ValueKey(isRead),
            );
          },
        ),
      ));

      // Initially unread → pulse is animating
      expect(findPulse(), findsOneWidget);

      // Mark as read externally and rebuild
      externalSetState(() => isRead = true);
      await tester.pump();

      // Pulse should be gone, Opacity(0.6) should appear
      expect(findPulse(), findsNothing);
      final opacities = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .where((o) => o.opacity == 0.6);
      expect(opacities, isNotEmpty);
    });
  });
}
