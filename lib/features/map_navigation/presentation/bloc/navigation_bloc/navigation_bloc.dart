import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import 'package:modern_ride/core/constants/app_constants.dart';
import 'package:modern_ride/core/utils/bloc_transformers.dart';
import 'package:modern_ride/core/utils/result.dart';
import 'package:modern_ride/features/map_navigation/domain/entities/nav_progress.dart';
import 'package:modern_ride/features/map_navigation/domain/entities/ride_navigation_mode.dart';
import 'package:modern_ride/features/map_navigation/domain/entities/route_entity.dart';
import 'package:modern_ride/features/map_navigation/domain/entities/user_location.dart';
import 'package:modern_ride/features/map_navigation/data/services/route_navigator.dart';
import 'package:modern_ride/features/map_navigation/domain/repositories/location_repository.dart';
import 'package:modern_ride/features/map_navigation/domain/repositories/route_repository.dart';

part 'navigation_event.dart';
part 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  final RouteRepository routeRepository;
  final LocationRepository locationRepository;
  final Duration simulationTickInterval;

  static const Duration _debounceDuration = Duration(milliseconds: 300);

  RouteNavigator? _navigator;
  Timer? _simulationTimer;
  StreamSubscription<Result<UserLocation>>? _locationSubscription;
  bool _isRerouting = false;
  DateTime? _lastRerouteTime;

  NavigationBloc({
    required this.routeRepository,
    required this.locationRepository,
    this.simulationTickInterval = const Duration(milliseconds: 100),
  }) : super(const NavigationInitial()) {
    on<SetPickupLocation>(_onSetPickupLocation);
    on<ConfirmPickup>(_onConfirmPickup);
    on<SetConfirmedPickup>(_onSetConfirmedPickup);
    on<SelectDestination>(
      _onSelectDestination,
      transformer: debounceRestartable(duration: _debounceDuration),
    );
    on<ResetToPickupSelection>(_onResetToPickupSelection);
    on<ClearDestination>(_onClearDestination);
    on<StartNavigation>(_onStartNavigation);
    on<ResetNavigation>(_onResetNavigation);
    on<NavigationTick>(_onNavigationTick);
    on<LocationStreamUpdated>(_onLocationStreamUpdated);
    on<TriggerSimulatedDeviation>(_onTriggerSimulatedDeviation);
    on<RecenterCamera>(_onRecenterCamera);
    on<CameraPanned>(_onCameraPanned);
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

  void _onSetConfirmedPickup(
    SetConfirmedPickup event,
    Emitter<NavigationState> emit,
  ) {
    if (state is NavigationInitial || state is PickupSelected) {
      emit(DestinationSelectionReady(pickup: event.pickup));
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

  void _onStartNavigation(
    StartNavigation event,
    Emitter<NavigationState> emit,
  ) {
    final currentRoute = state.route;
    final currentPickup = state.pickup;
    final currentDestination = state.destination;

    if (currentRoute == null || currentPickup == null || currentDestination == null) {
      return;
    }

    _stopNavigationStreams();
    _navigator = RouteNavigator(route: currentRoute);
    _isRerouting = false;
    _lastRerouteTime = null;

    emit(Navigating(
      pickup: currentPickup,
      destination: currentDestination,
      route: currentRoute,
      progress: _navigator!.initialProgress,
      mode: event.mode,
    ));

    if (event.mode == RideNavigationMode.simulation) {
      _simulationTimer = Timer.periodic(
        simulationTickInterval,
        (_) => add(const NavigationTick()),
      );
    } else {
      _locationSubscription = locationRepository.getLocationStream().listen(
        (result) {
          if (result is Success<UserLocation>) {
            add(LocationStreamUpdated(result.data));
          }
        },
      );
    }
  }

  void _onNavigationTick(
    NavigationTick event,
    Emitter<NavigationState> emit,
  ) {
    if (state is! Navigating || _navigator == null) return;
    final currentNavState = state as Navigating;

    final dtSeconds = simulationTickInterval.inMilliseconds / 1000.0;
    final progress = _navigator!.advanceTick(
      dtSeconds: dtSeconds,
    );

    if (progress.isCompleted) {
      _stopNavigationStreams();
      emit(NavigationCompleted(
        pickup: currentNavState.pickup,
        destination: currentNavState.destination,
        route: currentNavState.route,
        finalPosition: progress.currentPosition,
      ));
    } else {
      emit(currentNavState.copyWith(progress: progress));
    }
  }

  Future<void> _onLocationStreamUpdated(
    LocationStreamUpdated event,
    Emitter<NavigationState> emit,
  ) async {
    if (state is! Navigating || _navigator == null) return;
    final currentNavState = state as Navigating;

    final progress = _navigator!.updateRealLocation(
      event.location.toLatLng,
      gpsHeading: event.location.heading,
    );

    if (progress.isCompleted) {
      _stopNavigationStreams();
      emit(NavigationCompleted(
        pickup: currentNavState.pickup,
        destination: currentNavState.destination,
        route: currentNavState.route,
        finalPosition: progress.currentPosition,
      ));
      return;
    }

    emit(currentNavState.copyWith(progress: progress));

    if (progress.isOffRoute) {
      await _handleReroute(currentNavState, progress.currentPosition, emit);
    }
  }

  Future<void> _onTriggerSimulatedDeviation(
    TriggerSimulatedDeviation event,
    Emitter<NavigationState> emit,
  ) async {
    if (state is! Navigating || _navigator == null) return;
    final currentNavState = state as Navigating;

    final progress = _navigator!.deviateCurrentPosition(
      distanceMeters: event.distanceMeters,
    );

    emit(currentNavState.copyWith(progress: progress));

    if (progress.isOffRoute) {
      await _handleReroute(currentNavState, progress.currentPosition, emit);
    }
  }

  Future<void> _handleReroute(
    Navigating currentNavState,
    LatLng currentPosition,
    Emitter<NavigationState> emit,
  ) async {
    if (_isRerouting) return;

    final now = DateTime.now();
    if (_lastRerouteTime != null &&
        now.difference(_lastRerouteTime!) < AppConstants.rerouteCooldown) {
      return;
    }

    _isRerouting = true;
    _lastRerouteTime = now;
    emit(currentNavState.copyWith(isRerouting: true));

    final result = await routeRepository.getRoute(
      start: currentPosition,
      destination: currentNavState.destination,
    );

    _isRerouting = false;

    if (state is! Navigating) return;
    final latestNavState = state as Navigating;

    switch (result) {
      case Success(data: final newRoute):
        _navigator = RouteNavigator(route: newRoute);
        emit(latestNavState.copyWith(
          route: newRoute,
          progress: _navigator!.initialProgress,
          isRerouting: false,
        ));
      case Error():
        emit(latestNavState.copyWith(isRerouting: false));
    }
  }

  void _onResetNavigation(
    ResetNavigation event,
    Emitter<NavigationState> emit,
  ) {
    _stopNavigationStreams();
    _navigator?.reset();
    _isRerouting = false;

    final currentPickup = state.pickup;
    final currentDestination = state.destination;
    final currentRoute = state.route;

    if (currentPickup != null && currentDestination != null && currentRoute != null) {
      emit(RouteReady(
        pickup: currentPickup,
        destination: currentDestination,
        route: currentRoute,
      ));
    }
  }

  void _onRecenterCamera(
    RecenterCamera event,
    Emitter<NavigationState> emit,
  ) {
    if (state is Navigating) {
      emit((state as Navigating).copyWith(isCameraFollowing: true));
    }
  }

  void _onCameraPanned(
    CameraPanned event,
    Emitter<NavigationState> emit,
  ) {
    if (state is Navigating) {
      emit((state as Navigating).copyWith(isCameraFollowing: false));
    }
  }

  void _stopNavigationStreams() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  @override
  Future<void> close() {
    _stopNavigationStreams();
    return super.close();
  }
}
