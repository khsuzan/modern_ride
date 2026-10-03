import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

class NavProgress extends Equatable {
  final LatLng currentPosition;
  final double bearing;
  final double remainingDistanceMeters;
  final double remainingDurationSeconds;
  final double progressFraction;
  final bool isCompleted;

  const NavProgress({
    required this.currentPosition,
    required this.bearing,
    required this.remainingDistanceMeters,
    required this.remainingDurationSeconds,
    this.progressFraction = 0.0,
    this.isCompleted = false,
  });

  @override
  List<Object?> get props => [
    currentPosition,
    bearing,
    remainingDistanceMeters,
    remainingDurationSeconds,
    progressFraction,
    isCompleted,
  ];

  @override
  String toString() {
    return 'NavProgress(pos: $currentPosition, bearing: $bearing, remDist: $remainingDistanceMeters, remSecs: $remainingDurationSeconds, done: $isCompleted)';
  }
}
