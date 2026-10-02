
import 'package:modern_ride/core/config/flavor_type.dart';

class AppConfig {
  final FlavorType flavor;
  final String appTitle;
  final String osrmBaseUrl;
  final bool showDevBanner;

  const AppConfig({
    required this.flavor,
    required this.appTitle,
    required this.osrmBaseUrl,
    required this.showDevBanner,
  });

  static late AppConfig current;
}