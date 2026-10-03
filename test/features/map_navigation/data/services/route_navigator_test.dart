import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:modern_ride/core/utils/navigation_math.dart';
import 'package:modern_ride/features/map_navigation/data/services/route_navigator.dart';
import 'package:modern_ride/features/map_navigation/domain/entities/route_entity.dart';

void main() {
  group('RouteNavigator', () {
    const p1 = LatLng(23.8103, 90.4125);
    const p2 = LatLng(23.8000, 90.4100);
    const p3 = LatLng(23.7925, 90.4078);

    final d1 = NavigationMath.haversineDistance(p1, p2);
    final d2 = NavigationMath.haversineDistance(p2, p3);
    final totalDist = d1 + d2;

    final testRoute = RouteEntity(
      points: const [p1, p2, p3],
      totalDistanceMeters: totalDist,
      totalDurationSeconds: 120.0,
    );

    test('initialProgress returns start point with 0 progress fraction', () {
      final navigator = RouteNavigator(route: testRoute);
      final progress = navigator.initialProgress;

      expect(progress.currentPosition, equals(p1));
      expect(progress.remainingDistanceMeters, equals(totalDist));
      expect(progress.remainingDurationSeconds, equals(120.0));
      expect(progress.progressFraction, equals(0.0));
      expect(progress.isCompleted, isFalse);
      expect(progress.isOffRoute, isFalse);
    });

    test('advanceDistance correctly moves car along first segment', () {
      final navigator = RouteNavigator(route: testRoute);
      final halfD1 = d1 / 2.0;

      final progress = navigator.advanceDistance(halfD1);

      expect(progress.currentPosition.latitude, closeTo((p1.latitude + p2.latitude) / 2.0, 0.0001));
      expect(progress.currentPosition.longitude, closeTo((p1.longitude + p2.longitude) / 2.0, 0.0001));
      expect(progress.remainingDistanceMeters, closeTo(totalDist - halfD1, 0.1));
      expect(progress.isCompleted, isFalse);
      expect(progress.isOffRoute, isFalse);
    });

    test('advanceDistance transitions past segment 1 into segment 2', () {
      final navigator = RouteNavigator(route: testRoute);
      final pastFirstSegment = d1 + (d2 / 2.0);

      final progress = navigator.advanceDistance(pastFirstSegment);

      expect(progress.currentPosition.latitude, closeTo((p2.latitude + p3.latitude) / 2.0, 0.0001));
      expect(progress.currentPosition.longitude, closeTo((p2.longitude + p3.longitude) / 2.0, 0.0001));
      expect(progress.isCompleted, isFalse);
    });

    test('advanceDistance clamps to destination and marks completed', () {
      final navigator = RouteNavigator(route: testRoute);

      final progress = navigator.advanceDistance(totalDist + 500.0);

      expect(progress.currentPosition, equals(p3));
      expect(progress.remainingDistanceMeters, equals(0.0));
      expect(progress.remainingDurationSeconds, equals(0.0));
      expect(progress.progressFraction, equals(1.0));
      expect(progress.isCompleted, isTrue);
    });

    test('advanceTick advances distance at 1x nominal speed', () {
      final nav = RouteNavigator(route: testRoute);
      const dt = 2.0; // 2 seconds
      final progress = nav.advanceTick(dtSeconds: dt);
      final expectedDelta = nav.nominalSpeedMps * dt;

      expect(progress.remainingDistanceMeters, closeTo(totalDist - expectedDelta, 0.1));
    });

    test('reset restores navigator to initial start point', () {
      final navigator = RouteNavigator(route: testRoute);
      navigator.advanceDistance(totalDist);
      expect(navigator.traveledDistanceMeters, equals(totalDist));

      navigator.reset();
      expect(navigator.traveledDistanceMeters, equals(0.0));
      final progress = navigator.advanceDistance(0.0);
      expect(progress.currentPosition, equals(p1));
    });

    test('updateRealLocation snaps to route when within 50m threshold', () {
      final navigator = RouteNavigator(route: testRoute);

      // Midpoint of segment 1 displaced by ~15 meters
      final midpoint = LatLng((p1.latitude + p2.latitude) / 2, (p1.longitude + p2.longitude) / 2);
      final closeToRoute = NavigationMath.computeOffset(midpoint, 15.0, 90.0);

      final progress = navigator.updateRealLocation(closeToRoute, gpsHeading: 180.0);

      expect(progress.isOffRoute, isFalse);
      expect(progress.deviationDistanceMeters, closeTo(15.0, 1.0));
      // Position snaps to route segment, not raw offset
      expect(progress.currentPosition.latitude, closeTo(midpoint.latitude, 0.001));
      expect(progress.currentPosition.longitude, closeTo(midpoint.longitude, 0.001));
    });

    test('updateRealLocation detects off-route when exceeding 50m threshold', () {
      final navigator = RouteNavigator(route: testRoute);

      // Midpoint of segment 1 displaced by 80 meters (> 50m)
      final midpoint = LatLng((p1.latitude + p2.latitude) / 2, (p1.longitude + p2.longitude) / 2);
      final farFromRoute = NavigationMath.computeOffset(midpoint, 80.0, 90.0);

      final progress = navigator.updateRealLocation(farFromRoute, gpsHeading: 180.0);

      expect(progress.isOffRoute, isTrue);
      expect(progress.deviationDistanceMeters, closeTo(80.0, 2.0));
      // Displays actual off-route coordinates
      expect(progress.currentPosition, equals(farFromRoute));
    });

    test('deviateCurrentPosition shifts simulated position off route (>50m)', () {
      final navigator = RouteNavigator(route: testRoute);
      final progress = navigator.deviateCurrentPosition(distanceMeters: 65.0);

      expect(progress.isOffRoute, isTrue);
      expect(progress.deviationDistanceMeters, closeTo(65.0, 2.0));
    });

    test('updateRealLocation marks completed when within arrival threshold of destination', () {
      final navigator = RouteNavigator(route: testRoute);

      // Point within 5 meters of destination
      final nearDestination = NavigationMath.computeOffset(p3, 5.0, 0.0);
      final progress = navigator.updateRealLocation(nearDestination);

      expect(progress.remainingDistanceMeters, closeTo(0.0, 6.0));
      expect(progress.isCompleted, isTrue);
    });

    group('Messy Route Robustness (repeated / duplicate / closely spaced points)', () {
      test('does not crash or produce NaN when route has repeated identical points', () {
        const messyRoute = RouteEntity(
          points: [p1, p1, p2, p2, p3, p3],
          totalDistanceMeters: 2000.0,
          totalDurationSeconds: 120.0,
        );

        final nav = RouteNavigator(route: messyRoute);
        expect(nav.currentBearing.isNaN, isFalse);
        expect(nav.currentBearing.isInfinite, isFalse);

        // Advance through all points
        for (var step = 0; step < 20; step++) {
          final progress = nav.advanceDistance(100.0);
          expect(progress.currentPosition.latitude.isNaN, isFalse);
          expect(progress.currentPosition.longitude.isNaN, isFalse);
          expect(progress.currentPosition.latitude.isInfinite, isFalse);
          expect(progress.currentPosition.longitude.isInfinite, isFalse);
          expect(progress.bearing.isNaN, isFalse);
          expect(progress.bearing.isInfinite, isFalse);
          expect(progress.remainingDistanceMeters.isNaN, isFalse);
          expect(progress.progressFraction.isNaN, isFalse);
        }
      });

      test('does not crash or stutter on sub-millimeter closely spaced points', () {
        const microP1 = LatLng(23.8103000, 90.4125000);
        const microP2 = LatLng(23.8103001, 90.4125001); // ~1.5 centimeters apart
        const microP3 = LatLng(23.8103002, 90.4125002);

        const microRoute = RouteEntity(
          points: [microP1, microP2, microP3],
          totalDistanceMeters: 0.03,
          totalDurationSeconds: 1.0,
        );

        final nav = RouteNavigator(route: microRoute);
        final progress = nav.advanceTick(dtSeconds: 0.1);

        expect(progress.currentPosition.latitude.isNaN, isFalse);
        expect(progress.currentPosition.longitude.isNaN, isFalse);
        expect(progress.bearing.isNaN, isFalse);
        expect(progress.progressFraction.isNaN, isFalse);
      });

      test('handles updating real location on route with repeated points', () {
        const messyRoute = RouteEntity(
          points: [p1, p1, p2, p2, p3],
          totalDistanceMeters: 2000.0,
          totalDurationSeconds: 120.0,
        );

        final nav = RouteNavigator(route: messyRoute);
        final progress = nav.updateRealLocation(p1);

        expect(progress.currentPosition.latitude.isNaN, isFalse);
        expect(progress.currentPosition.longitude.isNaN, isFalse);
        expect(progress.bearing.isNaN, isFalse);
        expect(progress.isOffRoute, isFalse);
      });
    });
  });
}
