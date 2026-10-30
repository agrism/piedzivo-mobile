import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piedzivo/app.dart';
import 'package:piedzivo/core/navigation/app_router.dart';
import 'package:piedzivo/core/network/api_client.dart';
import 'package:piedzivo/core/theme/app_theme.dart';
import 'package:piedzivo/features/events/bloc/events_bloc.dart';
import 'package:piedzivo/features/events/repositories/events_repository.dart';
import 'package:piedzivo/features/geo/cubit/geo_cubit.dart';
import 'package:piedzivo/features/geo/models/geo_place.dart';
import 'package:piedzivo/features/geo/repositories/geo_repository.dart';
import 'package:piedzivo/features/places/bloc/places_bloc.dart';
import 'package:piedzivo/features/places/bloc/places_state.dart';
import 'package:piedzivo/features/places/models/place_list_item.dart';
import 'package:piedzivo/features/places/repositories/places_repository.dart';
import 'package:piedzivo/features/places/screens/fullscreen_map_screen.dart';
import 'package:piedzivo/features/places/screens/place_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../unit/api_client_test.dart';

void main() {
  group('Uzdevums 8: FullscreenMapScreen UI tests', () {
    late FakeSecureStorage fakeStorage;
    late MockAdapter mockAdapter;
    late ApiClient apiClient;
    late PlacesRepository placesRepo;
    late PlacesBloc placesBloc;
    late EventsRepository eventsRepo;
    late EventsBloc eventsBloc;
    late GeoRepository geoRepo;
    late GeoCubit geoCubit;

    const placeCesis = GeoPlace(
      id: 'city-cesis',
      name: 'Cēsis',
      slug: 'cesis',
      type: 'city',
      isStateCity: false,
    );

    const mockPlace1 = PlaceListItem(
      id: 'p1',
      publicId: 'cesis-castle',
      slug: 'cesu-pils',
      title: 'Cēsu viduslaiku pils',
      shortDescription: 'Ievērojamākā pils Latvijā',
      city: 'Cēsis',
      latitude: 57.3131,
      longitude: 25.2715,
      primaryImageUrl: 'https://cdn.piedzivo.lv/places/p1.jpg',
      imagesCount: 4,
      editorialPriority: 10,
      recommendationsCount: 50,
      upcomingEventsCount: 3,
      isNew: false,
      isRecommendedByMe: false,
      isFollowedByMe: false,
      isOpen: true,
      openingLabel: '🟢 Atvērts līdz 18:00',
      rootCategoryName: 'Apskates objekti',
      primaryTaxonomyName: 'Vēsturiskās vietas',
    );

    const mockPlace2 = PlaceListItem(
      id: 'p2',
      publicId: 'janoga',
      slug: 'restorans-janoga',
      title: 'Restorāns Jāņoga',
      shortDescription: 'Gardas maltītes Cēsu centrā',
      city: 'Cēsis',
      latitude: 57.3105,
      longitude: 25.2680,
      primaryImageUrl: 'https://cdn.piedzivo.lv/places/p2.jpg',
      imagesCount: 6,
      editorialPriority: 5,
      recommendationsCount: 80,
      upcomingEventsCount: 0,
      isNew: true,
      isRecommendedByMe: false,
      isFollowedByMe: false,
      isOpen: false,
      openingLabel: '🔴 Slēgts (atvērsies 12:00)',
      rootCategoryName: 'Ēdināšana',
      primaryTaxonomyName: 'Restorāni',
    );

    setUp(() async {
      AppTheme.isTestMode = true;
      SharedPreferences.setMockInitialValues({
        GeoRepository.cacheKeyPlacesJson: jsonEncode([placeCesis.toJson()]),
        GeoRepository.cacheKeyChecksum: 'chk1',
        GeoCubit.keyActivePlaceId: 'city-cesis',
      });

      fakeStorage = FakeSecureStorage();
      mockAdapter = MockAdapter();

      mockAdapter.handler = (options) {
        if (options.path.contains('/recommend') || options.path.contains('/follow')) {
          return ResponseBody.fromString(jsonEncode({'status': 'ok'}), 200);
        }
        if (options.path == '/places/p1' || options.path == '/places/p2') {
          return ResponseBody.fromString(
            jsonEncode({'data': mockPlace1.toJson()}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.startsWith('/places')) {
          return ResponseBody.fromString(
            jsonEncode({
              'data': [mockPlace1.toJson(), mockPlace2.toJson()],
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString(jsonEncode({'status': 'ok'}), 200);
      };

      final dio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
      dio.httpClientAdapter = mockAdapter;

      apiClient = ApiClient(secureStorage: fakeStorage, dioClient: dio);
      placesRepo = PlacesRepository(apiClient: apiClient);
      placesBloc = PlacesBloc(repository: placesRepo);
      eventsRepo = EventsRepository(apiClient: apiClient);
      eventsBloc = EventsBloc(repository: eventsRepo);
      geoRepo = GeoRepository(apiClient: apiClient);
      geoCubit = GeoCubit(geoRepository: geoRepo);
      await geoCubit.loadPlaces(serverChecksum: 'chk1');
    });

    testWidgets('renders FullscreenMapScreen with pins, header and filter chips', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        PiedzivoApp(
          geoCubit: geoCubit,
          eventsBloc: eventsBloc,
          eventsRepository: eventsRepo,
          placesBloc: placesBloc,
          placesRepository: placesRepo,
          router: createAppRouter(
            navigatorKey: GlobalKey<NavigatorState>(),
            initialLocation: '/places/map',
          ),
          startWithRouter: true,
        ),
      );

      await tester.runAsync(() async {
        if (placesBloc.state is! PlacesLoaded) {
          await placesBloc.stream.firstWhere((s) => s is PlacesLoaded);
        }
      });
      await tester.pumpAndSettle();

      // Pārbaudām galvenes elementus
      expect(find.byType(FullscreenMapScreen), findsOneWidget);
      expect(find.byKey(const Key('map_back_button')), findsOneWidget);
      expect(find.text('Karte: Cēsis'), findsOneWidget);
      expect(find.text('2 vietas'), findsOneWidget);
      expect(find.byKey(const Key('map_recenter_button')), findsOneWidget);

      // Pārbaudām kategoriju čipus
      expect(find.byKey(const Key('map_filter_chip_Visas')), findsOneWidget);
      expect(find.byKey(const Key('map_filter_chip_Apskates objekti')), findsOneWidget);
      expect(find.byKey(const Key('map_filter_chip_Ēdināšana')), findsOneWidget);

      // Pārbaudām, ka abu vietu marķieri ir kartē
      expect(find.byKey(const Key('map_marker_p1')), findsOneWidget);
      expect(find.byKey(const Key('map_marker_p2')), findsOneWidget);

      // Pagaidām nav atvērta neviena vietas kartīte
      expect(find.byKey(const Key('map_selected_place_card')), findsNothing);
    });

    testWidgets('Tapping marker reveals sliding bottom card with place details', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        PiedzivoApp(
          geoCubit: geoCubit,
          eventsBloc: eventsBloc,
          eventsRepository: eventsRepo,
          placesBloc: placesBloc,
          placesRepository: placesRepo,
          router: createAppRouter(
            navigatorKey: GlobalKey<NavigatorState>(),
            initialLocation: '/places/map',
          ),
          startWithRouter: true,
        ),
      );

      await tester.runAsync(() async {
        if (placesBloc.state is! PlacesLoaded) {
          await placesBloc.stream.firstWhere((s) => s is PlacesLoaded);
        }
      });
      await tester.pumpAndSettle();

      // Nospiežam uz Cēsu pils marķiera
      await tester.tap(find.byKey(const Key('map_marker_p1')));
      await tester.pumpAndSettle();

      // Pārbaudām, ka kartīte parādījusies
      expect(find.byKey(const Key('map_selected_place_card')), findsOneWidget);
      expect(find.text('Cēsu viduslaiku pils'), findsOneWidget);
      expect(find.text('🟢 Atvērts līdz 18:00'), findsOneWidget);
      expect(find.text('APSKATES OBJEKTI'), findsOneWidget);
      expect(find.byKey(const Key('map_card_open_place_button')), findsOneWidget);

      // Aizveram kartīti ar [✕] pogu
      await tester.tap(find.byKey(const Key('close_map_place_card')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('map_selected_place_card')), findsNothing);
    });

    testWidgets('Tapping "Atvērt vietu" button navigates to /places/:id', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        PiedzivoApp(
          geoCubit: geoCubit,
          eventsBloc: eventsBloc,
          eventsRepository: eventsRepo,
          placesBloc: placesBloc,
          placesRepository: placesRepo,
          router: createAppRouter(
            navigatorKey: GlobalKey<NavigatorState>(),
            initialLocation: '/places/map',
          ),
          startWithRouter: true,
        ),
      );

      await tester.runAsync(() async {
        if (placesBloc.state is! PlacesLoaded) {
          await placesBloc.stream.firstWhere((s) => s is PlacesLoaded);
        }
      });
      await tester.pumpAndSettle();

      // Nospiežam uz marķiera
      await tester.tap(find.byKey(const Key('map_marker_p1')));
      await tester.pumpAndSettle();

      // Nospiežam "Atvērt vietu" pogu
      await tester.tap(find.byKey(const Key('map_card_open_place_button')));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 150));
      });
      await tester.pumpAndSettle();

      // Esam PlaceDetailScreen
      expect(find.byType(PlaceDetailScreen), findsOneWidget);
      expect(find.text('Cēsu viduslaiku pils'), findsOneWidget);
    });

    testWidgets('Tapping category filter chip filters markers on map', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        PiedzivoApp(
          geoCubit: geoCubit,
          eventsBloc: eventsBloc,
          eventsRepository: eventsRepo,
          placesBloc: placesBloc,
          placesRepository: placesRepo,
          router: createAppRouter(
            navigatorKey: GlobalKey<NavigatorState>(),
            initialLocation: '/places/map',
          ),
          startWithRouter: true,
        ),
      );

      await tester.runAsync(() async {
        if (placesBloc.state is! PlacesLoaded) {
          await placesBloc.stream.firstWhere((s) => s is PlacesLoaded);
        }
      });
      await tester.pumpAndSettle();

      // Atlasām tikai 'Ēdināšana'
      await tester.tap(find.byKey(const Key('map_filter_chip_Ēdināšana')));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      // Cēsu pils marķieris vairs nav redzams, Jāņoga marķieris ir redzams
      expect(find.byKey(const Key('map_marker_p2')), findsOneWidget);
      expect(find.byKey(const Key('map_marker_p1')), findsNothing);
    });

    testWidgets('Tapping back button pops back to previous screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        PiedzivoApp(
          geoCubit: geoCubit,
          eventsBloc: eventsBloc,
          eventsRepository: eventsRepo,
          placesBloc: placesBloc,
          placesRepository: placesRepo,
          router: createAppRouter(
            navigatorKey: GlobalKey<NavigatorState>(),
            initialLocation: '/places',
          ),
          startWithRouter: true,
        ),
      );

      await tester.runAsync(() async {
        if (placesBloc.state is! PlacesLoaded) {
          await placesBloc.stream.firstWhere((s) => s is PlacesLoaded);
        }
      });
      await tester.pumpAndSettle();

      // No /places pārejam uz karti
      await tester.tap(find.byKey(const Key('open_fullscreen_map_button')));
      await tester.pumpAndSettle();

      expect(find.byType(FullscreenMapScreen), findsOneWidget);

      // Nospiežam atpakaļ pogu
      await tester.tap(find.byKey(const Key('map_back_button')));
      await tester.pumpAndSettle();

      // Esam atgriezušies PlacesListScreen
      expect(find.byType(FullscreenMapScreen), findsNothing);
    });
  });
}

