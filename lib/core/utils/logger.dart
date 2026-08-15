import 'package:logger/logger.dart';

/// Centralized logger instance to be used across the application.
/// Ensures consistent logging formats and filters sensitive information.
final AppLogger appLogger = AppLogger();

class AppLogger {
  late final Logger _logger;

  AppLogger() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 80,
        colors: true,
        printEmojis: true,
      ),
    );
  }

  /// Logs a trace message.
  void t(String message) {
    _logger.t(message);
  }

  /// Logs a debug message.
  void d(String message) {
    _logger.d(message);
  }

  /// Logs an info message. Use for tracking startup, sync, and migrations.
  void i(String message) {
    _logger.i(message);
  }

  /// Logs a warning message.
  void w(String message) {
    _logger.w(message);
  }

  /// Logs an error message along with an optional exception and stacktrace.
  void e(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Logs a fatal message.
  void f(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}
