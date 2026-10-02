import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class LocationPermissionDeniedFailure extends Failure {
  const LocationPermissionDeniedFailure([super.message = 'Location permission was denied.']);
}

class LocationServicesDisabledFailure extends Failure {
  const LocationServicesDisabledFailure([super.message = 'Please enable GPS on your device.']);
}

class UnknownLocationFailure extends Failure {
  const UnknownLocationFailure(super.message);
}