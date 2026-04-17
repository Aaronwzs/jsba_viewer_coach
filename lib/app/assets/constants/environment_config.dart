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
  const String.fromEnvironment('appFlavor', defaultValue: 'production'),
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
}
