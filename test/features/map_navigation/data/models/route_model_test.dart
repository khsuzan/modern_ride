import 'package:flutter_test/flutter_test.dart';
import 'package:modern_ride/features/map_navigation/data/models/route_model.dart';
import 'package:modern_ride/features/map_navigation/domain/entities/route_entity.dart';

void main() {
  group('RouteModel', () {
    const sampleOsrmJson = {
      'code': 'Ok',
      'routes': [
        {
          'geometry': '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
          'distance': 5420.5,
          'duration': 842.3,
        }
      ],
    };

    test('should be a subclass of RouteEntity', () {
      final model = RouteModel.fromOsrmJson(sampleOsrmJson);
      expect(model, isA<RouteEntity>());
    });

    test('should parse valid OSRM json correctly', () {
      final model = RouteModel.fromOsrmJson(sampleOsrmJson);

      expect(model.points.length, equals(3));
      expect(model.totalDistanceMeters, equals(5420.5));
      expect(model.totalDurationSeconds, equals(842.3));
    });

    test('should throw FormatException when routes array is empty', () {
      const invalidJson = {
        'code': 'Ok',
        'routes': <dynamic>[],
      };

      expect(
        () => RouteModel.fromOsrmJson(invalidJson),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
