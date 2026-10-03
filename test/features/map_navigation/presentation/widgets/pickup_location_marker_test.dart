import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:modern_ride/features/map_navigation/presentation/widgets/pickup_location_marker.dart';

void main() {
  group('PickupLocationMarker', () {
    testWidgets('executes one-shot drop animation on placement and settles completely', (tester) async {
      const pickup = LatLng(23.8103, 90.4125);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: PickupLocationMarker(
                position: pickup,
                isUnifiedWithMyLocation: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(PickupLocationMarker), findsOneWidget);
      expect(find.byIcon(Icons.hail_rounded), findsOneWidget);

      // Advance through the drop animation
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(PickupLocationMarker), findsOneWidget);

      // Settle the animation
      await tester.pumpAndSettle();

      // Ensure no active ticker remains running (no looping/continuous animation)
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('re-triggers drop animation when position updates', (tester) async {
      const pos1 = LatLng(23.8103, 90.4125);
      const pos2 = LatLng(23.7925, 90.4078);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: PickupLocationMarker(
                position: pos1,
                isUnifiedWithMyLocation: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Update position
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: PickupLocationMarker(
                position: pos2,
                isUnifiedWithMyLocation: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(PickupLocationMarker), findsOneWidget);

      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('renders correctly when unified with user location', (tester) async {
      const pos = LatLng(23.8103, 90.4125);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: PickupLocationMarker(
                position: pos,
                isUnifiedWithMyLocation: true,
                heading: 90.0,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(PickupLocationMarker), findsOneWidget);
      expect(find.byIcon(Icons.hail_rounded), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });
}
