import 'package:modern_ride/core/utils/result.dart';

import '../entities/location_permission_type.dart';
import '../entities/user_location.dart';

abstract class LocationRepository {
  Future<Result<LocationPermissionType>> checkPermission();
  Future<Result<LocationPermissionType>> requestPermission();
  Future<Result<UserLocation>> getCurrentLocation();
  Stream<Result<UserLocation>> getLocationStream();
  Future<Result<void>> openAppSettings();
}