import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:modern_ride/features/map_navigation/domain/entities/ride_navigation_mode.dart';
import 'package:modern_ride/features/map_navigation/domain/entities/route_entity.dart';
import 'package:modern_ride/features/map_navigation/presentation/bloc/location_bloc/location_bloc.dart';
import 'package:modern_ride/features/map_navigation/presentation/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:modern_ride/features/map_navigation/presentation/widgets/navigation_hud.dart';

/// Declarative bottom panel container rendering contextual navigation controls
/// and ride information purely derived from [NavigationState] and [LocationState].
/// Declarative bottom panel container rendering contextual navigation controls
/// and ride information purely derived from [NavigationState] and [LocationState].
class NavigationBottomPanel extends StatefulWidget {
  final NavigationState navState;
  final LocationState locState;
  final RideNavigationMode? selectedMode;
  final ValueChanged<RideNavigationMode>? onModeChanged;
  final dynamic onStartRide;
  final Duration entranceDelay;

  const NavigationBottomPanel({
    super.key,
    required this.navState,
    required this.locState,
    this.selectedMode,
    this.onModeChanged,
    this.onStartRide,
    this.entranceDelay = Duration.zero,
  });

  @override
  State<NavigationBottomPanel> createState() => _NavigationBottomPanelState();
}

class _NavigationBottomPanelState extends State<NavigationBottomPanel> {
  late RideNavigationMode _internalMode;

  @override
  void initState() {
    super.initState();
    _internalMode = widget.selectedMode ?? RideNavigationMode.simulation;
  }

  @override
  void didUpdateWidget(covariant NavigationBottomPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedMode != null &&
        widget.selectedMode != oldWidget.selectedMode) {
      _internalMode = widget.selectedMode!;
    }
  }

  RideNavigationMode get _effectiveMode =>
      widget.selectedMode ?? _internalMode;

  void _onModeChanged(RideNavigationMode mode) {
    setState(() => _internalMode = mode);
    widget.onModeChanged?.call(mode);
  }

  void _triggerStartRide() {
    final callback = widget.onStartRide;
    if (callback != null) {
      if (callback is ValueChanged<RideNavigationMode>) {
        callback(_effectiveMode);
      } else if (callback is VoidCallback) {
        callback();
      } else {
        try {
          (callback as dynamic)(_effectiveMode);
        } catch (_) {
          (callback as dynamic)();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Declarative visibility: smoothly hidden only while initial GPS state is undetermined
    final isPanelVisible =
        !(widget.navState is NavigationInitial &&
            (widget.locState is LocationInitial || widget.locState is LocationLoading));

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      left: 16,
      right: 16,
      bottom: isPanelVisible ? 16 : -260,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        opacity: isPanelVisible ? 1.0 : 0.0,
        child: RepaintBoundary(
          child: SafeArea(
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: isPanelVisible
                    ? _buildContent(context)
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return switch (widget.navState) {
      NavigationInitial() => _buildInitialPanel(context, widget.locState),
      PickupSelected(:final pickup) => _buildPickupSelectedPanel(
        context,
        pickup,
      ),
      DestinationSelectionReady() => _buildDestinationPromptPanel(context),
      RouteLoading() => _buildRouteLoadingPanel(),
      RouteReady(:final route) => _buildRouteReadyPanel(context, route),
      Navigating() => NavigationHud(state: widget.navState as Navigating),
      NavigationCompleted(:final route) => _buildCompletedPanel(context, route),
      RouteFailureState(:final message) => _buildRouteFailurePanel(
        context,
        message,
      ),
    };
  }

  Widget _buildInitialPanel(BuildContext context, LocationState locState) {
    if (locState is LocationPermissionDenied) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            locState.isPermanentlyDenied
                ? 'Location Permission Disabled'
                : 'Location Access Required',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            locState.isPermanentlyDenied
                ? 'Please enable location in device settings, or tap on the map to set pickup manually.'
                : 'Enable location, or tap anywhere on the map to set pickup manually.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              if (locState.isPermanentlyDenied) {
                context.read<LocationBloc>().add(OpenAppSettings());
              } else {
                context.read<LocationBloc>().add(RequestLocationPermission());
              }
            },
            child: Text(
              locState.isPermanentlyDenied
                  ? 'OPEN SETTINGS'
                  : 'ENABLE LOCATION',
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Set Your Pickup Location',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          locState is LocationError ? locState.message : 'Use your current location or tap the map to choose a pickup point.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {
            context.read<LocationBloc>().add(RequestLocationPermission());
          },
          child: const Text('USE CURRENT LOCATION'),
        ),
      ],
    );
  }

  Widget _buildPickupSelectedPanel(BuildContext context, LatLng pickup) {
    final userLocation = widget.locState is LocationLoaded
        ? (widget.locState as LocationLoaded).userLocation
        : null;
    final isAtUserLocation =
        userLocation != null &&
        (pickup.latitude - userLocation.latitude).abs() < 0.0001 &&
        (pickup.longitude - userLocation.longitude).abs() < 0.0001;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pickup Location Selected',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (userLocation != null && !isAtUserLocation)
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: const Icon(Icons.my_location, size: 16),
                label: const Text(
                  'My Location',
                  style: TextStyle(fontSize: 12),
                ),
                onPressed: () {
                  context.read<NavigationBloc>().add(
                    SetPickupLocation(userLocation.toLatLng),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          isAtUserLocation
              ? 'Using your current GPS location'
              : 'Lat: ${pickup.latitude.toStringAsFixed(4)}, Lng: ${pickup.longitude.toStringAsFixed(4)}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {
            context.read<NavigationBloc>().add(const ConfirmPickup());
          },
          child: const Text('CONFIRM PICKUP'),
        ),
      ],
    );
  }

  Widget _buildDestinationPromptPanel(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Select Destination',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                context.read<NavigationBloc>().add(
                  const ResetToPickupSelection(),
                );
              },
              child: const Text('Change Pickup'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Long-press anywhere on the map to set your destination pin.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildRouteLoadingPanel() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(width: 12),
          Text(
            'Calculating optimal driving route...',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteReadyPanel(BuildContext context, RouteEntity route) {
    final distanceKm = (route.totalDistanceMeters / 1000).toStringAsFixed(1);
    final durationMin = (route.totalDurationSeconds / 60).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$durationMin min ($distanceKm km)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Fastest route via road network',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                context.read<NavigationBloc>().add(const ClearDestination());
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        SegmentedButton<RideNavigationMode>(
          segments: const [
            ButtonSegment(
              value: RideNavigationMode.simulation,
              label: Text('Simulation'),
              icon: Icon(Icons.play_circle_outline, size: 18),
            ),
            ButtonSegment(
              value: RideNavigationMode.realRide,
              label: Text('Real GPS'),
              icon: Icon(Icons.gps_fixed, size: 18),
            ),
          ],
          selected: {_effectiveMode},
          onSelectionChanged: (modes) => _onModeChanged(modes.first),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _triggerStartRide,
          child: Text(
            _effectiveMode == RideNavigationMode.simulation
                ? 'START SIMULATION'
                : 'START REAL RIDE',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedPanel(BuildContext context, RouteEntity route) {
    final distanceKm = (route.totalDistanceMeters / 1000).toStringAsFixed(1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Destination Reached',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Ride completed successfully ($distanceKm km traveled).',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 14),
        ElevatedButton(
          onPressed: () {
            final userLoc = widget.locState is LocationLoaded
                ? (widget.locState as LocationLoaded).userLocation.toLatLng
                : null;
            context.read<NavigationBloc>().add(StartNewRide(userLoc));
          },
          child: const Text('NEW RIDE'),
        ),
      ],
    );
  }

  Widget _buildRouteFailurePanel(BuildContext context, String message) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Routing Error',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            TextButton(
              onPressed: () {
                context.read<NavigationBloc>().add(const ClearDestination());
              },
              child: const Text('Reset'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          message,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}
