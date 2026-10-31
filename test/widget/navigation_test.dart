import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:piedzivo/app.dart';
import 'package:piedzivo/core/theme/app_theme.dart';
import 'package:piedzivo/core/navigation/app_router.dart';
import 'package:piedzivo/core/navigation/piedzivo_bottom_nav.dart';
import 'package:piedzivo/core/network/api_client.dart';
import 'package:piedzivo/features/auth/bloc/auth_bloc.dart';
import 'package:piedzivo/features/auth/bloc/auth_state.dart';
import 'package:piedzivo/features/auth/models/user.dart';
import 'package:piedzivo/features/auth/repositories/auth_repository.dart';
import 'package:piedzivo/features/events/bloc/events_bloc.dart';
import 'package:piedzivo/features/events/bloc/events_state.dart';
import 'package:piedzivo/features/events/repositories/events_repository.dart';
import 'package:piedzivo/features/geo/cubit/geo_cubit.dart';
import 'package:piedzivo/features/geo/models/geo_place.dart';
import 'package:piedzivo/features/geo/repositories/geo_repository.dart';
import 'package:piedzivo/features/places/bloc/places_bloc.dart';
import 'package:piedzivo/features/places/bloc/places_state.dart';
import 'package:piedzivo/features/places/repositories/places_repository.dart';
import 'package:piedzivo/features/places/screens/places_list_screen.dart';
import 'package:piedzivo/features/search/screens/search_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../unit/api_client_test.dart';

void main() {
  group('Uzdevums 4: Navigation, MainScaffold, GlobalTopBar, and BottomNav', () {
    late FakeSecureStorage fakeStorage;
    late MockAdapter mockAdapter;
    late ApiClient apiClient;
    late GeoRepository geoRepository;
    late GeoCubit geoCubit;
    late EventsRepository eventsRepository;
    late EventsBloc eventsBloc;
    late PlacesRepository placesRepository;
    late PlacesBloc placesBloc;
    late AuthRepository authRepository;
    late AuthBloc authBloc;
    late GoRouter testRouter;

    const placeCesis = GeoPlace(
      id: 'city-cesis',
      name: 'Cēsis',
      slug: 'cesis',
      type: 'city',
      isStateCity: false,
      parent: GeoPlaceParent(
        id: 'muni-cesis',
        name: 'Cēsu novads',
        slug: 'cesu-novads',
        type: 'municipality',
      ),
    );

    const placeValmiera = GeoPlace(
      id: 'city-valmiera',
      name: 'Valmiera',
      slug: 'valmiera',
      type: 'city',
      isStateCity: true,
      parent: null,
    );

    setUp(() async {
      AppTheme.isTestMode = true;
      SharedPreferences.setMockInitialValues({
        GeoRepository.cacheKeyPlacesJson: jsonEncode([placeCesis.toJson(), placeValmiera.toJson()]),
        GeoRepository.cacheKeyChecksum: 'chk1',
        GeoCubit.keyActivePlaceId: 'city-cesis',
        GeoCubit.keyIsMunicipalityWide: false,
      });

      fakeStorage = FakeSecureStorage();
      mockAdapter = MockAdapter();
      mockAdapter.handler = (options) {
        if (options.path.contains('/events') || options.path.contains('/places')) {
          return ResponseBody.fromString(
            jsonEncode({'data': []}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString(jsonEncode({'status': 'ok'}), 200);
      };

      final dio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
      dio.httpClientAdapter = mockAdapter;

      apiClient = ApiClient(secureStorage: fakeStorage, dioClient: dio);
      eventsRepository = EventsRepository(apiClient: apiClient);
      eventsBloc = EventsBloc(repository: eventsRepository);
      placesRepository = PlacesRepository(apiClient: apiClient);
      placesBloc = PlacesBloc(repository: placesRepository);
      authRepository = AuthRepository(apiClient: apiClient);
      authBloc = AuthBloc(
        authRepository: authRepository,
        initialState: const AuthState(
          status: AuthStatus.authenticated,
          user: User(id: 'u1', email: 'test@example.com'),
        ),
      );
      geoRepository = GeoRepository(apiClient: apiClient);
      geoCubit = GeoCubit(geoRepository: geoRepository);
      await geoCubit.loadPlaces(serverChecksum: 'chk1');

      testRouter = createAppRouter();
    });

    testWidgets('Can switch between all 3 tabs and tab states do not reset', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        PiedzivoApp(
          apiClient: apiClient,
          geoCubit: geoCubit,
          eventsBloc: eventsBloc,
          eventsRepository: eventsRepository,
          placesBloc: placesBloc,
          placesRepository: placesRepository,
          authBloc: authBloc,
          authRepository: authRepository,
          router: testRouter,
          startWithRouter: true,
        ),
      );
      await tester.runAsync(() async {
        await eventsBloc.stream.firstWhere((s) => s is EventsLoaded);
      });
      await tester.pumpAndSettle();

      // 1. Pārbaudām, ka startējam 0. cilnē (Pasākumi) un kategoriju čips ir redzams
      expect(find.byKey(const Key('category_chip_Koncerts')), findsOneWidget);

      // 2. Pārslēdzamies uz 1. cilni (Vietas)
      await tester.tap(find.byKey(const Key('bottom_nav_item_1')));
      await tester.pump();
      await tester.runAsync(() async {
        await placesBloc.stream.firstWhere((s) => s is PlacesLoaded);
      });
      await tester.pumpAndSettle();

      expect(find.byType(PlacesListScreen), findsOneWidget);
      expect(find.byKey(const Key('places_category_chip_Ēdināšana')), findsOneWidget);

      // 3. Pārslēdzamies uz 2. cilni (Sekotie)
      await tester.tap(find.byKey(const Key('bottom_nav_item_2')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('following_tab_events')), findsOneWidget);
      expect(find.byKey(const Key('following_tab_places')), findsOneWidget);

      // Pārslēdzamies uz apakšcilni "Manas Vietas"
      await tester.tap(find.byKey(const Key('following_tab_places')));
      await tester.pumpAndSettle();
      expect(find.text('Nav sekotu vietu'), findsOneWidget);

      // 4. Atgriežamies atpakaļ uz 0. cilni (Pasākumi)
      await tester.tap(find.byKey(const Key('bottom_nav_item_0')));
      await tester.pumpAndSettle();

      // VERIFIKĀCIJA: Pasākumos kategorijas čips joprojām ir vietā
      expect(find.byKey(const Key('category_chip_Koncerts')), findsOneWidget);

      // 5. Atgriežamies uz 1. cilni (Vietas)
      await tester.tap(find.byKey(const Key('bottom_nav_item_1')));
      await tester.pumpAndSettle();

      // VERIFIKĀCIJA: Stāvoklis Vietās nav atiestatījies
      expect(find.byType(PlacesListScreen), findsOneWidget);
      expect(find.byKey(const Key('places_category_chip_Ēdināšana')), findsOneWidget);

      // 6. Atgriežamies uz 2. cilni (Sekotie)
      await tester.tap(find.byKey(const Key('bottom_nav_item_2')));
      await tester.pumpAndSettle();

      // VERIFIKĀCIJA: Sekotajos joprojām ir aktīva apakšcilne "Manas Vietas"
      expect(find.text('Nav sekotu vietu'), findsOneWidget);
    });

    testWidgets('GlobalTopBar displays active city and toggles municipality switch (Variants A)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        PiedzivoApp(
          apiClient: apiClient,
          geoCubit: geoCubit,
          eventsBloc: eventsBloc,
          eventsRepository: eventsRepository,
          placesBloc: placesBloc,
          placesRepository: placesRepository,
          router: testRouter,
          startWithRouter: true,
        ),
      );
      await tester.pumpAndSettle();

      // Sākotnēji aktīvā pilsēta ir Cēsis
      expect(find.text('Cēsis'), findsOneWidget);
      expect(find.text('Tikai pilsētā'), findsOneWidget);

      // Nospiežam slēdzi "Tikai pilsētā" -> jāpārslēdzas uz "Visā novadā"
      await tester.tap(find.byKey(const Key('global_top_bar_municipality_toggle')));
      await tester.pumpAndSettle();

      expect(find.text('Visā novadā'), findsOneWidget);
      expect(geoCubit.state.isMunicipalityWide, isTrue);

      // Nospiežam atkal -> atgriežas uz "Tikai pilsētā"
      await tester.tap(find.byKey(const Key('global_top_bar_municipality_toggle')));
      await tester.pumpAndSettle();

      expect(find.text('Tikai pilsētā'), findsOneWidget);
      expect(geoCubit.state.isMunicipalityWide, isFalse);
    });

    testWidgets('Search button in GlobalTopBar navigates to /search', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        PiedzivoApp(
          apiClient: apiClient,
          geoCubit: geoCubit,
          eventsBloc: eventsBloc,
          eventsRepository: eventsRepository,
          placesBloc: placesBloc,
          placesRepository: placesRepository,
          router: testRouter,
          startWithRouter: true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('global_top_bar_search_button')));
      await tester.pumpAndSettle();

      expect(find.byType(SearchScreen), findsOneWidget);
    });

    testWidgets('PiedzivoBottomNav displays red badges for 1..99 and 99+', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        PiedzivoApp(
          apiClient: apiClient,
          geoCubit: geoCubit,
          eventsBloc: eventsBloc,
          eventsRepository: eventsRepository,
          placesBloc: placesBloc,
          placesRepository: placesRepository,
          router: testRouter,
          startWithRouter: true,
        ),
      );
      await tester.pumpAndSettle();

      // Nomainām BottomNav ar skaitītājiem
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: PiedzivoBottomNav(
              navigationShell: (tester.widget(find.byType(PiedzivoBottomNav)) as PiedzivoBottomNav)
                  .navigationShell,
              eventsBadgeCount: 7,
              placesBadgeCount: 150,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('7'), findsOneWidget);
      expect(find.text('99+'), findsOneWidget);
    });
  });
}

