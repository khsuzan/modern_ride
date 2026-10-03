// lib/app.dart
import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'features/map_navigation/presentation/screens/map_screen.dart';
import 'features/map_navigation/presentation/widgets/dev_badge_banner.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.current.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const FlavorBanner(
        child: MapScreen(),
      ),
    );
  }
}