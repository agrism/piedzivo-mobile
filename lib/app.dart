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
import 'features/events/bloc/events_bloc.dart';
import 'features/events/repositories/events_repository.dart';
import 'features/geo/cubit/geo_cubit.dart';
import 'features/geo/repositories/geo_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/places/bloc/places_bloc.dart';
import 'features/places/repositories/places_repository.dart';
import 'features/search/bloc/search_bloc.dart';

class PiedzivoApp extends StatefulWidget {
  final ApiClient? apiClient;
  final AppConfigRepository? appConfigRepository;
  final GeoRepository? geoRepository;
  final GeoCubit? geoCubit;
  final EventsRepository? eventsRepository;
  final EventsBloc? eventsBloc;
  final PlacesRepository? placesRepository;
  final PlacesBloc? placesBloc;
  final SearchBloc? searchBloc;
  final AuthRepository? authRepository;
  final AuthBloc? authBloc;
  final GoRouter? router;
  final bool startWithRouter;

  const PiedzivoApp({
    super.key,
    this.apiClient,
    this.appConfigRepository,
    this.geoRepository,
    this.geoCubit,
    this.eventsRepository,
    this.eventsBloc,
    this.placesRepository,
    this.placesBloc,
    this.searchBloc,
    this.authRepository,
    this.authBloc,
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
  late final EventsRepository _eventsRepo;
  late final EventsBloc _eventsBloc;
  late final PlacesRepository _placesRepo;
  late final PlacesBloc _placesBloc;
  late final SearchBloc _searchBloc;
  late final AuthRepository _authRepo;
  late final AuthBloc _authBloc;
  late final GoRouter _router;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient ?? ApiClient(secureStorage: const FlutterSecureStorage());
    _configRepo = widget.appConfigRepository ?? AppConfigRepository(apiClient: _apiClient);
    _geoRepo = widget.geoRepository ?? GeoRepository(apiClient: _apiClient);
    _geoCubit = widget.geoCubit ?? GeoCubit(geoRepository: _geoRepo);
    _eventsRepo = widget.eventsRepository ?? EventsRepository(apiClient: _apiClient);
    _eventsBloc = widget.eventsBloc ?? EventsBloc(repository: _eventsRepo);
    _placesRepo = widget.placesRepository ?? PlacesRepository(apiClient: _apiClient);
    _placesBloc = widget.placesBloc ?? PlacesBloc(repository: _placesRepo);
    _searchBloc = widget.searchBloc ??
        SearchBloc(
          eventsRepository: _eventsRepo,
          placesRepository: _placesRepo,
        );
    _authRepo = widget.authRepository ?? AuthRepository(apiClient: _apiClient);
    _authBloc = widget.authBloc ?? AuthBloc(authRepository: _authRepo)..add(const AuthCheckRequested());
    _router = widget.router ?? appRouter;
    _isInitialized = widget.startWithRouter;
  }

  @override
  void dispose() {
    if (widget.geoCubit == null) {
      _geoCubit.close();
    }
    if (widget.eventsBloc == null) {
      _eventsBloc.close();
    }
    if (widget.placesBloc == null) {
      _placesBloc.close();
    }
    if (widget.searchBloc == null) {
      _searchBloc.close();
    }
    if (widget.authBloc == null) {
      _authBloc.close();
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
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _configRepo),
        RepositoryProvider.value(value: _geoRepo),
        RepositoryProvider.value(value: _eventsRepo),
        RepositoryProvider.value(value: _placesRepo),
        RepositoryProvider.value(value: _authRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _geoCubit),
          BlocProvider.value(value: _eventsBloc),
          BlocProvider.value(value: _placesBloc),
          BlocProvider.value(value: _searchBloc),
          BlocProvider.value(value: _authBloc),
        ],
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
      ),
    );
  }
}
