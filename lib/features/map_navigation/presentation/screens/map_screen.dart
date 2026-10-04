import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:modern_ride/features/map_navigation/domain/entities/ride_navigation_mode.dart';
import 'package:modern_ride/features/map_navigation/presentation/bloc/location_bloc/location_bloc.dart';
import 'package:modern_ride/features/map_navigation/presentation/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:modern_ride/features/map_navigation/presentation/controllers/map_camera_animator.dart';
import 'package:modern_ride/features/map_navigation/presentation/widgets/map_recenter_button.dart';
import 'package:modern_ride/features/map_navigation/presentation/widgets/navigation_bottom_panel.dart';
import 'package:modern_ride/features/map_navigation/presentation/widgets/navigation_map_view.dart';

/// Single-screen map navigation dashboard coordinating map view, camera tracking,
/// native location stream, and navigation bottom sheet.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final MapController _mapController;
  late final MapCameraAnimator _cameraAnimator;
  NavigationState? _previousNavState;

  static const LatLng _defaultCenter = LatLng(23.8103, 90.4125);
  RideNavigationMode _selectedNavigationMode = RideNavigationMode.simulation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _mapController = MapController();
    _cameraAnimator = MapCameraAnimator(
      mapController: _mapController,
      vsync: this,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraAnimator.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final locBloc = context.read<LocationBloc>();
      if (locBloc.state is! LocationLoaded) {
        locBloc.add(CheckLocationPermission());
      }
    }
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

    if (navState is NavigationInitial || navState is PickupSelected) {
      navBloc.add(SetPickupLocation(point));
    } else if (navState is DestinationSelectionReady ||
        navState is RouteReady ||
        navState is RouteFailureState ||
        navState is RouteLoading) {
      navBloc.add(SelectDestination(point));
    }
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture) {
      _cameraAnimator.cancelAnimation();
      final navBloc = context.read<NavigationBloc>();
      if (navBloc.state is Navigating) {
        navBloc.add(const CameraPanned());
      }
    }
  }

  void _onLocationStateChanged(BuildContext context, LocationState state) {
    if (!mounted) return;
    if (state is LocationLoaded) {
      final userLatLng = state.userLocation.toLatLng;
      final navBloc = context.read<NavigationBloc>();
      if (navBloc.state is NavigationInitial) {
        navBloc.add(SetConfirmedPickup(userLatLng));
        _cameraAnimator.animateTo(destLocation: userLatLng, destZoom: 16.0);
      }
    }
  }

  void _onNavigationStateChanged(BuildContext context, NavigationState state) {
    if (!mounted) return;
    final prevState = _previousNavState;
    _previousNavState = state;

    if (state is RouteReady && state.route.points.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(state.route.points);
      _cameraAnimator.animateToBounds(
        bounds: bounds,
        padding: const EdgeInsets.only(
          left: 48,
          right: 48,
          top: 64,
          bottom: 240,
        ),
      );
    } else if (state is DestinationSelectionReady) {
      _cameraAnimator.animateTo(destLocation: state.pickup, destZoom: 16.0);
    } else if (state is Navigating) {
      if (prevState is! Navigating) {
        _cameraAnimator.animateTo(
          destLocation: state.progress.currentPosition,
          destZoom: 16.0,
        );
      } else if (state.isCameraFollowing) {
        if (!_cameraAnimator.isAnimating) {
          _mapController.move(
            state.progress.currentPosition,
            _mapController.camera.zoom < 15.0
                ? 16.0
                : _mapController.camera.zoom,
          );
        }
      }
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
              final isRecenterVisible =
                  navState is Navigating && !navState.isCameraFollowing;

              return Scaffold(
                body: Stack(
                  children: [
                    // 1. OpenStreetMap View (renders edge-to-edge on isolated GPU layer)
                    RepaintBoundary(
                      child: NavigationMapView(
                        mapController: _mapController,
                        initialCenter: _defaultCenter,
                        navState: navState,
                        userLocation: locState is LocationLoaded
                            ? locState.userLocation
                            : null,
                        onTap: _onMapTap,
                        onLongPress: _onMapLongPress,
                        onPositionChanged: _onPositionChanged,
                      ),
                    ),

                    // 2. Positional Overlay Views wrapped in SafeArea
                    SafeArea(
                      child: Stack(
                        children: [
                          // Floating Recenter Action Button
                          MapRecenterButton(
                            isVisible: isRecenterVisible,
                            onRecenter: () {
                              if (navState is Navigating) {
                                _cameraAnimator.animateTo(
                                  destLocation:
                                      navState.progress.currentPosition,
                                  destZoom: 16.0,
                                );
                              }
                            },
                          ),

                          // Bottom Navigation Action Panel
                          NavigationBottomPanel(
                            navState: navState,
                            locState: locState,
                            selectedMode: _selectedNavigationMode,
                            onModeChanged: (mode) {
                              setState(() => _selectedNavigationMode = mode);
                            },
                            onStartRide: () {
                              context.read<NavigationBloc>().add(
                                StartNavigation(mode: _selectedNavigationMode),
                              );
                            },
                          ),
                        ],
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
}
