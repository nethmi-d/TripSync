import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static void info(String scope, String message) {
    if (kDebugMode) {
      debugPrint('[TripSync][$scope] $message');
    }
  }

  static void error(String scope, Object error, {StackTrace? stackTrace}) {
    if (!kDebugMode) {
      return;
    }

    debugPrint('[TripSync][$scope][ERROR] $error');
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
