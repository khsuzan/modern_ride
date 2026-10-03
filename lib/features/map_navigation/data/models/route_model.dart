import '../../../../core/utils/polyline_decoder.dart';
import '../../domain/entities/route_entity.dart';

class RouteModel extends RouteEntity {
  const RouteModel({
    required super.points,
    required super.totalDistanceMeters,
    required super.totalDurationSeconds,
  });

  factory RouteModel.fromOsrmJson(Map<String, dynamic> json) {
    final routes = json['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) {
      throw const FormatException('No route found in OSRM response.');
    }

    final firstRoute = routes[0] as Map<String, dynamic>;
    final geometryStr = firstRoute['geometry'] as String? ?? '';
    final distance = (firstRoute['distance'] as num?)?.toDouble() ?? 0.0;
    final duration = (firstRoute['duration'] as num?)?.toDouble() ?? 0.0;

    final decodedPoints = PolylineDecoder.decode(geometryStr);

    return RouteModel(
      points: decodedPoints,
      totalDistanceMeters: distance,
      totalDurationSeconds: duration,
    );
  }
}
