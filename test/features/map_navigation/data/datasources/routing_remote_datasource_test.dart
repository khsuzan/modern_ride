import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modern_ride/core/errors/exceptions.dart';
import 'package:modern_ride/features/map_navigation/data/datasources/routing_remote_datasource.dart';
import 'package:modern_ride/features/map_navigation/data/models/route_model.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late RouteRemoteDatasourceImpl datasource;

  const startPoint = LatLng(23.8103, 90.4125);
  const destPoint = LatLng(23.7925, 90.4078);
  final expectedPath =
      '/route/v1/driving/${startPoint.longitude},${startPoint.latitude};${destPoint.longitude},${destPoint.latitude}';

  const sampleOsrmResponse = {
    'code': 'Ok',
    'routes': [
      {
        'geometry': '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
        'distance': 5420.5,
        'duration': 842.3,
      }
    ],
  };

  setUp(() {
    mockDio = MockDio();
    datasource = RouteRemoteDatasourceImpl(dio: mockDio);
  });

  group('RouteRemoteDatasourceImpl.getRoute', () {
    test('calls Dio with correct path, query parameters, and returns RouteModel on Ok response', () async {
      final cancelToken = CancelToken();

      when(
        () => mockDio.get<Map<String, dynamic>>(
          expectedPath,
          queryParameters: const {
            'overview': 'full',
            'geometries': 'polyline',
          },
          cancelToken: cancelToken,
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: expectedPath),
          statusCode: 200,
          data: sampleOsrmResponse,
        ),
      );

      final result = await datasource.getRoute(
        start: startPoint,
        destination: destPoint,
        cancelToken: cancelToken,
      );

      expect(result, isA<RouteModel>());
      expect(result.points.length, equals(3));
      expect(result.totalDistanceMeters, equals(5420.5));
      expect(result.totalDurationSeconds, equals(842.3));

      verify(
        () => mockDio.get<Map<String, dynamic>>(
          expectedPath,
          queryParameters: const {
            'overview': 'full',
            'geometries': 'polyline',
          },
          cancelToken: cancelToken,
        ),
      ).called(1);
    });

    test('throws ServerException when response data is null', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: expectedPath),
          statusCode: 200,
          data: null,
        ),
      );

      expect(
        () => datasource.getRoute(start: startPoint, destination: destPoint),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            equals('Empty response from routing server.'),
          ),
        ),
      );
    });

    test('throws NoRouteFoundException when OSRM code is not Ok', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: expectedPath),
          statusCode: 200,
          data: const {'code': 'NoRoute', 'routes': []},
        ),
      );

      expect(
        () => datasource.getRoute(start: startPoint, destination: destPoint),
        throwsA(isA<NoRouteFoundException>()),
      );
    });

    test('rethrows DioException when request is cancelled', () async {
      final cancelDioException = DioException(
        requestOptions: RequestOptions(path: expectedPath),
        type: DioExceptionType.cancel,
        message: 'Request was cancelled',
      );

      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(cancelDioException);

      expect(
        () => datasource.getRoute(start: startPoint, destination: destPoint),
        throwsA(isA<DioException>().having((e) => e.type, 'type', DioExceptionType.cancel)),
      );
    });

    test('throws ServerException on connectionTimeout', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: expectedPath),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect(
        () => datasource.getRoute(start: startPoint, destination: destPoint),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            equals('Route request timed out.'),
          ),
        ),
      );
    });

    test('throws ServerRateLimitException on 429 status code', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: expectedPath),
          response: Response(
            requestOptions: RequestOptions(path: expectedPath),
            statusCode: 429,
          ),
        ),
      );

      expect(
        () => datasource.getRoute(start: startPoint, destination: destPoint),
        throwsA(isA<ServerRateLimitException>()),
      );
    });

    test('throws ServerException on connectionError', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: expectedPath),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => datasource.getRoute(start: startPoint, destination: destPoint),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            equals('No internet connection.'),
          ),
        ),
      );
    });

    test('throws generic ServerException with error message on other DioExceptions', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: expectedPath),
          type: DioExceptionType.badResponse,
          message: 'Internal server error 500',
        ),
      );

      expect(
        () => datasource.getRoute(start: startPoint, destination: destPoint),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            equals('Internal server error 500'),
          ),
        ),
      );
    });
  });
}
