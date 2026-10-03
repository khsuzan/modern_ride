import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modern_ride/features/map_navigation/presentation/bloc/navigation_bloc/navigation_bloc.dart';

/// Floating Recenter button that appears when user manually pans away from following the car.
class MapRecenterButton extends StatelessWidget {
  final bool isVisible;
  final VoidCallback? onRecenter;

  const MapRecenterButton({
    super.key,
    required this.isVisible,
    this.onRecenter,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      right: 16,
      bottom: isVisible ? 220 : -80,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isVisible ? 1.0 : 0.0,
        child: FloatingActionButton.extended(
          heroTag: 'recenter_btn',
          onPressed: () {
            context.read<NavigationBloc>().add(const RecenterCamera());
            onRecenter?.call();
          },
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1976D2),
          elevation: 4,
          icon: const Icon(Icons.my_location, size: 20),
          label: const Text(
            'RECENTER',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }
}
