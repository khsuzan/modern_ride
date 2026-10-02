import 'package:modern_locate/modern_locate.dart';
import '../../domain/entities/location_permission_type.dart';

extension LocationPermissionStatusX on LocationPermissionStatus {
  LocationPermissionType toDomain() {
    switch (this) {
      case LocationPermissionStatus.granted:
        return LocationPermissionType.granted;
      case LocationPermissionStatus.denied:
        return LocationPermissionType.denied;
      case LocationPermissionStatus.permanentlyDenied:
        return LocationPermissionType.permanentlyDenied;
    }
  }
}