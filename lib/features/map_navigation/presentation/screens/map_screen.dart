import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../bloc/location_bloc/location_bloc.dart';
import '../bloc/navigation_bloc/navigation_bloc.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapController _mapController;

  static const LatLng _defaultCenter = LatLng(23.8103, 90.4125);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    final navBloc = context.read<NavigationBloc>();
    final navState = navBloc.state;

    if (navState is NavigationInitial || navState is PickupSelected) {
      navBloc.add(SetPickupLocation(point));
    }
  }

  void _onMapLongPress(TapPosition tapPosition, LatLng point) {
    final navBloc = context.read<NavigationBloc>();
    final navState = navBloc.state;

    if (navState is DestinationSelectionReady ||
        navState is RouteReady ||
        navState is RouteFailureState ||
        navState is RouteLoading) {
      navBloc.add(SelectDestination(point));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm your pickup location first.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _onLocationStateChanged(BuildContext context, LocationState state) {
    if (state is LocationLoaded) {
      final userLatLng = state.userLocation.toLatLng;
      final navBloc = context.read<NavigationBloc>();
      if (navBloc.state is NavigationInitial) {
        navBloc.add(SetPickupLocation(userLatLng));
        _mapController.move(userLatLng, 16.0);
      }
    }
  }

  void _onNavigationStateChanged(BuildContext context, NavigationState state) {
    if (state is RouteReady && state.route.points.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(state.route.points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.only(
            left: 48,
            right: 48,
            top: 64,
            bottom: 220,
          ),
        ),
      );
    } else if (state is RouteFailureState) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<LocationBloc, LocationState>(
          listener: _onLocationStateChanged,
        ),
        BlocListener<NavigationBloc, NavigationState>(
          listener: _onNavigationStateChanged,
        ),
      ],
      child: BlocBuilder<NavigationBloc, NavigationState>(
        builder: (context, navState) {
          return BlocBuilder<LocationBloc, LocationState>(
            builder: (context, locState) {
              return Scaffold(
                body: Stack(
                  children: [
                    // 1. OpenStreetMap Layer
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _defaultCenter,
                        initialZoom: 13.0,
                        onTap: _onMapTap,
                        onLongPress: _onMapLongPress,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.kawsar.modern_ride',
                        ),
                        // Route Polyline Layer
                        PolylineLayer(
                          polylines: [
                            if (navState is RouteReady)
                              Polyline(
                                points: navState.route.points,
                                strokeWidth: 5.0,
                                color: const Color(0xFF1E88E5),
                              ),
                          ],
                        ),
                        // Markers Layer
                        MarkerLayer(
                          markers: [
                            if (navState.pickup != null)
                              Marker(
                                point: navState.pickup!,
                                width: 44,
                                height: 44,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Color(0xFF2E7D32),
                                  size: 40,
                                ),
                              ),
                            if (navState.destination != null)
                              Marker(
                                point: navState.destination!,
                                width: 44,
                                height: 44,
                                child: const Icon(
                                  Icons.flag_rounded,
                                  color: Color(0xFFD32F2F),
                                  size: 40,
                                ),
                              ),
                          ],
                        ),
                        // Required OSM Attribution
                        const SimpleAttributionWidget(
                          source: Text('OpenStreetMap contributors'),
                        ),
                      ],
                    ),

                    // 2. Bottom Confirmation & Info Card
                    Positioned(
                      bottom: 24,
                      left: 16,
                      right: 16,
                      child: SafeArea(
                        top: false,
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 16.0,
                            ),
                            child: _buildPanelContent(
                              context,
                              navState,
                              locState,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPanelContent(
    BuildContext context,
    NavigationState navState,
    LocationState locState,
  ) {
    if (locState is LocationLoading && navState is NavigationInitial) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'Acquiring location...',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return switch (navState) {
      NavigationInitial() => _buildInitialPanel(context, locState),
      PickupSelected(:final pickup) => _buildPickupSelectedPanel(context, pickup),
      DestinationSelectionReady() => _buildDestinationPromptPanel(context),
      RouteLoading() => _buildRouteLoadingPanel(),
      RouteReady(:final route) => _buildRouteReadyPanel(context, route),
      RouteFailureState(:final message) => _buildRouteFailurePanel(context, message),
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
              locState.isPermanentlyDenied ? 'OPEN SETTINGS' : 'ENABLE LOCATION',
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
          'Use your current location or tap the map to choose a pickup point.',
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Pickup Location Selected',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Lat: ${pickup.latitude.toStringAsFixed(4)}, Lng: ${pickup.longitude.toStringAsFixed(4)}',
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
                context.read<NavigationBloc>().add(const ResetToPickupSelection());
              },
              child: const Text('Change Pickup'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Long-press anywhere on the map to set your destination.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
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
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text(
            'Calculating driving route...',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteReadyPanel(BuildContext context, dynamic route) {
    final distanceKm = (route.totalDistanceMeters / 1000).toStringAsFixed(1);
    final durationMin = (route.totalDurationSeconds / 60).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Route Ready',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
        Row(
          children: [
            Icon(Icons.directions_car, size: 18, color: Colors.blue.shade700),
            const SizedBox(width: 6),
            Text(
              '$distanceKm km  •  $durationMin min',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {
            // Next: triggers car navigation animation
          },
          child: const Text('START RIDE'),
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
