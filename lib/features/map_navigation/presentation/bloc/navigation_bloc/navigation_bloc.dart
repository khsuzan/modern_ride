import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import 'package:modern_ride/core/utils/bloc_transformers.dart';
import 'package:modern_ride/core/utils/result.dart';
import 'package:modern_ride/features/map_navigation/domain/entities/route_entity.dart';
import 'package:modern_ride/features/map_navigation/domain/repositories/route_repository.dart';

part 'navigation_event.dart';
part 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  final RouteRepository routeRepository;

  static const Duration _debounceDuration = Duration(milliseconds: 300);

  NavigationBloc({required this.routeRepository})
      : super(const NavigationInitial()) {
    on<SetPickupLocation>(_onSetPickupLocation);
    on<ConfirmPickup>(_onConfirmPickup);
    on<SelectDestination>(
      _onSelectDestination,
      transformer: debounceRestartable(duration: _debounceDuration),
    );
    on<ResetToPickupSelection>(_onResetToPickupSelection);
    on<ClearDestination>(_onClearDestination);
  }

  void _onSetPickupLocation(
    SetPickupLocation event,
    Emitter<NavigationState> emit,
  ) {
    if (state is NavigationInitial || state is PickupSelected) {
      emit(PickupSelected(pickup: event.pickup));
    }
  }

  void _onConfirmPickup(
    ConfirmPickup event,
    Emitter<NavigationState> emit,
  ) {
    final currentPickup = state.pickup;
    if (currentPickup != null) {
      emit(DestinationSelectionReady(pickup: currentPickup));
    }
  }

  Future<void> _onSelectDestination(
    SelectDestination event,
    Emitter<NavigationState> emit,
  ) async {
    final currentPickup = state.pickup;
    if (currentPickup == null) return;

    emit(RouteLoading(pickup: currentPickup, destination: event.destination));

    final result = await routeRepository.getRoute(
      start: currentPickup,
      destination: event.destination,
    );

    switch (result) {
      case Success(data: final route):
        emit(RouteReady(
          pickup: currentPickup,
          destination: event.destination,
          route: route,
        ));
      case Error(failure: final failure):
        emit(RouteFailureState(
          pickup: currentPickup,
          destination: event.destination,
          message: failure.message,
        ));
    }
  }

  void _onResetToPickupSelection(
    ResetToPickupSelection event,
    Emitter<NavigationState> emit,
  ) {
    final currentPickup = state.pickup;
    if (currentPickup != null) {
      emit(PickupSelected(pickup: currentPickup));
    } else {
      emit(const NavigationInitial());
    }
  }

  void _onClearDestination(
    ClearDestination event,
    Emitter<NavigationState> emit,
  ) {
    final currentPickup = state.pickup;
    if (currentPickup != null) {
      emit(DestinationSelectionReady(pickup: currentPickup));
    }
  }
}
