import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

class DioFactory {
  const DioFactory._();

  static const Duration _defaultConnectTimeout = Duration(seconds: 10);
  static const Duration _defaultReceiveTimeout = Duration(seconds: 10);

  /// Creates and configures a production-grade [Dio] instance.
  static Dio create({
    String? baseUrl,
    Duration connectTimeout = _defaultConnectTimeout,
    Duration receiveTimeout = _defaultReceiveTimeout,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? AppConfig.current.osrmBaseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        headers: const {
          'Accept': 'application/json',
        },
      ),
    );

    // Attach logging only in debug mode
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: false,
          responseHeader: false,
          responseBody: false, // Prevents dumping huge polylines into console
          error: true,
        ),
      );
    }

    return dio;
  }
}
