import '../logging/log_level.dart';

/// Central place for everything that differs between dev/staging/prod:
/// backend URL, environment name, log level, and env-gated behavior like
/// network logging. Every value is read via `String.fromEnvironment` /
/// `bool.fromEnvironment`, which Dart resolves at *compile time* — so
/// there's no runtime file I/O and it works identically on every
/// platform Flutter targets (mobile, web, desktop).
///
/// Values are supplied per environment via the JSON files in `env/`
/// (see `env/dev.json`, `env/staging.json`, `env/prod.json`) using
/// `--dart-define-from-file`, so you never edit this file to switch
/// environments — see the README for the run/build commands.
enum Environment { dev, staging, prod }

class EnvConfig {
  EnvConfig._();

  static const String _envName = String.fromEnvironment('ENV_NAME', defaultValue: 'dev');

  static Environment get environment {
    switch (_envName) {
      case 'prod':
        return Environment.prod;
      case 'staging':
        return Environment.staging;
      default:
        return Environment.dev;
    }
  }

  static bool get isDev => environment == Environment.dev;
  static bool get isStaging => environment == Environment.staging;
  static bool get isProd => environment == Environment.prod;

  // TODO(backend): replace the placeholder host in env/*.json with the
  // real API base URL for each environment before release — dev.json /
  // staging.json / prod.json all still point at your-backend.example.com.
  // Falls back to the dev backend so `flutter run` with no --dart-define
  // flags still points somewhere sane instead of a placeholder URL.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://your-backend.example.com',
  );

  // Verbose request/response logging is opt-in per environment — the
  // per-environment JSON file is what actually turns this off in prod
  // (see env/prod.json). The bare `defaultValue` here only applies if
  // you run without --dart-define-from-file at all.
  static const bool enableNetworkLogging = bool.fromEnvironment(
    'ENABLE_NETWORK_LOGGING',
    defaultValue: true,
  );

  // Minimum severity AppLogger will emit. Set per environment in
  // env/*.json ('debug' | 'info' | 'warning' | 'error'); anything below
  // this is dropped before it's formatted, not just hidden from view.
  static const String _logLevelName = String.fromEnvironment('LOG_LEVEL', defaultValue: 'debug');

  static LogLevel get logLevel => LogLevelSeverity.fromName(_logLevelName);
}
