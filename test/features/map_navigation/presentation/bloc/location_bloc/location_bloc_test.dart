import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modern_ride/core/errors/exceptions.dart';
import 'package:modern_ride/core/utils/result.dart';
import 'package:modern_ride/features/map_navigation/domain/entities/location_permission_type.dart';
import 'package:modern_ride/features/map_navigation/domain/entities/user_location.dart';
import 'package:modern_ride/features/map_navigation/domain/repositories/location_repository.dart';
import 'package:modern_ride/features/map_navigation/presentation/bloc/location_bloc/location_bloc.dart';

class MockLocationRepository extends Mock implements LocationRepository {}

void main() {
  late MockLocationRepository mockLocationRepository;

  final testLocation = UserLocation(
    latitude: 23.8103,
    longitude: 90.4125,
    accuracy: 5.0,
  );

  setUp(() {
    mockLocationRepository = MockLocationRepository();
  });

  LocationBloc buildBloc() {
    return LocationBloc(locationRepository: mockLocationRepository);
  }

  test('initial state is LocationInitial', () {
    expect(buildBloc().state, equals(LocationInitial()));
  });

  group('CheckLocationPermission', () {
    blocTest<LocationBloc, LocationState>(
      'emits [LocationPermissionDenied(isPermanentlyDenied: false)] when permission is denied',
      build: () {
        when(() => mockLocationRepository.checkPermission()).thenAnswer(
          (_) async => const Success(LocationPermissionType.denied),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(CheckLocationPermission()),
      expect: () => [
        const LocationPermissionDenied(isPermanentlyDenied: false),
      ],
      verify: (_) {
        verify(() => mockLocationRepository.checkPermission()).called(1);
      },
    );

    blocTest<LocationBloc, LocationState>(
      'emits [LocationPermissionDenied(isPermanentlyDenied: true)] when permission is permanently denied',
      build: () {
        when(() => mockLocationRepository.checkPermission()).thenAnswer(
          (_) async => const Success(LocationPermissionType.permanentlyDenied),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(CheckLocationPermission()),
      expect: () => [
        const LocationPermissionDenied(isPermanentlyDenied: true),
      ],
      verify: (_) {
        verify(() => mockLocationRepository.checkPermission()).called(1);
      },
    );

    blocTest<LocationBloc, LocationState>(
      'emits [LocationError] when checkPermission fails',
      build: () {
        when(() => mockLocationRepository.checkPermission()).thenAnswer(
          (_) async => const Error(LocationPermissionDeniedFailure('Permission check failed')),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(CheckLocationPermission()),
      expect: () => [
        const LocationError(message: 'Permission check failed'),
      ],
      verify: (_) {
        verify(() => mockLocationRepository.checkPermission()).called(1);
      },
    );
  });

  group('RequestLocationPermission', () {
    blocTest<LocationBloc, LocationState>(
      'emits [LocationLoading, LocationLoaded] when permission granted and coordinates fetched',
      build: () {
        when(() => mockLocationRepository.requestPermission()).thenAnswer(
          (_) async => const Success(LocationPermissionType.granted),
        );
        when(() => mockLocationRepository.getCurrentLocation()).thenAnswer(
          (_) async => Success(testLocation),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(RequestLocationPermission()),
      expect: () => [
        LocationLoading(),
        LocationLoaded(userLocation: testLocation),
      ],
      verify: (_) {
        verify(() => mockLocationRepository.requestPermission()).called(1);
        verify(() => mockLocationRepository.getCurrentLocation()).called(1);
      },
    );

    blocTest<LocationBloc, LocationState>(
      'emits [LocationLoading, LocationPermissionDenied(isPermanentlyDenied: false)] when permission denied',
      build: () {
        when(() => mockLocationRepository.requestPermission()).thenAnswer(
          (_) async => const Success(LocationPermissionType.denied),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(RequestLocationPermission()),
      expect: () => [
        LocationLoading(),
        const LocationPermissionDenied(isPermanentlyDenied: false),
      ],
      verify: (_) {
        verify(() => mockLocationRepository.requestPermission()).called(1);
        verifyNever(() => mockLocationRepository.getCurrentLocation());
      },
    );

    blocTest<LocationBloc, LocationState>(
      'emits [LocationLoading, LocationPermissionDenied(isPermanentlyDenied: true)] when permission permanently denied',
      build: () {
        when(() => mockLocationRepository.requestPermission()).thenAnswer(
          (_) async => const Success(LocationPermissionType.permanentlyDenied),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(RequestLocationPermission()),
      expect: () => [
        LocationLoading(),
        const LocationPermissionDenied(isPermanentlyDenied: true),
      ],
      verify: (_) {
        verify(() => mockLocationRepository.requestPermission()).called(1);
        verifyNever(() => mockLocationRepository.getCurrentLocation());
      },
    );

    blocTest<LocationBloc, LocationState>(
      'emits [LocationLoading, LocationError] when requestPermission fails',
      build: () {
        when(() => mockLocationRepository.requestPermission()).thenAnswer(
          (_) async => const Error(LocationPermissionDeniedFailure('Request failed')),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(RequestLocationPermission()),
      expect: () => [
        LocationLoading(),
        const LocationError(message: 'Request failed'),
      ],
      verify: (_) {
        verify(() => mockLocationRepository.requestPermission()).called(1);
      },
    );
  });

  group('FetchCurrentLocation', () {
    blocTest<LocationBloc, LocationState>(
      'emits [LocationLoaded] when getCurrentLocation succeeds',
      build: () {
        when(() => mockLocationRepository.getCurrentLocation()).thenAnswer(
          (_) async => Success(testLocation),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(FetchCurrentLocation()),
      expect: () => [
        LocationLoaded(userLocation: testLocation),
      ],
      verify: (_) {
        verify(() => mockLocationRepository.getCurrentLocation()).called(1);
      },
    );

    blocTest<LocationBloc, LocationState>(
      'emits [LocationError] when getCurrentLocation fails',
      build: () {
        when(() => mockLocationRepository.getCurrentLocation()).thenAnswer(
          (_) async => const Error(UnknownLocationFailure('GPS timeout')),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(FetchCurrentLocation()),
      expect: () => [
        const LocationError(message: 'GPS timeout'),
      ],
      verify: (_) {
        verify(() => mockLocationRepository.getCurrentLocation()).called(1);
      },
    );
  });

  group('OpenAppSettings', () {
    blocTest<LocationBloc, LocationState>(
      'calls openAppSettings on repository without state changes',
      build: () {
        when(() => mockLocationRepository.openAppSettings()).thenAnswer(
          (_) async => const Success(null),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(OpenAppSettings()),
      expect: () => [],
      verify: (_) {
        verify(() => mockLocationRepository.openAppSettings()).called(1);
      },
    );
  });
}
