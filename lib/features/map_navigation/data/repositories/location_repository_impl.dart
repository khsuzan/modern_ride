import 'package:modern_ride/core/errors/exceptions.dart';
import 'package:modern_ride/core/utils/result.dart';
import 'package:modern_ride/features/map_navigation/domain/entities/location_permission_type.dart';

import '../../domain/entities/user_location.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_native_datasource.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationNativeDataSource dataSource;

  const LocationRepositoryImpl({required this.dataSource});

  @override
  Future<Result<LocationPermissionType>> checkPermission() async {
    try {
      final status = await dataSource.checkPermission();
      return Success(status);
    } on Failure catch (e) {
      return Error(e);
    } catch (e) {
      return Error(UnknownLocationFailure(e.toString()));
    }
  }

  @override
  Future<Result<LocationPermissionType>> requestPermission() async {
    try {
      final status = await dataSource.requestPermission();
      return Success(status);
    } on Failure catch (e) {
      return Error(e);
    } catch (e) {
      return Error(UnknownLocationFailure(e.toString()));
    }
  }

  @override
  Future<Result<UserLocation>> getCurrentLocation() async {
    try {
      final location = await dataSource.getCurrentLocation();
      return Success(location);
    } on Failure catch (e) {
      return Error(e);
    } catch (e) {
      return Error(UnknownLocationFailure(e.toString()));
    }
  }

  @override
  Stream<Result<UserLocation>> getLocationStream() async* {
    try {
      await for (final location in dataSource.getLocationStream()) {
        yield Success(location);
      }
    } on Failure catch (e) {
      yield Error(e);
    } catch (e) {
      yield Error(UnknownLocationFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> openAppSettings() async {
    try {
      await dataSource.openAppSettings();
      return const Success(null);
    } on Failure catch (e) {
      return Error(e);
    } catch (e) {
      return Error(UnknownLocationFailure(e.toString()));
    }
  }
}
