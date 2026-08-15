/// Environment configuration wrapper to manage Dev/Prod variables.
class EnvConfig {
  static late final EnvConfig _instance;

  final String environment;
  final bool isProduction;

  const EnvConfig._({
    required this.environment,
    required this.isProduction,
  });

  /// Initializes the environment configuration.
  /// Typically called before `runApp`.
  static void init({
    String environment = 'dev',
    bool isProduction = false,
  }) {
    _instance = EnvConfig._(
      environment: environment,
      isProduction: isProduction,
    );
  }

  /// Accesses the global [EnvConfig] instance.
  static EnvConfig get instance => _instance;
}
