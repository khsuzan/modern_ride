import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modern_ride/features/map_navigation/domain/entities/ride_navigation_mode.dart';
import 'package:modern_ride/features/map_navigation/presentation/bloc/navigation_bloc/navigation_bloc.dart';

/// Navigation Heads-Up Display showing live metrics and navigation controls.
class NavigationHud extends StatelessWidget {
  final Navigating state;

  const NavigationHud({super.key, required this.state});

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  String _formatDuration(double seconds) {
    final totalSecs = seconds.round();
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    if (mins > 0) {
      return '$mins min ${secs.toString().padLeft(2, '0')} s';
    }
    return '$secs s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSimulation = state.mode == RideNavigationMode.simulation;
    final progress = state.progress;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mode badge & Controls Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                isSimulation ? 'SIMULATION' : 'RIDE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isSimulation
                      ? Colors.purple.shade800
                      : Colors.green.shade800,
                ),
              ),
            ),
            Row(
              children: [
                if (isSimulation)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.alt_route_rounded, size: 16),
                    label: const Text(
                      'Test Off-Route',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: state.isRerouting
                        ? null
                        : () {
                            context.read<NavigationBloc>().add(
                              const TriggerSimulatedDeviation(),
                            );
                          },
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.stop_rounded,
                    size: 26,
                    color: Colors.red,
                  ),
                  tooltip: 'Cancel Ride',
                  onPressed: () {
                    context.read<NavigationBloc>().add(const ResetNavigation());
                  },
                ),
              ],
            ),
          ],
        ),

        // Rerouting notification banner
        if (state.isRerouting) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.orange.shade800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Off route (>50m). Recalculating route...',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 8),

        // Linear Route Progress
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.progressFraction.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Live Distance & Duration Metrics
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remaining Distance',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDistance(progress.remainingDistanceMeters),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(width: 1, height: 32, color: Colors.grey.shade300),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remaining Time',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDuration(progress.remainingDurationSeconds),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
