import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:modern_ride/features/map_navigation/presentation/widgets/user_location_marker.dart';

/// Renders the pickup marker on the map.
/// When [isUnifiedWithMyLocation] is true, it combines the GPS radar pulse
/// and wide-angled heading beam at the base with a translucent animated hailing passenger badge above.
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
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0.0, end: -5.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasHeading = widget.isUnifiedWithMyLocation && widget.heading > 0;
    final headingRad = widget.heading * math.pi / 180.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. Ground level: Wide-angled gradient beam & pulse (when unified with user GPS location)
        if (widget.isUnifiedWithMyLocation) ...[
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
        ],

        // 2. Translucent animated floating passenger pickup badge
        AnimatedBuilder(
          animation: _bounceAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                0,
                _bounceAnimation.value -
                    (widget.isUnifiedWithMyLocation ? 22 : 12),
              ),
              child: child,
            );
          },
          child: _buildTranslucentPickupBadge(),
        ),
      ],
    );
  }

  Widget _buildTranslucentPickupBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hail_rounded,
            color: Colors.white,
            size: 14,
          ),
          SizedBox(width: 3),
          Text(
            'Pickup',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
