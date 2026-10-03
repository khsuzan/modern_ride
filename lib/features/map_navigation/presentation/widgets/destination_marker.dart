import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' show LatLng;

/// Destination marker styled like Uber/Pathao:
/// A long sleek pen-like vertical line/handle with a small ball on top,
/// and an animated drop sequence landing right on the pressed coordinate.
class DestinationMarker extends StatefulWidget {
  final LatLng destination;

  const DestinationMarker({super.key, required this.destination});

  @override
  State<DestinationMarker> createState() => _DestinationMarkerState();
}

class _DestinationMarkerState extends State<DestinationMarker>
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

    // Pin drops down from above with an overshoot bounce on landing
    _dropAnimation = Tween<double>(
      begin: -22.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    // Ground shadow expands as the pin tip hits the ground
    _shadowScaleAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
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
        return SizedBox(
          width: 28,
          height: 42,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // 1. Ground contact shadow anchored at bottom (0, 0)
              Positioned(
                bottom: 0,
                child: Transform.scale(
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
              ),

              // 2. The falling pin body anchored directly above ground shadow
              Positioned(
                bottom: 1.5,
                child: Transform.translate(
                  offset: Offset(0, _dropAnimation.value),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Retouched ball on top of pen-like handle
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF18181B), // Sleek obsidian black
                          border: Border.all(
                            color: Colors.white,
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFD32F2F), // Vibrant crimson center core
                          ),
                        ),
                      ),
                      // Pen-like handle / vertical line (2/3 height = 18px)
                      Container(
                        width: 2.5,
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFF18181B),
                          borderRadius: BorderRadius.circular(1.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
