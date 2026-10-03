part of 'navigation_bloc.dart';

sealed class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object?> get props => [];
}

/// Sets the pickup coordinates before confirmation.
final class SetPickupLocation extends NavigationEvent {
  final LatLng pickup;

  const SetPickupLocation(this.pickup);

  @override
  List<Object?> get props => [pickup];
}

/// Confirms the selected pickup location, unlocking destination selection.
final class ConfirmPickup extends NavigationEvent {
  const ConfirmPickup();
}

/// Sets and immediately confirms the pickup location (used when live GPS fix is available).
final class SetConfirmedPickup extends NavigationEvent {
  final LatLng pickup;

  const SetConfirmedPickup(this.pickup);

  @override
  List<Object?> get props => [pickup];
}

/// Long-presses on map to select destination and fetches driving route.
final class SelectDestination extends NavigationEvent {
  final LatLng destination;

  const SelectDestination(this.destination);

  @override
  List<Object?> get props => [destination];
}

/// Returns to pickup selection stage to adjust pickup.
final class ResetToPickupSelection extends NavigationEvent {
  const ResetToPickupSelection();
}

/// Clears the destination and route, returning to destination selection prompt.
final class ClearDestination extends NavigationEvent {
  const ClearDestination();
}

/// Starts navigation in either [RideNavigationMode.simulation] or [RideNavigationMode.realRide].
final class StartNavigation extends NavigationEvent {
  final RideNavigationMode mode;

  const StartNavigation({this.mode = RideNavigationMode.simulation});

  @override
  List<Object?> get props => [mode];
}

/// Resets navigation back to route preview.
final class ResetNavigation extends NavigationEvent {
  const ResetNavigation();
}

/// Timer tick for moving the simulated vehicle forward.
final class NavigationTick extends NavigationEvent {
  const NavigationTick();
}

/// Location update from real device GPS stream.
final class LocationStreamUpdated extends NavigationEvent {
  final UserLocation location;

  const LocationStreamUpdated(this.location);

  @override
  List<Object?> get props => [location];
}

/// Triggers a simulated 60m deviation off-route to test and demonstrate automatic re-routing.
final class TriggerSimulatedDeviation extends NavigationEvent {
  final double distanceMeters;

  const TriggerSimulatedDeviation({this.distanceMeters = 60.0});

  @override
  List<Object?> get props => [distanceMeters];
}

/// Engages camera tracking to follow vehicle.
final class RecenterCamera extends NavigationEvent {
  const RecenterCamera();
}

/// Disengages camera tracking when user manually pans/drags the map.
final class CameraPanned extends NavigationEvent {
  const CameraPanned();
}
