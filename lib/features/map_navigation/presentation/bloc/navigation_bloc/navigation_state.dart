part of 'navigation_bloc.dart';

sealed class NavigationState extends Equatable {
  const NavigationState();

  LatLng? get pickup => switch (this) {
        PickupSelected(:final pickup) => pickup,
        DestinationSelectionReady(:final pickup) => pickup,
        RouteLoading(:final pickup) => pickup,
        RouteReady(:final pickup) => pickup,
        RouteFailureState(:final pickup) => pickup,
        _ => null,
      };

  LatLng? get destination => switch (this) {
        RouteLoading(:final destination) => destination,
        RouteReady(:final destination) => destination,
        RouteFailureState(:final destination) => destination,
        _ => null,
      };

  @override
  List<Object?> get props => [];
}

/// Initial state when no pickup has been selected or acquired.
final class NavigationInitial extends NavigationState {
  const NavigationInitial();
}

/// Pickup point chosen (via GPS or map tap), pending user confirmation.
final class PickupSelected extends NavigationState {
  @override
  final LatLng pickup;

  const PickupSelected({required this.pickup});

  @override
  List<Object?> get props => [pickup];
}

/// Pickup confirmed. Prompting user to long-press map to select destination.
final class DestinationSelectionReady extends NavigationState {
  @override
  final LatLng pickup;

  const DestinationSelectionReady({required this.pickup});

  @override
  List<Object?> get props => [pickup];
}

/// Destination selected, route calculation in-flight via OSRM.
final class RouteLoading extends NavigationState {
  @override
  final LatLng pickup;
  @override
  final LatLng destination;

  const RouteLoading({
    required this.pickup,
    required this.destination,
  });

  @override
  List<Object?> get props => [pickup, destination];
}

/// Route successfully fetched from OSRM, ready to start navigation.
final class RouteReady extends NavigationState {
  @override
  final LatLng pickup;
  @override
  final LatLng destination;
  final RouteEntity route;

  const RouteReady({
    required this.pickup,
    required this.destination,
    required this.route,
  });

  @override
  List<Object?> get props => [pickup, destination, route];
}

/// Route calculation failed (e.g. no road route found, server timeout, rate limit).
final class RouteFailureState extends NavigationState {
  @override
  final LatLng pickup;
  @override
  final LatLng destination;
  final String message;

  const RouteFailureState({
    required this.pickup,
    required this.destination,
    required this.message,
  });

  @override
  List<Object?> get props => [pickup, destination, message];
}
