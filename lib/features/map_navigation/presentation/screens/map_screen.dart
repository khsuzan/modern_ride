import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../bloc/location_bloc/location_bloc.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapController _mapController;

  // State machine variables
  LatLng? _pickupLocation;
  bool _isPickupConfirmed = false;
  LatLng? _destinationLocation;

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
    if (!_isPickupConfirmed) {
      setState(() {
        _pickupLocation = point;
      });
    }
  }

  void _onMapLongPress(TapPosition tapPosition, LatLng point) {
    // Long Press: Set Destination if pickup is confirmed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<LocationBloc, LocationState>(
        listener: (context, state) {
          if (state is LocationLoaded) {
            final userLatLng = LatLng(
              state.userLocation.latitude,
              state.userLocation.longitude,
            );
            setState(() {
              _pickupLocation = userLatLng;
            });
            _mapController.move(userLatLng, 16.0);
          }
        },
        builder: (context, state) {
          return Stack(
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
                  // Markers Layer
                  MarkerLayer(
                    markers: [
                      // Pickup Marker
                      if (_pickupLocation != null)
                        Marker(
                          point: _pickupLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.green,
                            size: 40,
                          ),
                        ),
                      // Destination Marker
                      if (_destinationLocation != null)
                        Marker(
                          point: _destinationLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.place,
                            color: Colors.red,
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

              // 2. Bottom Confirmation Card
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
                      child: _buildPanelContent(context, state),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPanelContent(BuildContext context, LocationState state) {
    if (state is LocationLoading) {
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

    // Step 1: Pickup Location Selection & Confirmation
    if (!_isPickupConfirmed) {
      if (_pickupLocation != null) {
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
              'Lat: ${_pickupLocation!.latitude.toStringAsFixed(4)}, Lng: ${_pickupLocation!.longitude.toStringAsFixed(4)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isPickupConfirmed = true;
                });
              },
              child: const Text('CONFIRM PICKUP'),
            ),
          ],
        );
      }

      // If location is denied or not acquired yet
      if (state is LocationPermissionDenied) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              state.isPermanentlyDenied
                  ? 'Location Permission Disabled'
                  : 'Location Access Required',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              state.isPermanentlyDenied
                  ? 'Please enable location in device settings, or tap on the map to set pickup manually.'
                  : 'Enable location, or tap anywhere on the map to set pickup manually.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                if (state.isPermanentlyDenied) {
                  context.read<LocationBloc>().add(OpenAppSettings());
                } else {
                  context.read<LocationBloc>().add(RequestLocationPermission());
                }
              },
              child: Text(
                state.isPermanentlyDenied ? 'OPEN SETTINGS' : 'ENABLE LOCATION',
              ),
            ),
          ],
        );
      }

      // Initial un-located state
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

    // Step 2: Pickup Confirmed -> Waiting for Destination
    if (_destinationLocation == null) {
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
                  setState(() {
                    _isPickupConfirmed = false;
                    _destinationLocation = null;
                  });
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

    // Step 3: Both Pickup and Destination are selected -> Ready to Route/Start
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Route Selected',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _destinationLocation = null;
                });
              },
              child: const Text('Reset'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Dest: ${_destinationLocation!.latitude.toStringAsFixed(4)}, ${_destinationLocation!.longitude.toStringAsFixed(4)}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {
            // Next phase: start car navigation along OSRM route
          },
          child: const Text('START RIDE'),
        ),
      ],
    );
  }
}
