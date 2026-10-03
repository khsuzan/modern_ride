import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:modern_ride/core/utils/navigation_math.dart';

void main() {
  group('NavigationMath', () {
    const p1 = LatLng(23.8103, 90.4125); // Dhaka
    const p2 = LatLng(23.7925, 90.4078); // ~2km south-southwest

    group('haversineDistance', () {
      test('returns 0 for identical points', () {
        expect(NavigationMath.haversineDistance(p1, p1), equals(0.0));
      });

      test('calculates accurate distance between known points', () {
        final dist = NavigationMath.haversineDistance(p1, p2);
        // Distance is approx 2030 meters
        expect(dist, greaterThan(1950.0));
        expect(dist, lessThan(2150.0));
      });

      test('distance is symmetric', () {
        final dist1 = NavigationMath.haversineDistance(p1, p2);
        final dist2 = NavigationMath.haversineDistance(p2, p1);
        expect((dist1 - dist2).abs(), lessThan(0.001));
      });
    });

    group('calculateBearing', () {
      test('calculates North heading (0 degrees)', () {
        const start = LatLng(0.0, 0.0);
        const north = LatLng(1.0, 0.0);
        final bearing = NavigationMath.calculateBearing(start, north);
        expect(bearing, closeTo(0.0, 0.01));
      });

      test('calculates East heading (90 degrees)', () {
        const start = LatLng(0.0, 0.0);
        const east = LatLng(0.0, 1.0);
        final bearing = NavigationMath.calculateBearing(start, east);
        expect(bearing, closeTo(90.0, 0.01));
      });

      test('calculates South heading (180 degrees)', () {
        const start = LatLng(1.0, 0.0);
        const south = LatLng(0.0, 0.0);
        final bearing = NavigationMath.calculateBearing(start, south);
        expect(bearing, closeTo(180.0, 0.01));
      });

      test('calculates West heading (270 degrees)', () {
        const start = LatLng(0.0, 1.0);
        const west = LatLng(0.0, 0.0);
        final bearing = NavigationMath.calculateBearing(start, west);
        expect(bearing, closeTo(270.0, 0.01));
      });
    });

    group('shortestAngleDelta', () {
      test('handles simple clockwise rotation', () {
        expect(NavigationMath.shortestAngleDelta(10.0, 50.0), closeTo(40.0, 0.001));
      });

      test('handles simple counter-clockwise rotation', () {
        expect(NavigationMath.shortestAngleDelta(50.0, 10.0), closeTo(-40.0, 0.001));
      });

      test('wraps across 0/360 boundary clockwise without 350-deg flip', () {
        // From 350° to 10° should rotate +20°, not -340°
        final delta = NavigationMath.shortestAngleDelta(350.0, 10.0);
        expect(delta, closeTo(20.0, 0.001));
      });

      test('wraps across 0/360 boundary counter-clockwise without 350-deg flip', () {
        // From 10° to 350° should rotate -20°, not +340°
        final delta = NavigationMath.shortestAngleDelta(10.0, 350.0);
        expect(delta, closeTo(-20.0, 0.001));
      });

      test('handles identical angles', () {
        expect(NavigationMath.shortestAngleDelta(180.0, 180.0), closeTo(0.0, 0.001));
      });
    });

    group('interpolate', () {
      const a = LatLng(10.0, 20.0);
      const b = LatLng(20.0, 40.0);

      test('returns start point at t = 0', () {
        final result = NavigationMath.interpolate(a, b, 0.0);
        expect(result.latitude, equals(10.0));
        expect(result.longitude, equals(20.0));
      });

      test('returns midpoint at t = 0.5', () {
        final result = NavigationMath.interpolate(a, b, 0.5);
        expect(result.latitude, equals(15.0));
        expect(result.longitude, equals(30.0));
      });

      test('returns end point at t = 1.0', () {
        final result = NavigationMath.interpolate(a, b, 1.0);
        expect(result.latitude, equals(20.0));
        expect(result.longitude, equals(40.0));
      });

      test('clamps t < 0 and t > 1', () {
        final resMin = NavigationMath.interpolate(a, b, -0.5);
        expect(resMin.latitude, equals(10.0));

        final resMax = NavigationMath.interpolate(a, b, 1.5);
        expect(resMax.latitude, equals(20.0));
      });
    });

    group('computeCumulativeDistances', () {
      test('returns empty list for empty points', () {
        expect(NavigationMath.computeCumulativeDistances([]), isEmpty);
      });

      test('returns [0.0] for single point', () {
        expect(NavigationMath.computeCumulativeDistances([p1]), equals([0.0]));
      });

      test('returns cumulative distances for multiple points', () {
        const p3 = LatLng(23.7800, 90.4000);
        final list = [p1, p2, p3];
        final cum = NavigationMath.computeCumulativeDistances(list);

        expect(cum.length, equals(3));
        expect(cum[0], equals(0.0));
        expect(cum[1], equals(NavigationMath.haversineDistance(p1, p2)));
        expect(
          cum[2],
          closeTo(cum[1] + NavigationMath.haversineDistance(p2, p3), 0.001),
        );
      });
    });

    group('projectPointOnSegment', () {
      const a = LatLng(0.0, 0.0);
      const b = LatLng(0.0, 10.0);

      test('projects point onto perpendicular position along segment', () {
        const p = LatLng(5.0, 5.0);
        final projected = NavigationMath.projectPointOnSegment(p, a, b);
        expect(projected.latitude, closeTo(0.0, 0.001));
        expect(projected.longitude, closeTo(5.0, 0.001));
      });

      test('clamps to start point if projection falls before segment', () {
        const p = LatLng(2.0, -5.0);
        final projected = NavigationMath.projectPointOnSegment(p, a, b);
        expect(projected.latitude, equals(a.latitude));
        expect(projected.longitude, equals(a.longitude));
      });

      test('clamps to end point if projection falls beyond segment', () {
        const p = LatLng(2.0, 15.0);
        final projected = NavigationMath.projectPointOnSegment(p, a, b);
        expect(projected.latitude, equals(b.latitude));
        expect(projected.longitude, equals(b.longitude));
      });
    });

    group('computeOffset', () {
      test('computes coordinate at exact distance and bearing', () {
        const start = LatLng(23.8103, 90.4125);
        final offsetPoint = NavigationMath.computeOffset(start, 100.0, 90.0);
        final measuredDist = NavigationMath.haversineDistance(start, offsetPoint);
        final measuredBearing = NavigationMath.calculateBearing(start, offsetPoint);

        expect(measuredDist, closeTo(100.0, 0.5));
        expect(measuredBearing, closeTo(90.0, 0.5));
      });
    });
  });
}
