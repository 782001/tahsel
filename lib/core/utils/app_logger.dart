import 'dart:developer';

import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  /// Outputs logs only in debug mode
  static void printMessage(dynamic message) {
    if (kDebugMode) {
      print(
        '==================================================[APP PRINT]: $message',
      );
    }
  }

  static void logMessage(dynamic message) {
    if (kDebugMode) {
      log('[APP LOG]: $message');
    }
  }
}
