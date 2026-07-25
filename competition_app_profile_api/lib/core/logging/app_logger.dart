import 'dart:developer' as developer;

import '../config/env_config.dart';
import 'log_level.dart';

extension on LogLevel {
  /// dart:developer's log() takes an int; these line up with the
  /// conventional values so DevTools/Logcat color them sensibly.
  int get devToolsLevel {
    switch (this) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
}

/// The one place app code calls into for logging. Never call `print`,
/// `debugPrint`, or Dio's own `LogInterceptor` directly elsewhere — route
/// through here so every log line respects `EnvConfig.logLevel` and
/// carries a consistent `tag`/timestamp/error/stackTrace shape.
class AppLogger {
  AppLogger._();

  static void debug(String message, {String tag = 'App'}) => _log(LogLevel.debug, tag, message);

  static void info(String message, {String tag = 'App'}) => _log(LogLevel.info, tag, message);

  static void warning(String message, {String tag = 'App'}) =>
      _log(LogLevel.warning, tag, message);

  static void error(
    String message, {
    String tag = 'App',
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _log(LogLevel.error, tag, message, error: error, stackTrace: stackTrace);

  static void _log(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.severity < EnvConfig.logLevel.severity) return;

    developer.log(
      message,
      time: DateTime.now(),
      level: level.devToolsLevel,
      name: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
