import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:modern_ride/features/map_navigation/domain/entities/ride_navigation_mode.dart';
import 'package:modern_ride/features/map_navigation/domain/entities/user_location.dart';
import 'package:modern_ride/features/map_navigation/presentation/bloc/location_bloc/location_bloc.dart';
import 'package:modern_ride/features/map_navigation/presentation/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:modern_ride/features/map_navigation/presentation/widgets/navigation_bottom_panel.dart';

void main() {
  Widget buildTestWidget({
    required NavigationState navState,
    required LocationState locState,
    Duration entranceDelay = Duration.zero,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            NavigationBottomPanel(
              navState: navState,
              locState: locState,
              selectedMode: RideNavigationMode.simulation,
              onModeChanged: (_) {},
              onStartRide: () {},
              entranceDelay: entranceDelay,
            ),
          ],
        ),
      ),
    );
  }

  group('NavigationBottomPanel Entrance & Visibility', () {
    testWidgets('remains hidden off-screen while location is being acquired', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          navState: NavigationInitial(),
          locState: LocationInitial(),
        ),
      );

      final animatedPositioned = tester.widget<AnimatedPositioned>(
        find.byType(AnimatedPositioned),
      );
      expect(animatedPositioned.bottom, equals(-260.0));

      final animatedOpacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(animatedOpacity.opacity, equals(0.0));
    });

    testWidgets('slides in when GPS location is confirmed and ready for destination', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          navState: const DestinationSelectionReady(
            pickup: LatLng(23.8103, 90.4125),
          ),
          locState: const LocationLoaded(
            userLocation: UserLocation(
              latitude: 23.8103,
              longitude: 90.4125,
              accuracy: 5.0,
              heading: 0.0,
            ),
          ),
        ),
      );

      // Trigger animation
      await tester.pump();
      await tester.pumpAndSettle();

      final animatedPositioned = tester.widget<AnimatedPositioned>(
        find.byType(AnimatedPositioned),
      );
      expect(animatedPositioned.bottom, equals(16.0));

      final animatedOpacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(animatedOpacity.opacity, equals(1.0));

      expect(find.text('Select Destination'), findsOneWidget);
    });

    testWidgets('slides in with permission prompt when location permission is denied', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          navState: NavigationInitial(),
          locState: const LocationPermissionDenied(isPermanentlyDenied: false),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      final animatedPositioned = tester.widget<AnimatedPositioned>(
        find.byType(AnimatedPositioned),
      );
      expect(animatedPositioned.bottom, equals(16.0));
      expect(find.text('Location Access Required'), findsOneWidget);
    });

    testWidgets('slides in with settings prompt when location is permanently denied', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          navState: NavigationInitial(),
          locState: const LocationPermissionDenied(isPermanentlyDenied: true),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      final animatedPositioned = tester.widget<AnimatedPositioned>(
        find.byType(AnimatedPositioned),
      );
      expect(animatedPositioned.bottom, equals(16.0));
      expect(find.text('Location Permission Disabled'), findsOneWidget);
      expect(find.text('OPEN SETTINGS'), findsOneWidget);
    });

    testWidgets('respects choreographed entranceDelay before sliding in', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          navState: const DestinationSelectionReady(
            pickup: LatLng(23.8103, 90.4125),
          ),
          locState: const LocationLoaded(
            userLocation: UserLocation(
              latitude: 23.8103,
              longitude: 90.4125,
            ),
          ),
          entranceDelay: const Duration(milliseconds: 300),
        ),
      );

      // Before delay finishes, panel remains hidden
      await tester.pump(const Duration(milliseconds: 150));
      expect(
        tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned)).bottom,
        equals(-260.0),
      );

      // Once delay fires and animation runs, panel slides in
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(
        tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned)).bottom,
        equals(16.0),
      );
    });
  });
}
