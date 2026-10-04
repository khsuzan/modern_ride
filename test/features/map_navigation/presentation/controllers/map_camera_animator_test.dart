import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:modern_ride/features/map_navigation/presentation/controllers/map_camera_animator.dart';

void main() {
  const initialCenter = LatLng(23.8103, 90.4125);
  const targetCenter = LatLng(23.8200, 90.4200);

  Widget createSubject({
    required MapController mapController,
    required void Function(MapCameraAnimator animator) onReady,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: _TestMapWrapper(mapController: mapController, onReady: onReady),
      ),
    );
  }

  testWidgets('animates camera smoothly to target location and zoom', (
    tester,
  ) async {
    final mapController = MapController();
    late MapCameraAnimator animator;

    await tester.pumpWidget(
      createSubject(mapController: mapController, onReady: (a) => animator = a),
    );
    await tester.pumpAndSettle();

    expect(animator.isAnimating, isFalse);

    animator.animateTo(
      destLocation: targetCenter,
      destZoom: 16.0,
      duration: const Duration(milliseconds: 500),
    );

    expect(animator.isAnimating, isTrue);

    // Pump intermediate frame
    await tester.pump(const Duration(milliseconds: 250));
    expect(animator.isAnimating, isTrue);

    // Pump until completion
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(animator.isAnimating, isFalse);
    expect(
      mapController.camera.center.latitude,
      closeTo(targetCenter.latitude, 0.001),
    );
    expect(
      mapController.camera.center.longitude,
      closeTo(targetCenter.longitude, 0.001),
    );
  });

  testWidgets(
    'cancels active animation immediately when cancelAnimation is called',
    (tester) async {
      final mapController = MapController();
      late MapCameraAnimator animator;

      await tester.pumpWidget(
        createSubject(
          mapController: mapController,
          onReady: (a) => animator = a,
        ),
      );
      await tester.pumpAndSettle();

      animator.animateTo(
        destLocation: targetCenter,
        destZoom: 16.0,
        duration: const Duration(milliseconds: 600),
      );

      await tester.pump(const Duration(milliseconds: 200));
      expect(animator.isAnimating, isTrue);

      animator.cancelAnimation();
      expect(animator.isAnimating, isFalse);

      await tester.pumpAndSettle();
    },
  );

  testWidgets('animates camera smoothly to fit LatLngBounds', (tester) async {
    final mapController = MapController();
    late MapCameraAnimator animator;

    await tester.pumpWidget(
      createSubject(mapController: mapController, onReady: (a) => animator = a),
    );
    await tester.pumpAndSettle();

    final bounds = LatLngBounds.fromPoints([initialCenter, targetCenter]);

    animator.animateToBounds(
      bounds: bounds,
      padding: const EdgeInsets.all(32),
      duration: const Duration(milliseconds: 600),
    );

    expect(animator.isAnimating, isTrue);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(animator.isAnimating, isFalse);
  });

  testWidgets(
    'trackVehicle moves camera directly when shift is below jump threshold',
    (tester) async {
      final mapController = MapController();
      late MapCameraAnimator animator;

      await tester.pumpWidget(
        createSubject(mapController: mapController, onReady: (a) => animator = a),
      );
      await tester.pumpAndSettle();

      // Ensure initial zoom is at minZoom (16.0)
      mapController.move(initialCenter, 16.0);
      await tester.pumpAndSettle();

      // Small 2m shift: 0.00002 deg latitude is ~2.2 meters
      const slightShift = LatLng(23.81032, 90.4125);
      animator.trackVehicle(slightShift, minZoom: 16.0, jumpThresholdMeters: 8.0);

      // Should not trigger an AnimationController
      expect(animator.isAnimating, isFalse);
      expect(
        mapController.camera.center.latitude,
        closeTo(slightShift.latitude, 0.00001),
      );
    },
  );

  testWidgets(
    'trackVehicle triggers smooth easeOut animation when deviation exceeds threshold',
    (tester) async {
      final mapController = MapController();
      late MapCameraAnimator animator;

      await tester.pumpWidget(
        createSubject(mapController: mapController, onReady: (a) => animator = a),
      );
      await tester.pumpAndSettle();

      mapController.move(initialCenter, 16.0);
      await tester.pumpAndSettle();

      // Significant shift (e.g. 60m test off-route deviation): ~0.0006 deg is ~66 meters
      const deviationShift = LatLng(23.8109, 90.4125);
      animator.trackVehicle(deviationShift, minZoom: 16.0, jumpThresholdMeters: 8.0);

      // Must start smooth animation
      expect(animator.isAnimating, isTrue);

      await tester.pump(const Duration(milliseconds: 250));
      expect(animator.isAnimating, isTrue);

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(animator.isAnimating, isFalse);
      expect(
        mapController.camera.center.latitude,
        closeTo(deviationShift.latitude, 0.0001),
      );
    },
  );
}

class _TestMapWrapper extends StatefulWidget {
  final MapController mapController;
  final void Function(MapCameraAnimator animator) onReady;

  const _TestMapWrapper({required this.mapController, required this.onReady});

  @override
  State<_TestMapWrapper> createState() => _TestMapWrapperState();
}

class _TestMapWrapperState extends State<_TestMapWrapper>
    with SingleTickerProviderStateMixin {
  late final MapCameraAnimator _animator;

  @override
  void initState() {
    super.initState();
    _animator = MapCameraAnimator(
      mapController: widget.mapController,
      vsync: this,
    );
    widget.onReady(_animator);
  }

  @override
  void dispose() {
    _animator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: widget.mapController,
      options: const MapOptions(
        initialCenter: LatLng(23.8103, 90.4125),
        initialZoom: 14.0,
      ),
      children: const [],
    );
  }
}
