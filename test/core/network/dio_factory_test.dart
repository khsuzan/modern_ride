import 'package:flutter_test/flutter_test.dart';
import 'package:modern_ride/core/config/app_config.dart';
import 'package:modern_ride/core/config/flavor_type.dart';
import 'package:modern_ride/core/network/dio_factory.dart';

void main() {
  group('DioFactory', () {
    setUpAll(() {
      AppConfig.current = const AppConfig(
        flavor: FlavorType.dev,
        appTitle: 'ModernRide Dev',
        osrmBaseUrl: 'https://router.project-osrm.org',
        showDevBanner: true,
      );
    });

    test(
      'creates Dio with default configuration using AppConfig osrmBaseUrl',
      () {
        final dio = DioFactory.create();

        expect(dio.options.baseUrl, equals('https://router.project-osrm.org'));
        expect(dio.options.connectTimeout, equals(const Duration(seconds: 10)));
        expect(dio.options.receiveTimeout, equals(const Duration(seconds: 10)));
        expect(dio.options.headers['Accept'], equals('application/json'));
      },
    );

    test('creates Dio with custom baseUrl and custom timeouts', () {
      const customUrl = 'https://custom-router.example.com';
      const customConnectTimeout = Duration(seconds: 5);
      const customReceiveTimeout = Duration(seconds: 7);

      final dio = DioFactory.create(
        baseUrl: customUrl,
        connectTimeout: customConnectTimeout,
        receiveTimeout: customReceiveTimeout,
      );

      expect(dio.options.baseUrl, equals(customUrl));
      expect(dio.options.connectTimeout, equals(customConnectTimeout));
      expect(dio.options.receiveTimeout, equals(customReceiveTimeout));
      expect(dio.options.headers['Accept'], equals('application/json'));
    });
  });
}
