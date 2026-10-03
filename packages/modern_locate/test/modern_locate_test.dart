import 'package:flutter_test/flutter_test.dart';
import 'package:modern_locate/modern_locate.dart';
import 'package:modern_locate/modern_locate_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockModernLocatePlatform extends ModernLocatePlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<LocationPermissionStatus> checkPermission() async =>
      LocationPermissionStatus.granted;

  @override
  Future<LocationPermissionStatus> requestPermission() async =>
      LocationPermissionStatus.granted;

  @override
  Future<LocationData> getCurrentLocation() async => const LocationData(
    latitude: 23.8103,
    longitude: 90.4125,
    heading: 0.0,
    accuracy: 5.0,
  );

  @override
  Stream<LocationData> getLocationStream() => Stream.value(
    const LocationData(
      latitude: 23.8103,
      longitude: 90.4125,
      heading: 0.0,
      accuracy: 5.0,
    ),
  );

  @override
  Future<void> openAppSettings() async {}
}

void main() {
  late ModernLocate modernLocate;
  late MockModernLocatePlatform fakePlatform;

  setUp(() {
    modernLocate = ModernLocate();
    fakePlatform = MockModernLocatePlatform();
    ModernLocatePlatform.instance = fakePlatform;
  });

  test('checkPermission delegates to platform instance', () async {
    expect(
      await modernLocate.checkPermission(),
      LocationPermissionStatus.granted,
    );
  });

  test('getCurrentLocation delegates to platform instance', () async {
    final loc = await modernLocate.getCurrentLocation();
    expect(loc.latitude, 23.8103);
    expect(loc.longitude, 90.4125);
  });
}
