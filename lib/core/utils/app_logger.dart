import 'dart:developer' as developer;

/// Structured logging utility for manual testing and debugging.
///
/// Uses `dart:developer` log so output appears in the Debug Console.
/// Each feature area has its own named logger for easy filtering.
class AppLogger {
  AppLogger._();

  /// Log an informational message.
  static void info(String tag, String message, [Object? data]) {
    final payload = data != null ? ' | $data' : '';
    developer.log(
      '[$tag] ℹ️  $message$payload',
      name: 'TeleMedCare',
      level: 800, // INFO
    );
  }

  /// Log a warning message.
  static void warning(String tag, String message, [Object? data]) {
    final payload = data != null ? ' | $data' : '';
    developer.log(
      '[$tag] ⚠️  $message$payload',
      name: 'TeleMedCare',
      level: 900, // WARNING
    );
  }

  /// Log an error message with optional error and stack trace.
  static void error(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      '[$tag] ❌  $message',
      name: 'TeleMedCare',
      level: 1000, // SEVERE
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log a navigation event.
  static void nav(String message) => info('NAV', message);

  /// Log an API call.
  static void api(String message, [Object? data]) => info('API', message, data);

  /// Log an auth event.
  static void auth(String message, [Object? data]) => info('AUTH', message, data);

  /// Log a Socket.IO event.
  static void socket(String message, [Object? data]) => info('SOCKET', message, data);

  /// Log a WebRTC event.
  static void webrtc(String message, [Object? data]) => info('WEBRTC', message, data);

  /// Log an AI/Gemini event.
  static void ai(String message, [Object? data]) => info('AI', message, data);

  /// Log a state change.
  static void state(String message, [Object? data]) => info('STATE', message, data);
}
