import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:modern_ride/core/utils/navigation_math.dart';

/// Renders a modern, aerodynamically styled vehicle marker that smoothly rotates
/// along the shortest angular path to face its exact direction of travel.
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
          width: 38,
          height: 38,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: _currentContinuousAngle),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            builder: (context, angleDegrees, child) {
              final radians = angleDegrees * (math.pi / 180.0);
              return Transform.rotate(angle: radians, child: child);
            },
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 34,
                child: CustomPaint(
                  painter: ModernVehiclePainter(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter rendering a top-down view of a modern aerodynamic EV / sedan.
/// Features a contoured silhouette, side mirrors, aerodynamic creases,
/// panoramic glass greenhouse, modern LED headlights, and full-width rear light bar.
class ModernVehiclePainter extends CustomPainter {
  const ModernVehiclePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft ambient ground shadow beneath vehicle
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    final shadowPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(1.5, 2.5, w - 3.0, h - 2.0),
          const Radius.circular(5.0),
        ),
      );
    canvas.drawPath(shadowPath, shadowPaint);

    // 2. Aerodynamic Side Mirrors
    final mirrorPaint = Paint()..color = const Color(0xFF1E293B);

    // Left mirror
    final leftMirror = Path()
      ..moveTo(1.5, 10.5)
      ..lineTo(0.0, 11.5)
      ..lineTo(0.2, 13.0)
      ..lineTo(1.5, 12.5)
      ..close();
    canvas.drawPath(leftMirror, mirrorPaint);

    // Right mirror
    final rightMirror = Path()
      ..moveTo(w - 1.5, 10.5)
      ..lineTo(w, 11.5)
      ..lineTo(w - 0.2, 13.0)
      ..lineTo(w - 1.5, 12.5)
      ..close();
    canvas.drawPath(rightMirror, mirrorPaint);

    // 3. Main Chassis Silhouette
    final bodyPath = Path()
      ..moveTo(w / 2, 0.8)
      // Front right curve
      ..quadraticBezierTo(w - 2.5, 0.8, w - 1.8, 4.0)
      // Front fender to mirror base
      ..lineTo(w - 1.5, 10.0)
      // Waistline tuck to rear haunches
      ..quadraticBezierTo(w - 2.2, 17.0, w - 1.4, 25.0)
      // Rear haunches to rear bumper corner
      ..quadraticBezierTo(w - 1.2, 31.0, w - 2.5, 33.2)
      // Rear bumper contour
      ..quadraticBezierTo(w / 2, 34.0, 2.5, 33.2)
      // Left rear bumper to rear haunch
      ..quadraticBezierTo(1.2, 31.0, 1.4, 25.0)
      // Left waistline
      ..quadraticBezierTo(2.2, 17.0, 1.5, 10.0)
      // Left front fender
      ..lineTo(1.8, 4.0)
      // Front left curve
      ..quadraticBezierTo(2.5, 0.8, w / 2, 0.8)
      ..close();

    // Body metallic fill (slate / dark graphite gradient)
    final bodyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFF334155),
        Color(0xFF1E293B),
        Color(0xFF0F172A),
      ],
      stops: const [0.0, 0.45, 1.0],
    );

    final bodyPaint = Paint()
      ..shader = bodyGradient.createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(bodyPath, bodyPaint);

    // Body crisp outer contour stroke
    final bodyStrokePaint = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;
    canvas.drawPath(bodyPath, bodyStrokePaint);

    // 4. Bonnet / Hood Aerodynamic Crease Lines
    final hoodLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    canvas.drawLine(
      const Offset(4.8, 4.0),
      const Offset(6.0, 9.2),
      hoodLinePaint,
    );
    canvas.drawLine(
      Offset(w - 4.8, 4.0),
      Offset(w - 6.0, 9.2),
      hoodLinePaint,
    );

    // 5. Cabin Glass Greenhouse (Curved front windshield, panoramic roof, rear glass)
    // Front windshield
    final windshieldPath = Path()
      ..moveTo(4.0, 9.8)
      ..quadraticBezierTo(w / 2, 9.0, w - 4.0, 9.8)
      ..lineTo(w - 4.4, 14.6)
      ..quadraticBezierTo(w / 2, 15.2, 4.4, 14.6)
      ..close();

    final windshieldGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFF64748B),
        Color(0xFF334155),
      ],
    );

    canvas.drawPath(
      windshieldPath,
      Paint()
        ..shader = windshieldGradient.createShader(Rect.fromLTWH(0, 9, w, 6)),
    );

    // Windshield reflection glint
    final reflectionPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    canvas.drawLine(
      const Offset(5.5, 13.8),
      const Offset(7.2, 10.4),
      reflectionPaint,
    );

    // Panoramic high-gloss roof
    final roofPath = Path()
      ..moveTo(4.5, 15.0)
      ..lineTo(w - 4.5, 15.0)
      ..lineTo(w - 4.6, 23.0)
      ..lineTo(4.6, 23.0)
      ..close();

    canvas.drawPath(
      roofPath,
      Paint()..color = const Color(0xFF090D16),
    );

    // Sunroof seam
    canvas.drawLine(
      const Offset(5.2, 19.0),
      Offset(w - 5.2, 19.0),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..strokeWidth = 0.5,
    );

    // Rear windshield
    final rearGlassPath = Path()
      ..moveTo(4.7, 23.4)
      ..quadraticBezierTo(w / 2, 22.8, w - 4.7, 23.4)
      ..lineTo(w - 5.2, 27.6)
      ..quadraticBezierTo(w / 2, 28.2, 5.2, 27.6)
      ..close();

    canvas.drawPath(
      rearGlassPath,
      Paint()..color = const Color(0xFF334155),
    );

    // 6. Modern Front LED Headlights (Crisp Ice-White LED strips)
    final headlightPaint = Paint()
      ..color = const Color(0xFFF8FAFC)
      ..style = PaintingStyle.fill;

    // Left LED headlight
    final leftHeadlight = Path()
      ..moveTo(2.4, 3.4)
      ..lineTo(5.4, 1.8)
      ..lineTo(5.1, 2.9)
      ..lineTo(2.7, 4.3)
      ..close();
    canvas.drawPath(leftHeadlight, headlightPaint);

    // Right LED headlight
    final rightHeadlight = Path()
      ..moveTo(w - 2.4, 3.4)
      ..lineTo(w - 5.4, 1.8)
      ..lineTo(w - 5.1, 2.9)
      ..lineTo(w - 2.7, 4.3)
      ..close();
    canvas.drawPath(rightHeadlight, headlightPaint);

    // 7. Modern Continuous LED Taillight Bar (Full-width sleek red strip)
    final taillightPath = Path()
      ..moveTo(3.6, 32.5)
      ..quadraticBezierTo(w / 2, 33.3, w - 3.6, 32.5)
      ..lineTo(w - 3.8, 33.5)
      ..quadraticBezierTo(w / 2, 34.2, 3.8, 33.5)
      ..close();

    canvas.drawPath(
      taillightPath,
      Paint()..color = const Color(0xFFEF4444),
    );

    // Center taillight accent
    canvas.drawLine(
      Offset((w / 2) - 3.0, 33.0),
      Offset((w / 2) + 3.0, 33.0),
      Paint()
        ..color = const Color(0xFFFCA5A5)
        ..strokeWidth = 0.6,
    );
  }

  @override
  bool shouldRepaint(covariant ModernVehiclePainter oldDelegate) => false;
}
