part of 'location_bloc.dart';

sealed class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object> get props => [];
}

class CheckLocationPermission extends LocationEvent {}

class RequestLocationPermission extends LocationEvent {}

class FetchCurrentLocation extends LocationEvent {}
