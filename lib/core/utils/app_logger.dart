import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  /// Outputs logs only in debug mode
  static void handleLogs(dynamic message) {
    if (kDebugMode) {
      print('[APP LOG]: $message');
    }
  }
}
