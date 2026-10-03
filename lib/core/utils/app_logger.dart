import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger._();
  static void debug(String message, {String tag = 'DEBUG'}) {
    if (!kDebugMode) return;
    developer.log('🔍 $message', name: tag, time: DateTime.now());
  }

  static void info(String message, {String tag = 'INFO'}) {
    if (!kDebugMode) return;
    developer.log('💡 $message', name: tag, time: DateTime.now());
  }

  static void warning(String message, {String tag = 'WARNING'}) {
    if (!kDebugMode) return;
    developer.log('⚠️ $message', name: tag, time: DateTime.now());
  }

  static void error(
    String message, {
    String tag = 'ERROR',
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) {
      return;
    }
    developer.log(
      '❌ $message',
      name: tag,
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );
  }
}
