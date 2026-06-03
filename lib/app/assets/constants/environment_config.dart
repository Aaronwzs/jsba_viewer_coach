enum EnvironmentType {
  staging,
  production;

  factory EnvironmentType.fromAppFlavor(String? flavor) {
    switch (flavor) {
      case 'staging':
        return EnvironmentType.staging;
      case 'production':
        return EnvironmentType.production;
      default:
        return EnvironmentType.production;
    }
  }
}

final appEnvironmentType = EnvironmentType.fromAppFlavor(
  const String.fromEnvironment('appFlavor', defaultValue: ''),
);

class EnvValues {
  EnvValues._();

  static const String appName = String.fromEnvironment(
    'appName',
    defaultValue: 'JSBA',
  );
  static const bool showDebugOverlay = bool.fromEnvironment(
    'showDebugOverlay',
    defaultValue: false,
  );
  static const String firebaseProjectId = String.fromEnvironment(
    'firebaseProjectId',
    defaultValue: 'juniorshuttlers',
  );
  static const String imgbbApiKey = String.fromEnvironment(
    'IMGBB_API_KEY',
    defaultValue: '',
  );

  /// FCM Web Push VAPID public key. Required when calling
  /// `FirebaseMessaging.getToken(vapidKey: ...)` on web to subscribe the
  /// browser to push messages. Inject via `--dart-define-from-file` using the
  /// `webVapidKey` key in `env/{environment}-env.json`. The corresponding
  /// private key lives in `functions/.env` and is used by the Cloud Functions
  /// to sign push messages — never commit the private key to git.
  ///
  /// **Security note:** the VAPID key pair was previously shared in chat. The
  /// private key should be rotated in Firebase Console as soon as possible.
  static const String webVapidKey = String.fromEnvironment(
    'webVapidKey',
    defaultValue: '',
  );
}
