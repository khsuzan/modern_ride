import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modern_locate/modern_locate.dart';
import 'package:modern_ride/features/map_navigation/data/datasources/location_native_datasource.dart';
import 'package:modern_ride/features/map_navigation/data/repositories/location_repository_impl.dart';
import 'package:modern_ride/features/map_navigation/domain/repositories/location_repository.dart';
import 'package:modern_ride/features/map_navigation/presentation/bloc/location_bloc/location_bloc.dart';

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
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<LocationBloc>(
            create: (context) => LocationBloc(
              locationRepository: context.read<LocationRepository>(),
            )..add(CheckLocationPermission()),
          ),
        ],
        child: MaterialApp(
          title: AppConfig.current.appTitle,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          home: const FlavorBanner(child: MapScreen()),
        ),
      ),
    );
  }
}
