import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modern_ride/features/map_navigation/domain/entities/ride_navigation_mode.dart';
import 'package:modern_ride/features/map_navigation/domain/entities/route_entity.dart';
import 'package:modern_ride/features/map_navigation/domain/entities/user_location.dart';
import 'package:modern_ride/features/map_navigation/presentation/bloc/location_bloc/location_bloc.dart';
import 'package:modern_ride/features/map_navigation/presentation/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:modern_ride/features/map_navigation/presentation/widgets/navigation_bottom_panel.dart';

class MockNavigationBloc extends Mock implements NavigationBloc {}

void main() {
  late MockNavigationBloc mockNavBloc;

  setUp(() {
    mockNavBloc = MockNavigationBloc();
    when(() => mockNavBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockNavBloc.state).thenReturn(const NavigationInitial());
  });

  Widget buildTestWidget({
    required NavigationState navState,
    required LocationState locState,
    NavigationBloc? navBloc,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<NavigationBloc>.value(
          value: navBloc ?? mockNavBloc,
          child: Stack(
            children: [
              NavigationBottomPanel(
                navState: navState,
                locState: locState,
                selectedMode: RideNavigationMode.simulation,
                onModeChanged: (_) {},
                onStartRide: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  group('NavigationBottomPanel Entrance & Visibility', () {
    testWidgets('remains hidden off-screen while location is being acquired', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          navState: const NavigationInitial(),
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

    testWidgets(
      'slides in when GPS location is confirmed and ready for destination',
      (tester) async {
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
      },
    );

    testWidgets(
      'slides in with permission prompt when location permission is denied',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            navState: const NavigationInitial(),
            locState: const LocationPermissionDenied(
              isPermanentlyDenied: false,
            ),
          ),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        final animatedPositioned = tester.widget<AnimatedPositioned>(
          find.byType(AnimatedPositioned),
        );
        expect(animatedPositioned.bottom, equals(16.0));
        expect(find.text('Location Access Required'), findsOneWidget);
      },
    );

    testWidgets(
      'slides in with settings prompt when location is permanently denied',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            navState: const NavigationInitial(),
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
      },
    );

    testWidgets(
      'dispatches StartNewRide with current live GPS when NEW RIDE is tapped',
      (tester) async {
        const liveGps = UserLocation(latitude: 23.8200, longitude: 90.4200);

        const completedState = NavigationCompleted(
          pickup: LatLng(23.8100, 90.4100),
          destination: LatLng(23.8200, 90.4200),
          route: RouteEntity(
            points: [LatLng(23.8100, 90.4100), LatLng(23.8200, 90.4200)],
            totalDistanceMeters: 1500,
            totalDurationSeconds: 300,
          ),
          finalPosition: LatLng(23.8200, 90.4200),
        );

        await tester.pumpWidget(
          buildTestWidget(
            navState: completedState,
            locState: const LocationLoaded(userLocation: liveGps),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('NEW RIDE'), findsOneWidget);
        await tester.tap(find.text('NEW RIDE'));

        verify(() => mockNavBloc.add(StartNewRide(liveGps.toLatLng))).called(1);
      },
    );
  });
}
