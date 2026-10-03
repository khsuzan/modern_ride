import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Pure math utility for navigation calculations, geometric projections,
/// bearing calculations, and shortest-turn angle rotations.
class NavigationMath {
  const NavigationMath._();

  static const double _earthRadiusMeters = 6371000.0;
  static const double _degToRad = math.pi / 180.0;
  static const double _radToDeg = 180.0 / math.pi;

  /// Calculates the great-circle distance between two coordinates in meters
  /// using the Haversine formula.
  static double haversineDistance(LatLng p1, LatLng p2) {
    final dLat = (p2.latitude - p1.latitude) * _degToRad;
    final dLon = (p2.longitude - p1.longitude) * _degToRad;

    final lat1 = p1.latitude * _degToRad;
    final lat2 = p2.latitude * _degToRad;

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) * math.sin(dLon / 2) * math.cos(lat1) * math.cos(lat2);
    final clampedA = a.clamp(0.0, 1.0);
    final c = 2 * math.atan2(math.sqrt(clampedA), math.sqrt(1 - clampedA));

    return _earthRadiusMeters * c;
  }

  /// Calculates the initial compass bearing from [from] to [to] in degrees [0, 360).
  ///
  /// North is 0, East is 90, South is 180, West is 270.
  static double calculateBearing(LatLng from, LatLng to) {
    if (from.latitude == to.latitude && from.longitude == to.longitude) {
      return 0.0;
    }
    final lat1 = from.latitude * _degToRad;
    final lat2 = to.latitude * _degToRad;
    final dLon = (to.longitude - from.longitude) * _degToRad;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final radians = math.atan2(y, x);
    final degrees = radians * _radToDeg;

    return (degrees + 360.0) % 360.0;
  }

  /// Calculates the shortest angular difference in degrees (-180, 180]
  /// to rotate from [currentBearing] to [targetBearing].
  ///
  /// Prevents unnatural 350-degree flips when crossing North (0°/360°).
  /// Example: rotating from 350° to 10° yields +20°, not -340°.
  static double shortestAngleDelta(double currentBearing, double targetBearing) {
    return ((targetBearing - currentBearing + 540.0) % 360.0) - 180.0;
  }

  /// Linearly interpolates between coordinate [from] and [to] by fraction [t] in [0, 1].
  static LatLng interpolate(LatLng from, LatLng to, double t) {
    final clampedT = t.clamp(0.0, 1.0);
    final lat = from.latitude + (to.latitude - from.latitude) * clampedT;
    final lon = from.longitude + (to.longitude - from.longitude) * clampedT;
    return LatLng(lat, lon);
  }

  /// Computes cumulative distances in meters along the polyline.
  ///
  /// Result length equals [points.length]. First element is always 0.0.
  static List<double> computeCumulativeDistances(List<LatLng> points) {
    if (points.isEmpty) return const [];
    if (points.length == 1) return const [0.0];

    final distances = List<double>.filled(points.length, 0.0);
    double accumulated = 0.0;

    for (var i = 0; i < points.length - 1; i++) {
      accumulated += haversineDistance(points[i], points[i + 1]);
      distances[i + 1] = accumulated;
    }

    return distances;
  }

  /// Projects a point [p] onto the line segment [[a], [b]], returning the closest [LatLng]
  /// on that segment.
  static LatLng projectPointOnSegment(LatLng p, LatLng a, LatLng b) {
    final segmentLengthSq = _distanceSquared(a, b);
    if (segmentLengthSq == 0) return a;

    // Parameter t of the projection onto the line
    final t = ((p.latitude - a.latitude) * (b.latitude - a.latitude) +
            (p.longitude - a.longitude) * (b.longitude - a.longitude)) /
        segmentLengthSq;

    if (t <= 0.0) return a;
    if (t >= 1.0) return b;

    return LatLng(
      a.latitude + t * (b.latitude - a.latitude),
      a.longitude + t * (b.longitude - a.longitude),
    );
  }

  /// Computes a destination coordinate at [distanceMeters] along [bearingDegrees] from [from].
  static LatLng computeOffset(LatLng from, double distanceMeters, double bearingDegrees) {
    final angularDist = distanceMeters / _earthRadiusMeters;
    final bearingRad = bearingDegrees * _degToRad;
    final lat1 = from.latitude * _degToRad;
    final lon1 = from.longitude * _degToRad;

    final sinLat1 = math.sin(lat1);
    final cosLat1 = math.cos(lat1);
    final sinDist = math.sin(angularDist);
    final cosDist = math.cos(angularDist);

    final sinLat2 = (sinLat1 * cosDist + cosLat1 * sinDist * math.cos(bearingRad)).clamp(-1.0, 1.0);
    final lat2 = math.asin(sinLat2);
    final lon2 = lon1 +
        math.atan2(
          math.sin(bearingRad) * sinDist * cosLat1,
          cosDist - sinLat1 * math.sin(lat2),
        );

    return LatLng(lat2 * _radToDeg, lon2 * _radToDeg);
  }

  static double _distanceSquared(LatLng p1, LatLng p2) {
    final dLat = p1.latitude - p2.latitude;
    final dLon = p1.longitude - p2.longitude;
    return dLat * dLat + dLon * dLon;
  }
}
