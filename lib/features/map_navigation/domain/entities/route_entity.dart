import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

class RouteEntity extends Equatable {
  final List<LatLng> points;
  final double totalDistanceMeters;
  final double totalDurationSeconds;

  const RouteEntity({
    required this.points,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
  });

  @override
  List<Object?> get props => [
    points,
    totalDistanceMeters,
    totalDurationSeconds,
  ];
}
