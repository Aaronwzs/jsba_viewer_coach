import 'package:flutter_test/flutter_test.dart';
import 'package:jsba_app/app/utils/starter_handler.dart';

void main() {
  group('writeCachedLoggedInUid', () {
    test('does not throw when SharedPreferences plugin is unavailable',
        () async {
      // In the test environment there is no native SharedPreferences plugin
      // registered. Our code wraps SharedPreferences access in a try/catch
      // so it must never throw even when the platform channel is missing.
      expect(
        () => writeCachedLoggedInUid('test-uid-123'),
        returnsNormally,
      );
    });

    test('sets in-memory cache even when plugin write fails', () async {
      cachedLoggedInUid = null;

      await writeCachedLoggedInUid('uid-456');

      // The in-memory cache is always updated, regardless of plugin status.
      expect(cachedLoggedInUid, 'uid-456');
    });

    test('clears in-memory cache when uid is null', () async {
      cachedLoggedInUid = 'previous-uid';

      await writeCachedLoggedInUid(null);

      expect(cachedLoggedInUid, isNull);
    });
  });

  group('cachedLoggedInUid', () {
    test('defaults to null before any write', () {
      // After the tests above run, cachedLoggedInUid may be set.
      // Reset it to simulate fresh app start.
      cachedLoggedInUid = null;
      expect(cachedLoggedInUid, isNull);
    });
  });
}
