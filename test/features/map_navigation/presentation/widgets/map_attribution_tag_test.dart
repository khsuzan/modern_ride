import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_ride/core/constants/app_constants.dart';
import 'package:modern_ride/features/map_navigation/presentation/widgets/map_attribution_tag.dart';

void main() {
  testWidgets(
    'renders exact OpenStreetMap attribution text in a compact tag at top-left',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                MapAttributionTag(),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppConstants.osmAttribution), findsOneWidget);
    },
  );
}
