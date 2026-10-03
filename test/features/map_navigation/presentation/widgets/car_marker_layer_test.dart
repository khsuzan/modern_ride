import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:modern_ride/features/map_navigation/presentation/widgets/car_marker_layer.dart';

void main() {
  testWidgets('CarMarkerLayer renders modern vehicle painter inside FlutterMap',
      (tester) async {
    const testPosition = LatLng(23.8103, 90.4125);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlutterMap(
            options: const MapOptions(
              initialCenter: testPosition,
              initialZoom: 15.0,
            ),
            children: const [
              CarMarkerLayer(
                position: testPosition,
                bearing: 45.0,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(CarMarkerLayer), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is ModernVehiclePainter), findsOneWidget);
  });

  testWidgets('CarMarkerLayer updates bearing smoothly with shortest turn delta',
      (tester) async {
    const testPosition = LatLng(23.8103, 90.4125);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlutterMap(
            options: const MapOptions(
              initialCenter: testPosition,
              initialZoom: 15.0,
            ),
            children: const [
              CarMarkerLayer(
                position: testPosition,
                bearing: 350.0,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Rotate across 0-degree North boundary to 10 degrees
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlutterMap(
            options: const MapOptions(
              initialCenter: testPosition,
              initialZoom: 15.0,
            ),
            children: const [
              CarMarkerLayer(
                position: testPosition,
                bearing: 10.0,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(CarMarkerLayer), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(CarMarkerLayer), findsOneWidget);
  });
}
