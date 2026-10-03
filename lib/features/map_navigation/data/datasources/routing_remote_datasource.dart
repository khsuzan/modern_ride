import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:modern_ride/core/utils/app_logger.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/route_model.dart';

abstract class RouteRemoteDatasource {
  Future<RouteModel> getRoute({
    required LatLng start,
    required LatLng destination,
    CancelToken? cancelToken,
  });
}

class RouteRemoteDatasourceImpl implements RouteRemoteDatasource {
  final Dio dio;

  const RouteRemoteDatasourceImpl({required this.dio});

  @override
  Future<RouteModel> getRoute({
    required LatLng start,
    required LatLng destination,
    CancelToken? cancelToken,
  }) async {
    // OSRM format: /route/v1/driving/{startLng},{startLat};{destLng},{destLat}
    final path =
        '/route/v1/driving/'
        '${start.longitude},${start.latitude};'
        '${destination.longitude},${destination.latitude}';

    try {
      final response = await dio.get<Map<String, dynamic>>(
        path,
        queryParameters: const {'overview': 'full', 'geometries': 'polyline'},
        cancelToken: cancelToken,
      );
      AppLogger.info("Response: ${response.data}");

      final data = response.data;
      if (data == null) {
        throw const ServerException('Empty response from routing server.');
      }

      final code = data['code'] as String?;
      if (code != 'Ok') {
        throw const NoRouteFoundException();
      }

      return RouteModel.fromOsrmJson(data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw const ServerException('Route request timed out.');
      }
      if (e.response?.statusCode == 429) {
        throw const ServerRateLimitException();
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const ServerException('No internet connection.');
      }
      throw ServerException(e.message ?? 'Failed to fetch route.');
    }
  }
}
