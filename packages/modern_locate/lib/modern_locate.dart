import 'dart:async';
import 'models/location_data.dart';
import 'models/location_permission_status.dart';
import 'modern_locate_platform_interface.dart';

export 'models/location_data.dart';
export 'models/location_permission_status.dart';
export 'exceptions/modern_locate_exceptions.dart';

class ModernLocate {
  Future<LocationPermissionStatus> checkPermission() {
    return ModernLocatePlatform.instance.checkPermission();
  }

  Future<LocationPermissionStatus> requestPermission() {
    return ModernLocatePlatform.instance.requestPermission();
  }

  Future<LocationData> getCurrentLocation() {
    return ModernLocatePlatform.instance.getCurrentLocation();
  }

  Stream<LocationData> getLocationStream() {
    return ModernLocatePlatform.instance.getLocationStream();
  }

  Future<void> openAppSettings() {
    return ModernLocatePlatform.instance.openAppSettings();
  }
}