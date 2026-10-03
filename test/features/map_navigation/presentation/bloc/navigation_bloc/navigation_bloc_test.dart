import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modern_ride/core/errors/exceptions.dart';
import 'package:modern_ride/core/utils/result.dart';
import 'package:modern_ride/features/map_navigation/domain/entities/route_entity.dart';
import 'package:modern_ride/features/map_navigation/domain/repositories/route_repository.dart';
import 'package:modern_ride/features/map_navigation/presentation/bloc/navigation_bloc/navigation_bloc.dart';

class MockRouteRepository extends Mock implements RouteRepository {}

void main() {
  late MockRouteRepository mockRouteRepository;

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
  });

  NavigationBloc buildBloc() => NavigationBloc(routeRepository: mockRouteRepository);

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
        // Rapid user long-press taps
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
        // Only 1 call made for the latest destination
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

  group('ResetToPickupSelection', () {
    blocTest<NavigationBloc, NavigationState>(
      'emits [PickupSelected] to return from destination selection to pickup confirmation',
      build: buildBloc,
      seed: () => const DestinationSelectionReady(pickup: testPickup),
      act: (bloc) => bloc.add(const ResetToPickupSelection()),
      expect: () => [
        const PickupSelected(pickup: testPickup),
      ],
    );
  });

  group('ClearDestination', () {
    blocTest<NavigationBloc, NavigationState>(
      'emits [DestinationSelectionReady] when clearing an existing route',
      build: buildBloc,
      seed: () => const RouteReady(
        pickup: testPickup,
        destination: testDestination,
        route: testRoute,
      ),
      act: (bloc) => bloc.add(const ClearDestination()),
      expect: () => [
        const DestinationSelectionReady(pickup: testPickup),
      ],
    );
  });
}
