import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' show LatLng;

/// Destination marker styled like Uber/Pathao with a ball-dot pinhead
/// and an animated drop-down bounce when placed on the map.
class DestinationMarker extends StatefulWidget {
  final LatLng destination;

  const DestinationMarker({
    super.key,
    required this.destination,
  });

  @override
  State<DestinationMarker> createState() => _DestinationMarkerState();
}

class _DestinationMarkerState extends State<DestinationMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _dropAnimation;
  late final Animation<double> _shadowScaleAnimation;
  late final Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    // Pin drops down from above with a crisp bounce on landing
    _dropAnimation = Tween<double>(begin: -36.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    // Ground shadow expands as the pin approaches the ground
    _shadowScaleAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutQuad),
      ),
    );

    // Ground ripple ring expands right upon impact
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant DestinationMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.destination.latitude != widget.destination.latitude ||
        oldWidget.destination.longitude != widget.destination.longitude) {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // 1. Impact Ground Ripple
            if (_rippleAnimation.value > 0.0)
              Transform.translate(
                offset: const Offset(0, 18),
                child: Opacity(
                  opacity: (1.0 - _rippleAnimation.value).clamp(0.0, 1.0),
                  child: Container(
                    width: 14 + (24 * _rippleAnimation.value),
                    height: 8 + (12 * _rippleAnimation.value),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFD32F2F),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

            // 2. Ground Drop Shadow
            Transform.translate(
              offset: const Offset(0, 18),
              child: Transform.scale(
                scale: _shadowScaleAnimation.value,
                child: Container(
                  width: 16,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.28),
                    borderRadius: const BorderRadius.all(
                      Radius.elliptical(16, 6),
                    ),
                  ),
                ),
              ),
            ),

            // 3. Falling Pin Body (Ball-dot head + pointer needle)
            Transform.translate(
              offset: Offset(0, _dropAnimation.value),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ball dot circular pinhead
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1E2229), // Sleek dark body
                      border: Border.all(
                        color: const Color(0xFFD32F2F), // Red highlight ring
                        width: 2.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white, // Inner white circle
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFD32F2F), // Core ball dot
                        ),
                      ),
                    ),
                  ),
                  // Pointer stem / needle connecting down to ground point
                  CustomPaint(
                    size: const Size(10, 8),
                    painter: _PinTipPainter(
                      color: const Color(0xFF1E2229),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PinTipPainter extends CustomPainter {
  final Color color;

  const _PinTipPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinTipPainter oldDelegate) =>
      oldDelegate.color != color;
}
