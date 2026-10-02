import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_locate/models/location_permission_status.dart';
import 'package:modern_locate/modern_locate_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannelModernLocate platform;
  final List<MethodCall> log = <MethodCall>[];

  setUp(() {
    platform = MethodChannelModernLocate();
    log.clear();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platform.methodChannel, (MethodCall methodCall) async {
      log.add(methodCall);

      switch (methodCall.method) {
        case 'checkPermission':
          return 'granted';
        case 'requestPermission':
          return 'denied';
        case 'getCurrentLocation':
          return <String, dynamic>{
            'latitude': 23.8103,
            'longitude': 90.4125,
            'heading': 90.0,
            'accuracy': 10.0,
          };
        case 'openAppSettings':
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platform.methodChannel, null);
  });

  group('ModernLocateMethodChannel - Permissions', () {
    test('checkPermission returns granted when native returns "granted"', () async {
      final status = await platform.checkPermission();

      expect(status, equals(LocationPermissionStatus.granted));
      expect(log, <Matcher>[
        isMethodCall('checkPermission', arguments: null),
      ]);
    });

    test('checkPermission returns permanentlyDenied when native returns "permanently_denied"', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (call) async => 'permanently_denied');

      final status = await platform.checkPermission();

      expect(status, equals(LocationPermissionStatus.permanentlyDenied));
    });

    test('requestPermission returns denied when native returns "denied"', () async {
      final status = await platform.requestPermission();

      expect(status, equals(LocationPermissionStatus.denied));
      expect(log, <Matcher>[
        isMethodCall('requestPermission', arguments: null),
      ]);
    });
  });

  group('ModernLocateMethodChannel - Location Fix', () {
    test('getCurrentLocation maps native payload to LocationData correctly', () async {
      final location = await platform.getCurrentLocation();

      expect(location.latitude, 23.8103);
      expect(location.longitude, 90.4125);
      expect(location.heading, 90.0);
      expect(location.accuracy, 10.0);
      expect(log, <Matcher>[
        isMethodCall('getCurrentLocation', arguments: null),
      ]);
    });

    test('getCurrentLocation throws Exception when payload is null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (call) async => null);

      expect(
        () async => await platform.getCurrentLocation(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('ModernLocateMethodChannel - App Settings', () {
    test('openAppSettings invokes native channel', () async {
      await platform.openAppSettings();

      expect(log, <Matcher>[
        isMethodCall('openAppSettings', arguments: null),
      ]);
    });
  });
}