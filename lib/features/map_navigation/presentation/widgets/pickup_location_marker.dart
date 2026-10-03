import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:modern_ride/features/map_navigation/presentation/widgets/user_location_marker.dart';

/// Pickup location marker styled consistently with the destination marker:
/// A sleek circular pinhead containing the hailing passenger icon (no text)
/// mounted on an 18px (2/3 height) vertical stem pointing directly at the pickup coordinate.
///
/// Features a one-shot animated drop-down sequence when placed or changed,
/// resting completely still with no continuous looping animations.
class PickupLocationMarker extends StatefulWidget {
  final LatLng position;
  final bool isUnifiedWithMyLocation;
  final double heading;

  const PickupLocationMarker({
    super.key,
    required this.position,
    this.isUnifiedWithMyLocation = false,
    this.heading = 0.0,
  });

  @override
  State<PickupLocationMarker> createState() => _PickupLocationMarkerState();
}

class _PickupLocationMarkerState extends State<PickupLocationMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _dropAnimation;
  late final Animation<double> _shadowScaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    // One-shot animated drop sequence (no continuous looping)
    _dropAnimation = Tween<double>(begin: -24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _shadowScaleAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant PickupLocationMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position.latitude != widget.position.latitude ||
        oldWidget.position.longitude != widget.position.longitude) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isUnifiedWithMyLocation) {
      // Standalone pickup marker sign (icon only, 18px stem, one-shot drop)
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Transform.translate(
                offset: Offset(0, _dropAnimation.value),
                child: _buildPickupPin(),
              ),
              Transform.scale(
                scale: _shadowScaleAnimation.value,
                child: Container(
                  width: 8,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: const BorderRadius.all(
                      Radius.elliptical(8, 3),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    // Unified with My GPS Location
    final hasHeading = widget.heading > 0;
    final headingRad = widget.heading * math.pi / 180.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. Ground level: Heading beam, accuracy pulse, and center GPS dot
        if (hasHeading)
          Transform.rotate(
            angle: headingRad,
            child: const CustomPaint(
              size: Size(84, 84),
              painter: LocationHeadingBeamPainter(),
            ),
          ),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.withValues(alpha: 0.18),
          ),
        ),
        Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF1976D2),
          ),
        ),

        // 2. Pickup Pin drops once and rests still above the GPS dot
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -21 + _dropAnimation.value),
              child: child,
            );
          },
          child: _buildPickupPin(),
        ),
      ],
    );
  }

  Widget _buildPickupPin() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Circular pinhead with hailing passenger icon only (no text)
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1976D2), // Blue pickup theme
            border: Border.all(
              color: Colors.white,
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.hail_rounded,
            color: Colors.white,
            size: 13,
          ),
        ),

        // Pen-like handle stem (2/3 height = 18px)
        Container(
          width: 2.5,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF1976D2),
            borderRadius: BorderRadius.circular(1.2),
          ),
        ),
      ],
    );
  }
}
