import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modern_ride/core/errors/exceptions.dart';
import 'package:modern_ride/core/utils/result.dart';
import 'package:modern_ride/features/map_navigation/domain/entities/ride_navigation_mode.dart';
import 'package:modern_ride/features/map_navigation/domain/entities/route_entity.dart';
import 'package:modern_ride/features/map_navigation/domain/repositories/location_repository.dart';
import 'package:modern_ride/features/map_navigation/domain/repositories/route_repository.dart';
import 'package:modern_ride/features/map_navigation/presentation/bloc/navigation_bloc/navigation_bloc.dart';

class MockRouteRepository extends Mock implements RouteRepository {}
class MockLocationRepository extends Mock implements LocationRepository {}

void main() {
  late MockRouteRepository mockRouteRepository;
  late MockLocationRepository mockLocationRepository;

  const testPickup = LatLng(23.8103, 90.4125);
  const testDestination = LatLng(23.7925, 90.4078);

  const testRoute = RouteEntity(
    points: [testPickup, testDestination],
    totalDistanceMeters: 5400.0,
    totalDurationSeconds: 840.0,
  );

  setUpAll(() {
    registerFallbackValue(const LatLng(0, 0));
  });

  setUp(() {
    mockRouteRepository = MockRouteRepository();
    mockLocationRepository = MockLocationRepository();
  });

  NavigationBloc buildBloc() => NavigationBloc(
        routeRepository: mockRouteRepository,
        locationRepository: mockLocationRepository,
      );

  test('initial state is NavigationInitial', () {
    expect(buildBloc().state, equals(const NavigationInitial()));
  });

  group('SetPickupLocation', () {
    blocTest<NavigationBloc, NavigationState>(
      'emits [PickupSelected] when state is NavigationInitial',
      build: buildBloc,
      act: (bloc) => bloc.add(const SetPickupLocation(testPickup)),
      expect: () => [
        const PickupSelected(pickup: testPickup),
      ],
    );

    blocTest<NavigationBloc, NavigationState>(
      'emits [PickupSelected] with updated location when state is already PickupSelected',
      build: buildBloc,
      seed: () => const PickupSelected(pickup: testPickup),
      act: (bloc) => bloc.add(const SetPickupLocation(LatLng(23.82, 90.42))),
      expect: () => [
        const PickupSelected(pickup: LatLng(23.82, 90.42)),
      ],
    );
  });

  group('ConfirmPickup', () {
    blocTest<NavigationBloc, NavigationState>(
      'emits [DestinationSelectionReady] when pickup was selected',
      build: buildBloc,
      seed: () => const PickupSelected(pickup: testPickup),
      act: (bloc) => bloc.add(const ConfirmPickup()),
      expect: () => [
        const DestinationSelectionReady(pickup: testPickup),
      ],
    );

    blocTest<NavigationBloc, NavigationState>(
      'does nothing if pickup is null',
      build: buildBloc,
      act: (bloc) => bloc.add(const ConfirmPickup()),
      expect: () => [],
    );
  });

  group('SetConfirmedPickup', () {
    blocTest<NavigationBloc, NavigationState>(
      'emits [DestinationSelectionReady] directly from NavigationInitial',
      build: buildBloc,
      act: (bloc) => bloc.add(const SetConfirmedPickup(testPickup)),
      expect: () => [
        const DestinationSelectionReady(pickup: testPickup),
      ],
    );

    blocTest<NavigationBloc, NavigationState>(
      'emits [DestinationSelectionReady] when overriding existing PickupSelected',
      build: buildBloc,
      seed: () => const PickupSelected(pickup: LatLng(23.70, 90.30)),
      act: (bloc) => bloc.add(const SetConfirmedPickup(testPickup)),
      expect: () => [
        const DestinationSelectionReady(pickup: testPickup),
      ],
    );
  });

  group('SelectDestination', () {
    blocTest<NavigationBloc, NavigationState>(
      'emits [RouteLoading, RouteReady] when route fetch succeeds after debounce',
      build: () {
        when(
          () => mockRouteRepository.getRoute(
            start: any(named: 'start'),
            destination: any(named: 'destination'),
          ),
        ).thenAnswer((_) async => const Success(testRoute));
        return buildBloc();
      },
      seed: () => const DestinationSelectionReady(pickup: testPickup),
      act: (bloc) => bloc.add(const SelectDestination(testDestination)),
      wait: const Duration(milliseconds: 350),
      expect: () => [
        const RouteLoading(pickup: testPickup, destination: testDestination),
        const RouteReady(
          pickup: testPickup,
          destination: testDestination,
          route: testRoute,
        ),
      ],
      verify: (_) {
        verify(
          () => mockRouteRepository.getRoute(
            start: testPickup,
            destination: testDestination,
          ),
        ).called(1);
      },
    );

    blocTest<NavigationBloc, NavigationState>(
      'debounces rapid destination selection events and only processes the latest destination',
      build: () {
        when(
          () => mockRouteRepository.getRoute(
            start: any(named: 'start'),
            destination: any(named: 'destination'),
          ),
        ).thenAnswer((_) async => const Success(testRoute));
        return buildBloc();
      },
      seed: () => const DestinationSelectionReady(pickup: testPickup),
      act: (bloc) {
        bloc.add(const SelectDestination(LatLng(23.71, 90.31)));
        bloc.add(const SelectDestination(LatLng(23.72, 90.32)));
        bloc.add(const SelectDestination(testDestination));
      },
      wait: const Duration(milliseconds: 350),
      expect: () => [
        const RouteLoading(pickup: testPickup, destination: testDestination),
        const RouteReady(
          pickup: testPickup,
          destination: testDestination,
          route: testRoute,
        ),
      ],
      verify: (_) {
        verify(
          () => mockRouteRepository.getRoute(
            start: testPickup,
            destination: testDestination,
          ),
        ).called(1);
        verifyNever(
          () => mockRouteRepository.getRoute(
            start: testPickup,
            destination: const LatLng(23.71, 90.31),
          ),
        );
      },
    );

    blocTest<NavigationBloc, NavigationState>(
      'emits [RouteLoading, RouteFailureState] when route fetch fails',
      build: () {
        when(
          () => mockRouteRepository.getRoute(
            start: any(named: 'start'),
            destination: any(named: 'destination'),
          ),
        ).thenAnswer(
          (_) async => const Error(NoRouteFoundFailure('No driving route found.')),
        );
        return buildBloc();
      },
      seed: () => const DestinationSelectionReady(pickup: testPickup),
      act: (bloc) => bloc.add(const SelectDestination(testDestination)),
      wait: const Duration(milliseconds: 350),
      expect: () => [
        const RouteLoading(pickup: testPickup, destination: testDestination),
        const RouteFailureState(
          pickup: testPickup,
          destination: testDestination,
          message: 'No driving route found.',
        ),
      ],
    );
  });

  group('StartNavigation', () {
    blocTest<NavigationBloc, NavigationState>(
      'starts simulation navigation from RouteReady and emits Navigating',
      build: buildBloc,
      seed: () => const RouteReady(
        pickup: testPickup,
        destination: testDestination,
        route: testRoute,
      ),
      act: (bloc) => bloc.add(const StartNavigation(mode: RideNavigationMode.simulation)),
      expect: () => [
        isA<Navigating>()
            .having((s) => s.mode, 'mode', RideNavigationMode.simulation)
            .having((s) => s.progress.currentPosition, 'pos', testPickup),
      ],
    );

    blocTest<NavigationBloc, NavigationState>(
      'starts realRide navigation and connects to locationStream',
      build: () {
        when(() => mockLocationRepository.getLocationStream()).thenAnswer(
          (_) => const Stream.empty(),
        );
        return buildBloc();
      },
      seed: () => const RouteReady(
        pickup: testPickup,
        destination: testDestination,
        route: testRoute,
      ),
      act: (bloc) => bloc.add(const StartNavigation(mode: RideNavigationMode.realRide)),
      expect: () => [
        isA<Navigating>()
            .having((s) => s.mode, 'mode', RideNavigationMode.realRide)
            .having((s) => s.progress.currentPosition, 'pos', testPickup),
      ],
      verify: (_) {
        verify(() => mockLocationRepository.getLocationStream()).called(1);
      },
    );
  });

  group('Navigation Controls & Camera Tracking', () {
    late NavigationBloc bloc;

    setUp(() {
      bloc = buildBloc();
    });

    blocTest<NavigationBloc, NavigationState>(
      'resets navigation back to RouteReady',
      build: () => bloc,
      seed: () => const RouteReady(
        pickup: testPickup,
        destination: testDestination,
        route: testRoute,
      ),
      act: (bloc) {
        bloc.add(const StartNavigation(mode: RideNavigationMode.simulation));
        bloc.add(const ResetNavigation());
      },
      expect: () => [
        isA<Navigating>(),
        const RouteReady(
          pickup: testPickup,
          destination: testDestination,
          route: testRoute,
        ),
      ],
    );

    blocTest<NavigationBloc, NavigationState>(
      'updates camera following on pan and recenter',
      build: () => bloc,
      seed: () => const RouteReady(
        pickup: testPickup,
        destination: testDestination,
        route: testRoute,
      ),
      act: (bloc) {
        bloc.add(const StartNavigation(mode: RideNavigationMode.simulation));
        bloc.add(const CameraPanned());
        bloc.add(const RecenterCamera());
      },
      expect: () => [
        isA<Navigating>().having((s) => s.isCameraFollowing, 'following', true),
        isA<Navigating>().having((s) => s.isCameraFollowing, 'following', false),
        isA<Navigating>().having((s) => s.isCameraFollowing, 'following', true),
      ],
    );
  });

  group('Off-Route Detection & Re-Routing', () {
    const rerouted = RouteEntity(
      points: [LatLng(23.82, 90.42), testDestination],
      totalDistanceMeters: 800.0,
      totalDurationSeconds: 60.0,
    );

    blocTest<NavigationBloc, NavigationState>(
      'TriggerSimulatedDeviation fetches new route when >50m off route',
      build: () {
        when(
          () => mockRouteRepository.getRoute(
            start: any(named: 'start'),
            destination: any(named: 'destination'),
          ),
        ).thenAnswer((_) async => const Success(rerouted));
        return buildBloc();
      },
      seed: () => const RouteReady(
        pickup: testPickup,
        destination: testDestination,
        route: testRoute,
      ),
      act: (bloc) {
        bloc.add(const StartNavigation(mode: RideNavigationMode.simulation));
        bloc.add(const TriggerSimulatedDeviation(distanceMeters: 65.0));
      },
      expect: () => [
        isA<Navigating>(),
        isA<Navigating>().having((s) => s.progress.isOffRoute, 'isOffRoute', true),
        isA<Navigating>().having((s) => s.isRerouting, 'isRerouting', true),
        isA<Navigating>()
            .having((s) => s.route, 'route', rerouted)
            .having((s) => s.isRerouting, 'isRerouting', false),
      ],
    );
  });
}

