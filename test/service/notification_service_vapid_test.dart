import 'package:flutter_test/flutter_test.dart';
import 'package:jsba_app/app/assets/constants/environment_config.dart';
import 'package:jsba_app/app/service/notification_service.dart';

void main() {
  group('EnvValues.webVapidKey', () {
    test('is exposed as a String', () {
      // The default value when no --dart-define is provided is the empty
      // string — the production build pipeline always injects one.
      expect(EnvValues.webVapidKey, isA<String>());
    });

    test('is empty when no --dart-define=webVapidKey=... is provided', () {
      // Tests run without a dart-define for webVapidKey, so the default
      // value should be the empty string. This guard is what
      // `NotificationService.resolveVapidKey` uses to decide whether to
      // pass the key to FCM.
      expect(EnvValues.webVapidKey, '');
    });
  });

  group('NotificationService.resolveVapidKey', () {
    test('returns the VAPID key on web when a non-empty key is provided', () {
      // flutter_test runs in the web environment, so kIsWeb is true here.
      expect(
        NotificationService.resolveVapidKey(
          webVapidKeyOverride: 'BO1h0Ic8-test-key',
        ),
        'BO1h0Ic8-test-key',
      );
    });

    test('returns null on web when the VAPID key is empty', () {
      // An empty env value means the build was run without configuring the
      // VAPID key — skip passing it to FCM rather than passing an empty
      // string (which FCM rejects).
      expect(
        NotificationService.resolveVapidKey(webVapidKeyOverride: ''),
        isNull,
      );
    });

    test('falls back to EnvValues.webVapidKey when no override is given', () {
      // No override → helper reads from EnvValues. In a test environment
      // without a dart-define, EnvValues.webVapidKey is empty, so the
      // helper returns null.
      expect(NotificationService.resolveVapidKey(), isNull);
    });
  });

  group('PushPermissionResult', () {
    test('has three states: granted, denied, unsupported', () {
      // The three states are referenced by name from
      // `lib/app/view/shared/notifications_page.dart` and from
      // `NotificationService.enablePushNotifications` — keeping the names
      // stable is a public-API contract.
      expect(PushPermissionResult.values, hasLength(3));
      expect(
        PushPermissionResult.values.map((e) => e.name).toSet(),
        {'granted', 'denied', 'unsupported'},
      );
    });
  });
}
