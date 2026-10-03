import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:modern_ride/core/errors/exceptions.dart';
import 'package:modern_ride/core/utils/app_logger.dart';
import 'package:modern_ride/core/utils/result.dart';
import 'package:modern_ride/features/map_navigation/domain/entities/location_permission_type.dart';
import 'package:modern_ride/features/map_navigation/domain/entities/user_location.dart';
import 'package:modern_ride/features/map_navigation/domain/repositories/location_repository.dart';

part 'location_event.dart';
part 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final LocationRepository locationRepository;

  LocationBloc({required this.locationRepository}) : super(LocationInitial()) {
    on<CheckLocationPermission>(_onCheckLocationPermission);
    on<RequestLocationPermission>(_onRequestLocationPermission);
    on<FetchCurrentLocation>(_onFetchCurrentLocation);
  }
  // Event: Check Location Permission
  void _onCheckLocationPermission(
    LocationEvent event,
    Emitter<LocationState> emit,
  ) async {
    emit(LocationLoading());
    switch (await locationRepository.checkPermission()) {
      case Success(data: final permission):
        _onLocationPermissionCheckSucceed(event, emit, permission);
      case Error(failure: final failure):
        _onLocationPermissionCheckError(event, emit, failure);
    }
  }

  void _onLocationPermissionCheckSucceed(
    LocationEvent event,
    Emitter<LocationState> emit,
    LocationPermissionType permission,
  ) {
    if (permission == LocationPermissionType.granted) {
      AppLogger.debug("Location Permission: Permission Granted");
    } else if (permission == LocationPermissionType.denied) {
      AppLogger.debug("Location Permission: Permission Denied");
      emit(LocationPermissionDenied());
    } else {
      AppLogger.debug("Location Permission: Permission Denied ~ $permission");
      emit(LocationPermissionDenied());
    }
  }

  void _onLocationPermissionCheckError(
    LocationEvent event,
    Emitter<LocationState> emit,
    Failure failure,
  ) {
    AppLogger.error("Location Permission: Error: ${failure.message}");
    emit(LocationError(message: failure.message));
  }

  // Event: Request Location Permission
  void _onRequestLocationPermission(
    LocationEvent event,
    Emitter<LocationState> emit,
  ) async {}
  // Event: Fetch Current Location
  void _onFetchCurrentLocation(
    LocationEvent event,
    Emitter<LocationState> emit,
  ) async {}
}
