part of 'location_bloc.dart';

sealed class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => [];
}

class CheckLocationPermission extends LocationEvent {}

class RequestLocationPermission extends LocationEvent {}

class FetchCurrentLocation extends LocationEvent {}

class StartLocationTracking extends LocationEvent {}

class StopLocationTracking extends LocationEvent {}

class LocationUpdated extends LocationEvent {
  final UserLocation userLocation;

  const LocationUpdated(this.userLocation);

  @override
  List<Object?> get props => [userLocation];
}

class LocationTrackingFailed extends LocationEvent {
  final String message;

  const LocationTrackingFailed(this.message);

  @override
  List<Object?> get props => [message];
}

class OpenAppSettings extends LocationEvent {}
