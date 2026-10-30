import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'core/navigation/app_router.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/app_config/models/app_config.dart';
import 'features/app_config/repositories/app_config_repository.dart';
import 'features/app_config/screens/splash_screen.dart';
import 'features/geo/cubit/geo_cubit.dart';
import 'features/geo/repositories/geo_repository.dart';

class PiedzivoApp extends StatefulWidget {
  final AppConfigRepository? appConfigRepository;
  final GeoRepository? geoRepository;
  final GeoCubit? geoCubit;
  final GoRouter? router;
  final bool startWithRouter;

  const PiedzivoApp({
    super.key,
    this.appConfigRepository,
    this.geoRepository,
    this.geoCubit,
    this.router,
    this.startWithRouter = false,
  });

  @override
  State<PiedzivoApp> createState() => _PiedzivoAppState();
}

class _PiedzivoAppState extends State<PiedzivoApp> {
  late final ApiClient _apiClient;
  late final AppConfigRepository _configRepo;
  late final GeoRepository _geoRepo;
  late final GeoCubit _geoCubit;
  late final GoRouter _router;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(secureStorage: const FlutterSecureStorage());
    _configRepo = widget.appConfigRepository ?? AppConfigRepository(apiClient: _apiClient);
    _geoRepo = widget.geoRepository ?? GeoRepository(apiClient: _apiClient);
    _geoCubit = widget.geoCubit ?? GeoCubit(geoRepository: _geoRepo);
    _router = widget.router ?? appRouter;
    _isInitialized = widget.startWithRouter;
  }

  @override
  void dispose() {
    if (widget.geoCubit == null) {
      _geoCubit.close();
    }
    super.dispose();
  }

  void _onConfigLoaded(AppConfig config) {
    _geoCubit.loadPlaces(serverChecksum: config.checksums['geo_places']);
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _geoCubit,
      child: _isInitialized
          ? MaterialApp.router(
              title: 'Piedzīvo.lv',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              routerConfig: _router,
            )
          : MaterialApp(
              title: 'Piedzīvo.lv',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              home: SplashScreen(
                repository: _configRepo,
                onConfigLoaded: _onConfigLoaded,
              ),
            ),
    );
  }
}
