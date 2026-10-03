import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:modern_ride/core/errors/exceptions.dart';
import 'package:modern_ride/core/utils/result.dart';

import '../../domain/entities/route_entity.dart';
import '../../domain/repositories/route_repository.dart';
import '../datasources/routing_remote_datasource.dart';

class RouteRepositoryImpl implements RouteRepository {
  final RouteRemoteDatasource remoteDatasource;
  CancelToken? _activeCancelToken;

  RouteRepositoryImpl({required this.remoteDatasource});

  @override
  Future<Result<RouteEntity>> getRoute({
    required LatLng start,
    required LatLng destination,
  }) async {
    // Cancel any previous in-flight request so newer destination always wins
    _activeCancelToken?.cancel('New route destination selected.');
    final currentCancelToken = CancelToken();
    _activeCancelToken = currentCancelToken;

    try {
      final routeModel = await remoteDatasource.getRoute(
        start: start,
        destination: destination,
        cancelToken: currentCancelToken,
      );
      return Success(routeModel);
    } on NoRouteFoundException {
      return const Error(NoRouteFoundFailure());
    } on ServerRateLimitException {
      return const Error(ServerRateLimitFailure());
    } on ServerException catch (e) {
      return Error(NetworkFailure(e.message));
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        return const Error(
          UnknownFailure('Request superseded by newer destination.'),
        );
      }
      return Error(NetworkFailure(e.message ?? 'Network error occurred.'));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    } finally {
      if (_activeCancelToken == currentCancelToken) {
        _activeCancelToken = null;
      }
    }
  }
}
