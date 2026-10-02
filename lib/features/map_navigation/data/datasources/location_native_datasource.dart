import 'package:modern_locate/modern_locate.dart';
import 'package:modern_ride/core/errors/exceptions.dart';

import '../../domain/entities/location_permission_type.dart';
import '../extensions/location_permission_status.dart';
import '../models/user_location_model.dart';

abstract class LocationNativeDataSource {
  Future<LocationPermissionType> checkPermission();
  Future<LocationPermissionType> requestPermission();
  Future<UserLocationModel> getCurrentLocation();
  Stream<UserLocationModel> getLocationStream();
  Future<void> openAppSettings();
}

class LocationNativeDataSourceImpl implements LocationNativeDataSource {
  final ModernLocate _modernLocate;

  LocationNativeDataSourceImpl({ModernLocate? modernLocate})
    : _modernLocate = modernLocate ?? ModernLocate();

  @override
  Future<LocationPermissionType> checkPermission() async {
    try {
      final pluginStatus = await _modernLocate.checkPermission();
      return pluginStatus.toDomain();
    } catch (e) {
      throw const LocationPermissionDeniedFailure();
    }
  }
 @override
  Future<LocationPermissionType> requestPermission() async {
    try {
      final pluginStatus = await _modernLocate.requestPermission();
      return pluginStatus.toDomain();
    } catch (e) {
      throw const LocationPermissionDeniedFailure();
    }
  }

  @override
  Future<UserLocationModel> getCurrentLocation() async {
    try {
      final loc = await _modernLocate.getCurrentLocation();
      return UserLocationModel.fromPlugin(loc);
    } on ModernLocatePermissionException {
      throw const LocationPermissionDeniedFailure();
    } on ModernLocateGpsDisabledException {
      throw const LocationServicesDisabledFailure();
    } on ModernLocateTimeoutException {
      throw const ModernLocateTimeoutException();
    } on ModernLocateException catch (e) {
      throw UnknownLocationFailure(e.message);
    } catch (e) {
      throw UnknownLocationFailure(e.toString());
    }
  }

  @override
  Stream<UserLocationModel> getLocationStream() {
    return _modernLocate.getLocationStream().map(
      (loc) => UserLocationModel.fromPlugin(loc),
    );
  }

  @override
  Future<void> openAppSettings() async {
    await _modernLocate.openAppSettings();
  }
}
