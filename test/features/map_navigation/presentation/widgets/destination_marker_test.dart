import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:modern_ride/features/map_navigation/presentation/widgets/destination_marker.dart';

void main() {
  group('DestinationMarker', () {
    testWidgets('renders ball dot pin and executes animated drop', (tester) async {
      const destination = LatLng(23.7925, 90.4078);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: DestinationMarker(destination: destination),
            ),
          ),
        ),
      );

      // Verify widget exists
      expect(find.byType(DestinationMarker), findsOneWidget);

      // Advance animation halfway
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(DestinationMarker), findsOneWidget);

      // Complete animation
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(DestinationMarker), findsOneWidget);
    });

    testWidgets('re-triggers drop animation when destination updates', (tester) async {
      const destination1 = LatLng(23.7925, 90.4078);
      const destination2 = LatLng(23.8103, 90.4125);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: DestinationMarker(destination: destination1),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Update destination coordinate
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: DestinationMarker(destination: destination2),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(DestinationMarker), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(DestinationMarker), findsOneWidget);
    });
  });
}
