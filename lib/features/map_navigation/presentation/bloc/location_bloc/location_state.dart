part of 'location_bloc.dart';

sealed class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object> get props => [];
}

final class LocationInitial extends LocationState {}

final class LocationLoading extends LocationState {}

final class LocationPermissionDenied extends LocationState {
  final bool isPermanentlyDenied;
  const LocationPermissionDenied({required this.isPermanentlyDenied});

  @override
  List<Object> get props => [isPermanentlyDenied];
}

final class LocationServiceDisabled extends LocationState {}

final class LocationLoaded extends LocationState {
  final UserLocation userLocation;

  const LocationLoaded({required this.userLocation});

  @override
  List<Object> get props => [userLocation];
}

final class LocationError extends LocationState {
  final String message;

  const LocationError({required this.message});

  @override
  List<Object> get props => [message];
}
