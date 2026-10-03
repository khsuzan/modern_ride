import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:modern_ride/core/utils/navigation_math.dart';

/// Renders an oriented vehicle marker that rotates along the shortest angular path
/// to face its exact direction of travel.
class CarMarkerLayer extends StatefulWidget {
  final LatLng position;
  final double bearing;

  const CarMarkerLayer({
    super.key,
    required this.position,
    required this.bearing,
  });

  @override
  State<CarMarkerLayer> createState() => _CarMarkerLayerState();
}

class _CarMarkerLayerState extends State<CarMarkerLayer> {
  double _currentContinuousAngle = 0.0;
  bool _isInitialized = false;

  @override
  void didUpdateWidget(covariant CarMarkerLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bearing != widget.bearing) {
      final delta = NavigationMath.shortestAngleDelta(
        _currentContinuousAngle % 360.0,
        widget.bearing,
      );
      _currentContinuousAngle += delta;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      _currentContinuousAngle = widget.bearing;
      _isInitialized = true;
    }

    return MarkerLayer(
      markers: [
        Marker(
          point: widget.position,
          width: 48,
          height: 48,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: _currentContinuousAngle),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            builder: (context, angleDegrees, child) {
              final radians = angleDegrees * (math.pi / 180.0);
              return Transform.rotate(angle: radians, child: child);
            },
            child: _buildVehicleMarker(),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleMarker() {
    return Center(
      child: Container(
        width: 22,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Headlights (top edge)
            Positioned(
              top: 1,
              left: 2,
              child: Container(
                width: 4,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.amber.shade200,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            Positioned(
              top: 1,
              right: 2,
              child: Container(
                width: 4,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.amber.shade200,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            // Front Windshield
            Positioned(
              top: 9,
              child: Container(
                width: 14,
                height: 7,
                decoration: BoxDecoration(
                  color: const Color(0xFF94A3B8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Roof
            Positioned(
              top: 18,
              child: Container(
                width: 13,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Rear Windshield
            Positioned(
              bottom: 8,
              child: Container(
                width: 14,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF64748B),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Taillights (bottom edge)
            Positioned(
              bottom: 1,
              left: 2,
              child: Container(
                width: 4,
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            Positioned(
              bottom: 1,
              right: 2,
              child: Container(
                width: 4,
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
