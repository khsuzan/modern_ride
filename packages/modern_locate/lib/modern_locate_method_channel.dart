import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'exceptions/modern_locate_exceptions.dart';
import 'models/location_data.dart';
import 'models/location_permission_status.dart';
import 'modern_locate_platform_interface.dart';

class MethodChannelModernLocate extends ModernLocatePlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('modern_locate/control');

  @visibleForTesting
  final eventChannel = const EventChannel('modern_locate/stream');

  LocationPermissionStatus _parseStatus(String? status) {
    switch (status) {
      case 'granted':
        return LocationPermissionStatus.granted;
      case 'permanently_denied':
        return LocationPermissionStatus.permanentlyDenied;
      default:
        return LocationPermissionStatus.denied;
    }
  }

  @override
  Future<LocationPermissionStatus> checkPermission() async {
    final status = await methodChannel.invokeMethod<String>('checkPermission');
    return _parseStatus(status);
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    final status = await methodChannel.invokeMethod<String>(
      'requestPermission',
    );
    return _parseStatus(status);
  }

  @override
  Future<LocationData> getCurrentLocation() async {
    try {
      final result = await methodChannel.invokeMapMethod<String, dynamic>(
        'getCurrentLocation',
      );
      if (result == null) {
        throw const ModernLocateGenericException(
          'Empty location received from native',
        );
      }
      return LocationData.fromMap(result);
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'PERMISSION_DENIED':
          throw const ModernLocatePermissionException();
        case 'SERVICES_DISABLED':
          throw const ModernLocateGpsDisabledException();
        case 'TIMEOUT':
          throw const ModernLocateTimeoutException();
        default:
          throw ModernLocateGenericException(
            e.message ?? 'Unknown location error',
          );
      }
    }
  }

  @override
  Stream<LocationData> getLocationStream() {
    return eventChannel
        .receiveBroadcastStream()
        .handleError((error) {
          if (error is PlatformException) {
            switch (error.code) {
              case 'PERMISSION_DENIED':
                throw const ModernLocatePermissionException();
              case 'SERVICES_DISABLED':
                throw const ModernLocateGpsDisabledException();
              default:
                throw ModernLocateGenericException(
                  error.message ?? 'Stream error',
                );
            }
          }
          throw error;
        })
        .map((event) => LocationData.fromMap(Map<String, dynamic>.from(event)));
  }

  @override
  Future<void> openAppSettings() async {
    await methodChannel.invokeMethod<void>('openAppSettings');
  }
}
