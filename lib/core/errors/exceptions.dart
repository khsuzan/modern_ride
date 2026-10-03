import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class LocationPermissionDeniedFailure extends Failure {
  const LocationPermissionDeniedFailure([
    super.message = 'Location permission was denied.',
  ]);
}

class LocationServicesDisabledFailure extends Failure {
  const LocationServicesDisabledFailure([
    super.message = 'Please enable GPS on your device.',
  ]);
}

class UnknownLocationFailure extends Failure {
  const UnknownLocationFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}

class NoRouteFoundFailure extends Failure {
  const NoRouteFoundFailure([
    super.message = 'No driving route found to this location.',
  ]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network connection failed.']);
}

class ServerRateLimitFailure extends Failure {
  const ServerRateLimitFailure([
    super.message = 'Routing server is busy. Please try again.',
  ]);
}

// -------------------------------------------------------------
// Exceptions (Data Layer)
// -------------------------------------------------------------
class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server error occurred.']);
}

class NoRouteFoundException implements Exception {
  final String message;
  const NoRouteFoundException([this.message = 'No route found.']);
}

class ServerRateLimitException implements Exception {
  final String message;
  const ServerRateLimitException([this.message = 'Rate limit exceeded.']);
}
