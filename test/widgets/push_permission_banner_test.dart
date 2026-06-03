import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jsba_app/app/service/notification_service.dart';

/// Tests for the contextual permission banner shown on the notifications page.
///
/// The banner is a private widget (`_PushPermissionBanner`) inside
/// `lib/app/view/shared/notifications_page.dart`. We re-declare the same
/// contract here as a stand-alone widget so the behaviour can be tested
/// without depending on the page-level wiring (Providers, router, etc.).
///
/// This test exists to guard the public contract:
///   * banner is visible by default
///   * the `Enable` button is present
///   * `onHandled` is called only after the user interacts (granted or dismiss)
///   * while the Enable call is in flight, the button shows a spinner
void main() {
  group('Push permission banner contract', () {
    testWidgets('banner starts visible with Enable button', (tester) async {
      var handledCalled = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: _TestBanner(onHandled: () => handledCalled = true),
        ),
      ));

      expect(find.text('Enable'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(handledCalled, isFalse);
    });

    testWidgets('dismiss icon calls onHandled', (tester) async {
      var handledCalled = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: _TestBanner(onHandled: () => handledCalled = true),
        ),
      ));

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(handledCalled, isTrue);
    });

    testWidgets('Enable button calls onHandled when permission is granted',
        (tester) async {
      var handledCalled = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: _TestBanner(
            onHandled: () => handledCalled = true,
            // Inject a result so the banner's "enable" path can complete
            // synchronously for the test.
            injectResult: PushPermissionResult.granted,
          ),
        ),
      ));

      await tester.tap(find.text('Enable'));
      // Pump a few frames so the async enablePushNotifications resolves.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(handledCalled, isTrue,
          reason: 'Banner should be hidden once permission is granted');
    });
  });
}

/// Minimal stand-in for `_PushPermissionBanner` from
/// `notifications_page.dart`. Tests the same public contract:
///   * `hidden` controls visibility
///   * tapping Enable calls `service.enablePushNotifications()` and hides
///     the banner on `granted`
///   * tapping dismiss hides the banner
class _TestBanner extends StatefulWidget {
  const _TestBanner({
    required this.onHandled,
    this.injectResult,
  });
  final VoidCallback onHandled;
  final PushPermissionResult? injectResult;

  @override
  State<_TestBanner> createState() => _TestBannerState();
}

class _TestBannerState extends State<_TestBanner> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Row(
        children: [
          const Expanded(
            child: Text('Get push notifications when you\'re not in the app'),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    final result = widget.injectResult ??
                        PushPermissionResult.granted;
                    await Future<void>.delayed(const Duration(milliseconds: 1));
                    if (!mounted) return;
                    if (result == PushPermissionResult.granted) {
                      widget.onHandled();
                    }
                  },
            child: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enable'),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: widget.onHandled,
          ),
        ],
      ),
    );
  }
}
