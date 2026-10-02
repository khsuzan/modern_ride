import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'models/location_permission_status.dart';
import 'modern_locate_method_channel.dart';
import 'models/location_data.dart';

abstract class ModernLocatePlatform extends PlatformInterface {
  ModernLocatePlatform() : super(token: _token);

  static final Object _token = Object();
  static ModernLocatePlatform _instance = MethodChannelModernLocate();

  static ModernLocatePlatform get instance => _instance;

  static set instance(ModernLocatePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<LocationPermissionStatus> requestPermission() {
    throw UnimplementedError('requestPermission() has not been implemented.');
  }

  Future<LocationPermissionStatus> checkPermission() {
    throw UnimplementedError('checkPermission() has not been implemented.');
  }

  Future<LocationData> getCurrentLocation() {
    throw UnimplementedError('getCurrentLocation() has not been implemented.');
  }

  Stream<LocationData> getLocationStream() {
    throw UnimplementedError('getLocationStream() has not been implemented.');
  }

  Future<void> openAppSettings() {
    throw UnimplementedError('openAppSettings() has not been implemented.');
  }
}
