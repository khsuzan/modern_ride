import 'package:flutter_test/flutter_test.dart';
import 'package:modern_locate/modern_locate.dart';
import 'package:modern_ride/features/map_navigation/data/models/user_location_model.dart';
import 'package:modern_ride/features/map_navigation/domain/entities/user_location.dart';

void main() {
  group('UserLocationModel', () {
    const testLocationData = LocationData(
      latitude: 23.8103,
      longitude: 90.4125,
      accuracy: 4.5,
      heading: 180.0,
    );

    test('should be a subclass of UserLocation entity', () {
      final model = UserLocationModel.fromPlugin(testLocationData);
      expect(model, isA<UserLocation>());
    });

    test('should map all fields correctly from LocationData', () {
      final model = UserLocationModel.fromPlugin(testLocationData);

      expect(model.latitude, equals(23.8103));
      expect(model.longitude, equals(90.4125));
      expect(model.accuracy, equals(4.5));
      expect(model.heading, equals(180.0));
      expect(model.toLatLng.latitude, equals(23.8103));
      expect(model.toLatLng.longitude, equals(90.4125));
    });
  });
}
