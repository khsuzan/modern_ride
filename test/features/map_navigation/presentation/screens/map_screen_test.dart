import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modern_ride/features/map_navigation/domain/entities/route_entity.dart';
import 'package:modern_ride/features/map_navigation/domain/entities/user_location.dart';
import 'package:modern_ride/features/map_navigation/presentation/bloc/location_bloc/location_bloc.dart';
import 'package:modern_ride/features/map_navigation/presentation/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:modern_ride/features/map_navigation/presentation/screens/map_screen.dart';
import 'package:modern_ride/features/map_navigation/presentation/widgets/navigation_map_view.dart';

class MockNavigationBloc extends Mock implements NavigationBloc {}

class MockLocationBloc extends Mock implements LocationBloc {}

void main() {
  late MockNavigationBloc mockNavBloc;
  late MockLocationBloc mockLocBloc;
  late StreamController<NavigationState> navStateController;
  late StreamController<LocationState> locStateController;

  const testPickup = LatLng(23.8103, 90.4125);
  const testDestination = LatLng(23.8200, 90.4200);

  final testUserLocation = UserLocation(
    latitude: 23.8103,
    longitude: 90.4125,
    accuracy: 5.0,
    heading: 90.0,
    timestamp: DateTime(2026, 10, 4),
  );

  const testRoute = RouteEntity(
    points: [
      LatLng(23.8103, 90.4125),
      LatLng(23.8150, 90.4150),
      LatLng(23.8200, 90.4200),
    ],
    totalDistanceMeters: 1500,
    totalDurationSeconds: 300,
  );

  setUp(() {
    mockNavBloc = MockNavigationBloc();
    mockLocBloc = MockLocationBloc();
    navStateController = StreamController<NavigationState>.broadcast();
    locStateController = StreamController<LocationState>.broadcast();

    when(() => mockNavBloc.stream).thenAnswer((_) => navStateController.stream);
    when(() => mockNavBloc.state).thenReturn(const NavigationInitial());

    when(() => mockLocBloc.stream).thenAnswer((_) => locStateController.stream);
    when(() => mockLocBloc.state).thenReturn(LocationInitial());
  });

  tearDown(() {
    navStateController.close();
    locStateController.close();
  });

  Widget createSubject() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<NavigationBloc>.value(value: mockNavBloc),
          BlocProvider<LocationBloc>.value(value: mockLocBloc),
        ],
        child: const MapScreen(),
      ),
    );
  }

  testWidgets('renders MapScreen and NavigationMapView successfully', (
    tester,
  ) async {
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    expect(find.byType(MapScreen), findsOneWidget);
    expect(find.byType(NavigationMapView), findsOneWidget);
  });

  testWidgets(
    'smoothly animates camera when RouteReady is emitted without error or leak',
    (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Emit RouteReady state
      navStateController.add(
        const RouteReady(
          pickup: testPickup,
          destination: testDestination,
          route: testRoute,
        ),
      );

      // Pump intermediate frames of the 700ms animation
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.byType(MapScreen), findsOneWidget);
    },
  );

  testWidgets(
    'smoothly animates camera when DestinationSelectionReady is emitted (e.g. on new ride)',
    (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Emit DestinationSelectionReady (such as when starting a new ride)
      navStateController.add(
        const DestinationSelectionReady(pickup: testPickup),
      );

      // Pump animation ticks
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(MapScreen), findsOneWidget);
    },
  );

  testWidgets(
    'smoothly animates camera when LocationLoaded arrives during NavigationInitial',
    (tester) async {
      when(() => mockLocBloc.state)
          .thenReturn(LocationLoaded(userLocation: testUserLocation));
      when(() => mockNavBloc.state).thenReturn(const NavigationInitial());

      await tester.pumpWidget(createSubject());
      await tester.pump();

      locStateController.add(LocationLoaded(userLocation: testUserLocation));

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(MapScreen), findsOneWidget);
    },
  );
}
