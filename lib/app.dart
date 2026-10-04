import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modern_locate/modern_locate.dart';
import 'core/network/dio_factory.dart';
import 'package:modern_ride/features/map_navigation/data/datasources/location_native_datasource.dart';
import 'package:modern_ride/features/map_navigation/data/datasources/routing_remote_datasource.dart';
import 'package:modern_ride/features/map_navigation/data/repositories/location_repository_impl.dart';
import 'package:modern_ride/features/map_navigation/data/repositories/route_repository_impl.dart';
import 'package:modern_ride/features/map_navigation/domain/repositories/location_repository.dart';
import 'package:modern_ride/features/map_navigation/domain/repositories/route_repository.dart';
import 'package:modern_ride/features/map_navigation/presentation/bloc/location_bloc/location_bloc.dart';
import 'package:modern_ride/features/map_navigation/presentation/bloc/navigation_bloc/navigation_bloc.dart';

import 'core/config/app_config.dart';
import 'features/map_navigation/presentation/screens/map_screen.dart';
import 'features/map_navigation/presentation/widgets/dev_badge_banner.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<LocationRepository>(
          create: (context) {
            final modernLocate = ModernLocate();
            final dataSource = LocationNativeDataSourceImpl(
              modernLocate: modernLocate,
            );
            return LocationRepositoryImpl(dataSource: dataSource);
          },
        ),
        RepositoryProvider<RouteRepository>(
          create: (context) {
            final dio = DioFactory.create();
            final dataSource = RouteRemoteDatasourceImpl(dio: dio);
            return RouteRepositoryImpl(remoteDatasource: dataSource);
          },
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<LocationBloc>(
            create: (context) => LocationBloc(
              locationRepository: context.read<LocationRepository>(),
            )..add(CheckLocationPermission()),
          ),
          BlocProvider<NavigationBloc>(
            create: (context) => NavigationBloc(
              routeRepository: context.read<RouteRepository>(),
              locationRepository: context.read<LocationRepository>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: AppConfig.current.appTitle,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1E88E5),
              primary: const Color(0xFF1E88E5),
            ),
            useMaterial3: true,
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                elevation: 6,
                shadowColor: const Color(0x731E88E5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          home: const FlavorBanner(child: MapScreen()),
        ),
      ),
    );
  }
}
