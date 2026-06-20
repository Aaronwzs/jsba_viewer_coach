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

  /// ImageKit private key used by [StorageService] to upload images.
  ///
  /// ⚠️ Security warning: this key is compiled into the app binary via
  /// `--dart-define-from-file`. ImageKit private keys are server-side secrets;
  /// embedding one in a client app means it can be extracted from the compiled
  /// artifact. This is the same trust model the previous imgBB integration used,
  /// but for production apps consider moving uploads to a backend endpoint
  /// (e.g., Firebase Cloud Function) that holds the private key and returns only
  /// the public URL to the client.
  ///
  /// Inject via `--dart-define-from-file` using the `IMAGEKIT_PRIVATE_KEY` key
  /// in `env/{environment}-env.json`. Never commit the real key to git.
  static const String imageKitPrivateKey = String.fromEnvironment(
    'IMAGEKIT_PRIVATE_KEY',
    defaultValue: '',
  );

  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
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
