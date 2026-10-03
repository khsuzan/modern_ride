import 'package:flutter_test/flutter_test.dart';
import 'package:modern_ride/core/utils/polyline_decoder.dart';

void main() {
  group('PolylineDecoder', () {
    test('returns empty list for empty string', () {
      final points = PolylineDecoder.decode('');
      expect(points, isEmpty);
    });

    test('correctly decodes standard OSRM polyline string', () {
      // Known polyline: (38.5, -120.2), (40.7, -120.95), (43.252, -126.453)
      const encoded = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';
      final points = PolylineDecoder.decode(encoded);

      expect(points.length, equals(3));

      expect(points[0].latitude, closeTo(38.5, 0.0001));
      expect(points[0].longitude, closeTo(-120.2, 0.0001));

      expect(points[1].latitude, closeTo(40.7, 0.0001));
      expect(points[1].longitude, closeTo(-120.95, 0.0001));

      expect(points[2].latitude, closeTo(43.252, 0.0001));
      expect(points[2].longitude, closeTo(-126.453, 0.0001));
    });
  });
}
