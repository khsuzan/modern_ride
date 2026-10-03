import 'package:flutter/material.dart';
import 'package:modern_ride/app.dart';
import 'package:modern_ride/core/config/flavor_type.dart';
import 'core/config/app_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.current = const AppConfig(
    flavor: FlavorType.prod,
    appTitle: 'ModernRide',
    osrmBaseUrl: 'https://router.project-osrm.org',
    showDevBanner: false,
  );
  runApp(const MyApp());
}