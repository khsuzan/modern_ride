import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:modern_ride/features/map_navigation/domain/entities/user_location.dart';

/// Renders a wide-angled radial gradient heading beam simulating a flashlight cone.
class LocationHeadingBeamPainter extends CustomPainter {
  final double beamAngleDegrees;
  final double radius;
  final Color color;

  const LocationHeadingBeamPainter({
    this.beamAngleDegrees = 65.0,
    this.radius = 42.0,
    this.color = const Color(0xFF1976D2),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final halfAngleRad = (beamAngleDegrees / 2) * math.pi / 180.0;
    final startAngle = -math.pi / 2 - halfAngleRad;
    final sweepAngle = halfAngleRad * 2;

    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
      )
      ..close();

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.45),
          color.withValues(alpha: 0.18),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LocationHeadingBeamPainter oldDelegate) {
    return oldDelegate.beamAngleDegrees != beamAngleDegrees ||
        oldDelegate.radius != radius ||
        oldDelegate.color != color;
  }
}

/// Renders a live user location indicator with radar pulse and wide-angled heading beam.
class UserLocationMarker extends StatelessWidget {
  final UserLocation location;

  const UserLocationMarker({
    super.key,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final hasHeading = location.heading > 0;
    final headingRad = location.heading * math.pi / 180.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Wide-angled gradient heading beam (rotates with real-time heading)
        if (hasHeading)
          Transform.rotate(
            angle: headingRad,
            child: const CustomPaint(
              size: Size(84, 84),
              painter: LocationHeadingBeamPainter(),
            ),
          ),
        // Outer radar pulse circle
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.withValues(alpha: 0.18),
          ),
        ),
        // White border circle
        Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
        // Solid blue center dot
        Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF1976D2),
          ),
        ),
      ],
    );
  }
}
