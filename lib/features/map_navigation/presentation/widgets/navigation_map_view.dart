import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:modern_ride/core/constants/app_constants.dart';
import 'package:modern_ride/core/utils/navigation_math.dart';
import 'package:modern_ride/features/map_navigation/domain/entities/user_location.dart';
import 'package:modern_ride/features/map_navigation/presentation/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:modern_ride/features/map_navigation/presentation/widgets/car_marker_layer.dart';
import 'package:modern_ride/features/map_navigation/presentation/widgets/destination_marker.dart';
import 'package:modern_ride/features/map_navigation/presentation/widgets/pickup_location_marker.dart';
import 'package:modern_ride/features/map_navigation/presentation/widgets/user_location_marker.dart';

/// Pure map view rendering the OpenStreetMap tiles, route polyline, destination markers,
/// user location dot, pickup marker, and animated car marker layer.
class NavigationMapView extends StatelessWidget {
  final MapController mapController;
  final LatLng initialCenter;
  final double initialZoom;
  final NavigationState navState;
  final UserLocation? userLocation;
  final void Function(TapPosition, LatLng) onTap;
  final void Function(TapPosition, LatLng) onLongPress;
  final void Function(MapCamera, bool) onPositionChanged;

  const NavigationMapView({
    super.key,
    required this.mapController,
    this.initialCenter = const LatLng(23.8103, 90.4125),
    this.initialZoom = 13.0,
    required this.navState,
    this.userLocation,
    required this.onTap,
    required this.onLongPress,
    required this.onPositionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isNavigating = navState is Navigating;
    final isPickupAtMyLocation =
        userLocation != null &&
        navState.pickup != null &&
        NavigationMath.haversineDistance(
              navState.pickup!,
              userLocation!.toLatLng,
            ) <
            15.0;

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
        onTap: onTap,
        onLongPress: onLongPress,
        onPositionChanged: onPositionChanged,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: AppConstants.osmUrlTemplate,
          userAgentPackageName: 'com.kawsar.modern_ride',
        ),
        RichAttributionWidget(
          attributions: const [
            TextSourceAttribution(AppConstants.osmAttribution),
          ],
        ),
        // Route Polyline Layer (hidden when ride is completed)
        PolylineLayer(
          polylines: [
            if (navState.route != null && navState is! NavigationCompleted)
              Polyline(
                points: navState.route!.points,
                strokeWidth: 5.0,
                color: const Color(0xFF1E88E5),
              ),
          ],
        ),
        // Markers Layer (User Location, Pickup & Destination)
        MarkerLayer(
          markers: [
            if (!isNavigating && navState is! NavigationCompleted) ...[
              // When unified: combines live radar beam with floating hailing badge
              if (isPickupAtMyLocation)
                Marker(
                  point: navState.pickup!,
                  width: 84,
                  height: 84,
                  child: PickupLocationMarker(
                    position: navState.pickup!,
                    isUnifiedWithMyLocation: true,
                    heading: userLocation!.heading,
                  ),
                )
              else ...[
                // When split: separate live user location dot and manual pickup badge
                if (userLocation != null)
                  Marker(
                    point: userLocation!.toLatLng,
                    width: 84,
                    height: 84,
                    child: UserLocationMarker(location: userLocation!),
                  ),
                if (navState.pickup != null)
                  Marker(
                    point: navState.pickup!,
                    width: 26,
                    height: 43,
                    alignment: Alignment.topCenter,
                    child: PickupLocationMarker(
                      position: navState.pickup!,
                      isUnifiedWithMyLocation: false,
                    ),
                  ),
              ],
            ],
            // On ride completion: clear pickup and destination markers; show current user GPS location if available
            if (navState is NavigationCompleted && userLocation != null)
              Marker(
                point: userLocation!.toLatLng,
                width: 84,
                height: 84,
                child: UserLocationMarker(location: userLocation!),
              ),
            // Destination Marker (Uber/Pathao ball on 2/3 height pen handle with animated drop)
            if (navState.destination != null &&
                navState is! NavigationCompleted)
              Marker(
                point: navState.destination!,
                width: 28,
                height: 42,
                alignment: Alignment.topCenter,
                child: DestinationMarker(destination: navState.destination!),
              ),
          ],
        ),
        // Oriented Car Marker Layer (during active navigation and parked at final arrival destination)
        if (isNavigating)
          CarMarkerLayer(
            position: (navState as Navigating).progress.currentPosition,
            bearing: (navState as Navigating).progress.bearing,
          )
        else if (navState is NavigationCompleted)
          CarMarkerLayer(
            position: (navState as NavigationCompleted).finalPosition,
            bearing: (navState as NavigationCompleted).route.points.length >= 2
                ? NavigationMath.calculateBearing(
                    (navState as NavigationCompleted).route.points[(navState
                                as NavigationCompleted)
                            .route
                            .points
                            .length -
                        2],
                    (navState as NavigationCompleted).finalPosition,
                  )
                : 0.0,
          ),
      ],
    );
  }
}
