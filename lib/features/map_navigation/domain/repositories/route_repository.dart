import 'package:latlong2/latlong.dart';
import 'package:modern_ride/core/utils/result.dart';

import '../entities/route_entity.dart';

abstract class RouteRepository {
  Future<Result<RouteEntity>> getRoute({
    required LatLng start,
    required LatLng destination,
  });
}
