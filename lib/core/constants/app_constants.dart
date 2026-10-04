import 'package:latlong2/latlong.dart';

class AppConstants {
  const AppConstants._();

  /// Default center coordinates for initial map rendering (Dhaka, Bangladesh).
  static const LatLng defaultMapCenter = LatLng(23.8103, 90.4125);

  /// Distance threshold in meters beyond which a live vehicle is considered off-route.
  static const double offRouteThresholdMeters = 50.0;

  /// Arrival threshold in meters within which destination is marked reached.
  static const double destinationArrivalThresholdMeters = 15.0;

  /// Minimum delay between automatic re-routing network requests to prevent flooding.
  static const Duration rerouteCooldown = Duration(seconds: 4);

  /// Default nominal simulation vehicle speed in meters per second (~45 km/h).
  static const double fallbackNominalSpeedMps = 12.5;

  /// OSM attribution requirement.
  static const String osmAttribution = '© OpenStreetMap contributors';

  /// OpenStreetMap tile server URL template.
  static const String osmUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
}
