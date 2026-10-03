import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modern_ride/core/errors/exceptions.dart';
import 'package:modern_ride/core/utils/result.dart';
import 'package:modern_ride/features/map_navigation/data/datasources/routing_remote_datasource.dart';
import 'package:modern_ride/features/map_navigation/data/models/route_model.dart';
import 'package:modern_ride/features/map_navigation/data/repositories/route_repository_impl.dart';
import 'package:modern_ride/features/map_navigation/domain/entities/route_entity.dart';

class MockRouteRemoteDatasource extends Mock implements RouteRemoteDatasource {}

void main() {
  late MockRouteRemoteDatasource mockDatasource;
  late RouteRepositoryImpl repository;

  const startPoint = LatLng(23.8103, 90.4125);
  const destPoint = LatLng(23.7925, 90.4078);

  final testRouteModel = RouteModel(
    points: const [
      LatLng(23.8103, 90.4125),
      LatLng(23.8000, 90.4100),
      LatLng(23.7925, 90.4078),
    ],
    totalDistanceMeters: 5420.5,
    totalDurationSeconds: 842.3,
  );

  setUpAll(() {
    registerFallbackValue(const LatLng(0, 0));
  });

  setUp(() {
    mockDatasource = MockRouteRemoteDatasource();
    repository = RouteRepositoryImpl(remoteDatasource: mockDatasource);
  });

  group('RouteRepositoryImpl.getRoute', () {
    test('returns Success<RouteEntity> when datasource successfully fetches route', () async {
      when(
        () => mockDatasource.getRoute(
          start: any(named: 'start'),
          destination: any(named: 'destination'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => testRouteModel);

      final result = await repository.getRoute(
        start: startPoint,
        destination: destPoint,
      );

      expect(result, isA<Success<RouteEntity>>());
      final success = result as Success<RouteEntity>;
      expect(success.data, equals(testRouteModel));
      expect(success.data.totalDistanceMeters, equals(5420.5));
      expect(success.data.totalDurationSeconds, equals(842.3));
    });

    test('returns Error(NoRouteFoundFailure) when NoRouteFoundException is thrown', () async {
      when(
        () => mockDatasource.getRoute(
          start: any(named: 'start'),
          destination: any(named: 'destination'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(const NoRouteFoundException());

      final result = await repository.getRoute(
        start: startPoint,
        destination: destPoint,
      );

      expect(result, isA<Error<RouteEntity>>());
      final error = result as Error<RouteEntity>;
      expect(error.failure, isA<NoRouteFoundFailure>());
    });

    test('returns Error(ServerRateLimitFailure) when ServerRateLimitException is thrown', () async {
      when(
        () => mockDatasource.getRoute(
          start: any(named: 'start'),
          destination: any(named: 'destination'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(const ServerRateLimitException());

      final result = await repository.getRoute(
        start: startPoint,
        destination: destPoint,
      );

      expect(result, isA<Error<RouteEntity>>());
      final error = result as Error<RouteEntity>;
      expect(error.failure, isA<ServerRateLimitFailure>());
    });

    test('returns Error(NetworkFailure) when ServerException is thrown', () async {
      when(
        () => mockDatasource.getRoute(
          start: any(named: 'start'),
          destination: any(named: 'destination'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(const ServerException('Connection lost'));

      final result = await repository.getRoute(
        start: startPoint,
        destination: destPoint,
      );

      expect(result, isA<Error<RouteEntity>>());
      final error = result as Error<RouteEntity>;
      expect(error.failure, isA<NetworkFailure>());
      expect(error.failure.message, equals('Connection lost'));
    });

    test('returns Error(UnknownFailure) when DioExceptionType.cancel is thrown', () async {
      when(
        () => mockDatasource.getRoute(
          start: any(named: 'start'),
          destination: any(named: 'destination'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.cancel,
        ),
      );

      final result = await repository.getRoute(
        start: startPoint,
        destination: destPoint,
      );

      expect(result, isA<Error<RouteEntity>>());
      final error = result as Error<RouteEntity>;
      expect(error.failure, isA<UnknownFailure>());
      expect(error.failure.message, equals('Request superseded by newer destination.'));
    });

    test('returns Error(NetworkFailure) on non-cancel DioException', () async {
      when(
        () => mockDatasource.getRoute(
          start: any(named: 'start'),
          destination: any(named: 'destination'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.badResponse,
          message: 'HTTP 502 Bad Gateway',
        ),
      );

      final result = await repository.getRoute(
        start: startPoint,
        destination: destPoint,
      );

      expect(result, isA<Error<RouteEntity>>());
      final error = result as Error<RouteEntity>;
      expect(error.failure, isA<NetworkFailure>());
      expect(error.failure.message, equals('HTTP 502 Bad Gateway'));
    });

    test('cancels previous in-flight request token when a new route is requested', () async {
      CancelToken? capturedToken1;
      CancelToken? capturedToken2;
      final completer1 = Completer<RouteModel>();

      when(
        () => mockDatasource.getRoute(
          start: any(named: 'start'),
          destination: any(named: 'destination'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((invocation) {
        final token = invocation.namedArguments[#cancelToken] as CancelToken?;
        if (capturedToken1 == null) {
          capturedToken1 = token;
          return completer1.future;
        } else {
          capturedToken2 = token;
          return Future.value(testRouteModel);
        }
      });

      // First call (stays pending)
      final future1 = repository.getRoute(start: startPoint, destination: destPoint);

      // Verify token 1 was generated and is not yet cancelled
      expect(capturedToken1, isNotNull);
      expect(capturedToken1!.isCancelled, isFalse);

      // Second call (should cancel token 1)
      final future2 = repository.getRoute(
        start: startPoint,
        destination: const LatLng(23.75, 90.38),
      );

      // Token 1 should now be cancelled with reason
      expect(capturedToken1!.isCancelled, isTrue);
      expect(capturedToken1!.cancelError?.error, equals('New route destination selected.'));

      // Complete first call with cancel exception
      completer1.completeError(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.cancel,
        ),
      );

      final result1 = await future1;
      final result2 = await future2;

      expect(result1, isA<Error<RouteEntity>>());
      expect(result2, isA<Success<RouteEntity>>());
      expect(capturedToken2, isNotNull);
      expect(capturedToken2!.isCancelled, isFalse);
    });
  });
}
