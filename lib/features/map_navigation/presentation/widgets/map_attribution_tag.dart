import 'package:flutter/material.dart';
import 'package:modern_ride/core/constants/app_constants.dart';

/// Unobtrusive, permanently visible attribution tag displaying OpenStreetMap copyright.
///
/// Fully complies with OpenStreetMap tile usage policies by presenting the
/// exact required attribution without extra library prefixes or obstructive banners.
class MapAttributionTag extends StatelessWidget {
  final Alignment alignment;

  const MapAttributionTag({
    super.key,
    this.alignment = Alignment.topLeft,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
              child: Text(
                AppConstants.osmAttribution,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
