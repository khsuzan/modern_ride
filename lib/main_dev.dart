import 'package:flutter/material.dart';
import 'package:modern_ride/app.dart';
import 'package:modern_ride/core/config/app_config.dart';
import 'package:modern_ride/core/config/flavor_type.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.current = const AppConfig(
    flavor: FlavorType.dev,
    appTitle: 'NavTest Dev',
    osrmBaseUrl: 'https://router.project-osrm.org',
    showDevBanner: true,
  );
  runApp(const MyApp());
}