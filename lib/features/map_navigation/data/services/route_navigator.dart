import 'package:latlong2/latlong.dart';
import 'package:modern_ride/core/constants/app_constants.dart';
import 'package:modern_ride/core/utils/navigation_math.dart';

import '../../domain/entities/nav_progress.dart';
import '../../domain/entities/route_entity.dart';

/// Navigation engine service for simulating vehicle progression along a route
/// or mapping real-time GPS locations onto route polyline segments.
class RouteNavigator {
  final RouteEntity route;
  final List<double> cumulativeDistances;

  double _traveledDistanceMeters = 0.0;
  double _currentBearing = 0.0;

  RouteNavigator({required this.route})
      : cumulativeDistances = NavigationMath.computeCumulativeDistances(route.points) {
    _currentBearing = _findInitialBearing(route.points);
  }

  static double _findInitialBearing(List<LatLng> points) {
    if (points.length < 2) return 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      if (points[i].latitude != points[i + 1].latitude ||
          points[i].longitude != points[i + 1].longitude) {
        return NavigationMath.calculateBearing(points[i], points[i + 1]);
      }
    }
    return 0.0;
  }

  double get traveledDistanceMeters => _traveledDistanceMeters;
  double get totalDistanceMeters => route.totalDistanceMeters;
  double get totalDurationSeconds => route.totalDurationSeconds;
  double get currentBearing => _currentBearing;

  /// Nominal simulation speed in meters/second derived from route metrics (~45 km/h fallback).
  double get nominalSpeedMps {
    if (route.totalDurationSeconds > 0 && route.totalDistanceMeters > 0) {
      return route.totalDistanceMeters / route.totalDurationSeconds;
    }
    return AppConstants.fallbackNominalSpeedMps;
  }

  /// Initial progress at start of route.
  NavProgress get initialProgress {
    if (route.points.isEmpty) {
      return const NavProgress(
        currentPosition: LatLng(0, 0),
        bearing: 0.0,
        remainingDistanceMeters: 0.0,
        remainingDurationSeconds: 0.0,
        progressFraction: 1.0,
        isCompleted: true,
      );
    }

    return NavProgress(
      currentPosition: route.points.first,
      bearing: _currentBearing,
      remainingDistanceMeters: totalDistanceMeters,
      remainingDurationSeconds: totalDurationSeconds,
      progressFraction: 0.0,
      isCompleted: false,
      isOffRoute: false,
      deviationDistanceMeters: 0.0,
    );
  }

  /// Resets the navigator back to the starting point.
  void reset() {
    _traveledDistanceMeters = 0.0;
    _currentBearing = _findInitialBearing(route.points);
  }

  /// Advances vehicle position by simulated elapsed time [dtSeconds] at normal (1x) speed.
  NavProgress advanceTick({required double dtSeconds}) {
    final deltaMeters = nominalSpeedMps * dtSeconds;
    return advanceDistance(deltaMeters);
  }

  /// Advances vehicle progression by [deltaMeters] along the polyline.
  NavProgress advanceDistance(double deltaMeters) {
    if (route.points.isEmpty) {
      return initialProgress;
    }

    if (route.points.length == 1) {
      return NavProgress(
        currentPosition: route.points.first,
        bearing: 0.0,
        remainingDistanceMeters: 0.0,
        remainingDurationSeconds: 0.0,
        progressFraction: 1.0,
        isCompleted: true,
        isOffRoute: false,
        deviationDistanceMeters: 0.0,
      );
    }

    _traveledDistanceMeters += deltaMeters;

    final totalDist = totalDistanceMeters > 0
        ? totalDistanceMeters
        : cumulativeDistances.last;

    if (_traveledDistanceMeters >= totalDist) {
      _traveledDistanceMeters = totalDist;
      return NavProgress(
        currentPosition: route.points.last,
        bearing: _currentBearing,
        remainingDistanceMeters: 0.0,
        remainingDurationSeconds: 0.0,
        progressFraction: 1.0,
        isCompleted: true,
        isOffRoute: false,
        deviationDistanceMeters: 0.0,
      );
    }

    // Locate active polyline segment [i, i+1]
    var segmentIndex = 0;
    for (var i = 0; i < cumulativeDistances.length - 1; i++) {
      if (_traveledDistanceMeters >= cumulativeDistances[i] &&
          _traveledDistanceMeters <= cumulativeDistances[i + 1]) {
        segmentIndex = i;
        break;
      }
    }

    final pA = route.points[segmentIndex];
    final pB = route.points[segmentIndex + 1];
    final segmentStartDist = cumulativeDistances[segmentIndex];
    final segmentEndDist = cumulativeDistances[segmentIndex + 1];
    final segmentLength = segmentEndDist - segmentStartDist;

    final t = segmentLength > 0.0
        ? (_traveledDistanceMeters - segmentStartDist) / segmentLength
        : 0.0;

    final position = NavigationMath.interpolate(pA, pB, t);

    // Update bearing only on non-degenerate segments
    if (segmentLength > 0.0) {
      _currentBearing = NavigationMath.calculateBearing(pA, pB);
    }

    final remainingDist = (totalDist - _traveledDistanceMeters).clamp(0.0, totalDist);
    final progressFraction = totalDist > 0 ? _traveledDistanceMeters / totalDist : 1.0;
    final remainingDuration = (1.0 - progressFraction) * totalDurationSeconds;

    return NavProgress(
      currentPosition: position,
      bearing: _currentBearing,
      remainingDistanceMeters: remainingDist,
      remainingDurationSeconds: remainingDuration.clamp(0.0, totalDurationSeconds),
      progressFraction: progressFraction,
      isCompleted: false,
      isOffRoute: false,
      deviationDistanceMeters: 0.0,
    );
  }

  /// Maps incoming real-time GPS location [userLatLng] onto the route polyline.
  ///
  /// - Snap to route: When [userLatLng] is within 50 meters of the nearest segment,
  ///   the vehicle position snaps to the closest projected point on the segment.
  /// - Off route: When [userLatLng] is more than 50 meters away, [isOffRoute] is set to true
  ///   and the real [userLatLng] is returned.
  NavProgress updateRealLocation(
    LatLng userLatLng, {
    double? gpsHeading,
  }) {
    if (route.points.isEmpty) return initialProgress;
    if (route.points.length == 1) {
      final dist = NavigationMath.haversineDistance(userLatLng, route.points.first);
      final isOff = dist > AppConstants.offRouteThresholdMeters;
      return NavProgress(
        currentPosition: isOff ? userLatLng : route.points.first,
        bearing: gpsHeading ?? 0.0,
        remainingDistanceMeters: 0.0,
        remainingDurationSeconds: 0.0,
        progressFraction: 1.0,
        isCompleted: true,
        isOffRoute: isOff,
        deviationDistanceMeters: dist,
      );
    }

    var bestSegmentIndex = 0;
    var minDistanceToSegment = double.infinity;
    var bestProjectedPoint = route.points.first;

    for (var i = 0; i < route.points.length - 1; i++) {
      final pA = route.points[i];
      final pB = route.points[i + 1];
      final projected = NavigationMath.projectPointOnSegment(userLatLng, pA, pB);
      final dist = NavigationMath.haversineDistance(userLatLng, projected);

      if (dist < minDistanceToSegment) {
        minDistanceToSegment = dist;
        bestSegmentIndex = i;
        bestProjectedPoint = projected;
      }
    }

    final isOffRoute = minDistanceToSegment > AppConstants.offRouteThresholdMeters;
    final displayPosition = isOffRoute ? userLatLng : bestProjectedPoint;

    final pA = route.points[bestSegmentIndex];
    final pB = route.points[bestSegmentIndex + 1];

    if (pA != pB) {
      final segmentBearing = NavigationMath.calculateBearing(pA, pB);
      final bearing = (gpsHeading != null && gpsHeading >= 0)
          ? gpsHeading
          : segmentBearing;
      _currentBearing = bearing;
    } else if (gpsHeading != null && gpsHeading >= 0) {
      _currentBearing = gpsHeading;
    }

    // Traveled distance up to projection
    final startOfSegmentDist = cumulativeDistances[bestSegmentIndex];
    final distAlongSegment = NavigationMath.haversineDistance(pA, bestProjectedPoint);
    _traveledDistanceMeters = startOfSegmentDist + distAlongSegment;

    final totalDist = totalDistanceMeters > 0
        ? totalDistanceMeters
        : cumulativeDistances.last;

    final remainingDist = (totalDist - _traveledDistanceMeters).clamp(0.0, totalDist);
    final progressFraction = totalDist > 0
        ? (_traveledDistanceMeters / totalDist).clamp(0.0, 1.0)
        : 1.0;
    final remainingDuration = (1.0 - progressFraction) * totalDurationSeconds;

    final isDone = remainingDist <= AppConstants.destinationArrivalThresholdMeters;

    return NavProgress(
      currentPosition: displayPosition,
      bearing: _currentBearing,
      remainingDistanceMeters: remainingDist,
      remainingDurationSeconds: remainingDuration.clamp(0.0, totalDurationSeconds),
      progressFraction: progressFraction,
      isCompleted: isDone,
      isOffRoute: isOffRoute,
      deviationDistanceMeters: minDistanceToSegment,
    );
  }

  /// Displaces the current position perpendicular to the route by [distanceMeters]
  /// to test and simulate an off-route deviation (> 50m).
  NavProgress deviateCurrentPosition({double distanceMeters = 60.0}) {
    if (route.points.isEmpty) return initialProgress;
    final currentPos = advanceDistance(0.0).currentPosition;
    final offRoutePoint = NavigationMath.computeOffset(
      currentPos,
      distanceMeters,
      (_currentBearing + 90.0) % 360.0,
    );
    return updateRealLocation(offRoutePoint);
  }
}
