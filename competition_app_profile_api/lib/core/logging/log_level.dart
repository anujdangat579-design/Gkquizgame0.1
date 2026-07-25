/// Severity, ordered low → high.
enum LogLevel { debug, info, warning, error }

extension LogLevelSeverity on LogLevel {
  int get severity => index;

  static LogLevel fromName(String name) {
    switch (name) {
      case 'debug':
        return LogLevel.debug;
      case 'warning':
        return LogLevel.warning;
      case 'error':
        return LogLevel.error;
      default:
        return LogLevel.info;
    }
  }
}
