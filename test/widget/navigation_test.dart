import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:piedzivo/app.dart';
import 'package:piedzivo/core/navigation/app_router.dart';
import 'package:piedzivo/core/navigation/piedzivo_bottom_nav.dart';
import 'package:piedzivo/core/network/api_client.dart';
import 'package:piedzivo/features/geo/cubit/geo_cubit.dart';
import 'package:piedzivo/features/geo/models/geo_place.dart';
import 'package:piedzivo/features/geo/repositories/geo_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../unit/api_client_test.dart';

void main() {
  group('Uzdevums 4: Navigation, MainScaffold, GlobalTopBar, and BottomNav', () {
    late FakeSecureStorage fakeStorage;
    late MockAdapter mockAdapter;
    late ApiClient apiClient;
    late GeoRepository geoRepository;
    late GeoCubit geoCubit;
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
      SharedPreferences.setMockInitialValues({
        GeoRepository.cacheKeyPlacesJson: jsonEncode([placeCesis.toJson(), placeValmiera.toJson()]),
        GeoRepository.cacheKeyChecksum: 'chk1',
        GeoCubit.keyActivePlaceId: 'city-cesis',
        GeoCubit.keyIsMunicipalityWide: false,
      });

      fakeStorage = FakeSecureStorage();
      mockAdapter = MockAdapter();
      final dio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
      dio.httpClientAdapter = mockAdapter;

      apiClient = ApiClient(secureStorage: fakeStorage, dioClient: dio);
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
          geoCubit: geoCubit,
          router: testRouter,
          startWithRouter: true,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Pārbaudām, ka startējam 0. cilnē (Pasākumi)
      expect(find.text('Pasākumu saraksts'), findsOneWidget);
      expect(find.text('Stāvokļa pārbaude: 0'), findsOneWidget);

      // Palielinām skaitītāju Pasākumu cilnē līdz 2
      await tester.tap(find.byKey(const Key('events_increment_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('events_increment_button')));
      await tester.pumpAndSettle();
      expect(find.text('Stāvokļa pārbaude: 2'), findsOneWidget);

      // 2. Pārslēdzamies uz 1. cilni (Vietas)
      await tester.tap(find.byKey(const Key('bottom_nav_item_1')));
      await tester.pumpAndSettle();

      expect(find.text('Vietu katalogs'), findsOneWidget);
      expect(find.text('Stāvokļa pārbaude: 0'), findsOneWidget);

      // Palielinām skaitītāju Vietu cilnē līdz 5
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byKey(const Key('places_increment_button')));
        await tester.pumpAndSettle();
      }
      expect(find.text('Stāvokļa pārbaude: 5'), findsOneWidget);

      // 3. Pārslēdzamies uz 2. cilni (Sekotie)
      await tester.tap(find.byKey(const Key('bottom_nav_item_2')));
      await tester.pumpAndSettle();

      expect(find.text('Mani sekotie pasākumi un vietas'), findsOneWidget);
      expect(find.text('Stāvokļa pārbaude: 0'), findsOneWidget);

      await tester.tap(find.byKey(const Key('following_increment_button')));
      await tester.pumpAndSettle();
      expect(find.text('Stāvokļa pārbaude: 1'), findsOneWidget);

      // 4. Atgriežamies atpakaļ uz 0. cilni (Pasākumi)
      await tester.tap(find.byKey(const Key('bottom_nav_item_0')));
      await tester.pumpAndSettle();

      // VERIFIKĀCIJA: Stāvoklis Pasākumos nav atiestatījies (joprojām 2)!
      expect(find.text('Pasākumu saraksts'), findsOneWidget);
      expect(find.text('Stāvokļa pārbaude: 2'), findsOneWidget);

      // 5. Atgriežamies uz 1. cilni (Vietas)
      await tester.tap(find.byKey(const Key('bottom_nav_item_1')));
      await tester.pumpAndSettle();

      // VERIFIKĀCIJA: Stāvoklis Vietās nav atiestatījies (joprojām 5)!
      expect(find.text('Vietu katalogs'), findsOneWidget);
      expect(find.text('Stāvokļa pārbaude: 5'), findsOneWidget);
    });

    testWidgets('GlobalTopBar displays active city and toggles municipality switch (Variants A)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        PiedzivoApp(
          geoCubit: geoCubit,
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
          geoCubit: geoCubit,
          router: testRouter,
          startWithRouter: true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('global_top_bar_search_button')));
      await tester.pumpAndSettle();

      expect(find.text('Meklēšanas ekrāns tiks implementēts Uzdevumā 10'), findsOneWidget);
    });

    testWidgets('PiedzivoBottomNav displays red badges for 1..99 and 99+', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        PiedzivoApp(
          geoCubit: geoCubit,
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
