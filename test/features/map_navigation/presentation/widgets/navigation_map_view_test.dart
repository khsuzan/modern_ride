import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:modern_ride/features/map_navigation/domain/entities/route_entity.dart';
import 'package:modern_ride/features/map_navigation/domain/entities/user_location.dart';
import 'package:modern_ride/features/map_navigation/presentation/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:modern_ride/features/map_navigation/presentation/widgets/car_marker_layer.dart';
import 'package:modern_ride/features/map_navigation/presentation/widgets/destination_marker.dart';
import 'package:modern_ride/features/map_navigation/presentation/widgets/navigation_map_view.dart';
import 'package:modern_ride/features/map_navigation/presentation/widgets/pickup_location_marker.dart';

void main() {
  const pickup = LatLng(23.8103, 90.4125);
  const destination = LatLng(23.8200, 90.4200);

  final testUserLocation = UserLocation(
    latitude: 23.8103,
    longitude: 90.4125,
    accuracy: 5,
    heading: 90,
    timestamp: DateTime.now(),
  );

  const testRoute = RouteEntity(
    points: [pickup, destination],
    totalDistanceMeters: 1500,
    totalDurationSeconds: 300,
  );

  Widget createSubject(NavigationState state) {
    return MaterialApp(
      home: Scaffold(
        body: NavigationMapView(
          mapController: MapController(),
          navState: state,
          userLocation: testUserLocation,
          onTap: (_, _) {},
          onLongPress: (_, _) {},
          onPositionChanged: (_, _) {},
        ),
      ),
    );
  }

  testWidgets('renders pickup marker when pickup is selected and before navigation starts',
      (tester) async {
    await tester.pumpWidget(createSubject(
      const PickupSelected(pickup: pickup),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(PickupLocationMarker), findsOneWidget);
    expect(find.byType(DestinationMarker), findsNothing);
    expect(find.byType(CarMarkerLayer), findsNothing);
  });

  testWidgets(
      'clears pickup marker, clears destination marker, and renders car marker when ride is NavigationCompleted',
      (tester) async {
    await tester.pumpWidget(createSubject(
      const NavigationCompleted(
        pickup: pickup,
        destination: destination,
        route: testRoute,
        finalPosition: destination,
      ),
    ));
    await tester.pumpAndSettle();

    // Pickup and destination markers must be cleared on ride completion
    expect(find.byType(PickupLocationMarker), findsNothing);
    expect(find.byType(DestinationMarker), findsNothing);

    // Car marker should be rendered at the final destination
    expect(find.byType(CarMarkerLayer), findsOneWidget);
  });
}
