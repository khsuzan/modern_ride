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
