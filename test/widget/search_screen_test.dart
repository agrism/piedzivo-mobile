import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piedzivo/app.dart';
import 'package:piedzivo/core/navigation/app_router.dart';
import 'package:piedzivo/core/network/api_client.dart';
import 'package:piedzivo/core/theme/app_theme.dart';
import 'package:piedzivo/features/events/bloc/events_bloc.dart';
import 'package:piedzivo/features/events/models/event_list_item.dart';
import 'package:piedzivo/features/events/repositories/events_repository.dart';
import 'package:piedzivo/features/events/screens/event_detail_screen.dart';
import 'package:piedzivo/features/geo/cubit/geo_cubit.dart';
import 'package:piedzivo/features/geo/models/geo_place.dart';
import 'package:piedzivo/features/geo/repositories/geo_repository.dart';
import 'package:piedzivo/features/places/bloc/places_bloc.dart';
import 'package:piedzivo/features/places/models/place_list_item.dart';
import 'package:piedzivo/features/places/repositories/places_repository.dart';
import 'package:piedzivo/features/search/bloc/search_bloc.dart';
import 'package:piedzivo/features/search/bloc/search_state.dart';
import 'package:piedzivo/features/search/screens/search_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../unit/api_client_test.dart';

void main() {
  group('Uzdevums 10: SearchScreen UI Tests', () {
    late FakeSecureStorage fakeStorage;
    late MockAdapter mockAdapter;
    late ApiClient apiClient;
    late EventsRepository eventsRepo;
    late EventsBloc eventsBloc;
    late PlacesRepository placesRepo;
    late PlacesBloc placesBloc;
    late SearchBloc searchBloc;
    late GeoRepository geoRepo;
    late GeoCubit geoCubit;

    const placeCesis = GeoPlace(
      id: 'city-cesis',
      name: 'Cēsis',
      slug: 'cesis',
      type: 'city',
      isStateCity: false,
    );

    const mockEvent1 = EventListItem(
      id: 'e1',
      slug: 'cesu-pils-koncerts',
      title: 'Cēsu pils koncerts',
      editorialPriority: 10,
      recommendationsCount: 15,
      isNew: true,
      isRecommendedByMe: false,
      isFollowedByMe: false,
      priceLabel: '10 €',
      isFree: false,
      startsOn: '2026-11-01',
      startsAt: '19:00:00',
      placeTitle: 'Cēsu pils',
      placeCity: 'Cēsis',
    );

    const mockEventNationwide = EventListItem(
      id: 'e2',
      slug: 'nacionala-opera',
      title: 'Nacionālā Opera Rīgā',
      editorialPriority: 5,
      recommendationsCount: 30,
      isNew: false,
      isRecommendedByMe: false,
      isFollowedByMe: false,
      priceLabel: '20 €',
      isFree: false,
      startsOn: '2026-11-05',
      startsAt: '19:00:00',
      placeTitle: 'Latvijas Nacionālā Opera',
      placeCity: 'Rīga',
    );

    const mockPlace1 = PlaceListItem(
      id: 'p1',
      slug: 'cesu-pils',
      title: 'Cēsu viduslaiku pils',
      city: 'Cēsis',
      latitude: 57.313,
      longitude: 25.271,
      primaryImageUrl: 'https://piedzivo.lv/storage/places/pils.jpg',
      imagesCount: 4,
      editorialPriority: 10,
      recommendationsCount: 50,
      upcomingEventsCount: 3,
      isNew: false,
      isRecommendedByMe: false,
      isFollowedByMe: false,
      isOpen: true,
      openingLabel: 'Atvērts līdz 18:00',
      rootCategoryName: 'Apskates objekti',
      primaryTaxonomyName: 'Pilis un muižas',
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
        final path = options.path;

        if (path.startsWith('/events/e1')) {
          return ResponseBody.fromString(
            jsonEncode({
              'data': {
                'id': 'e1',
                'title': 'Cēsu pils koncerts',
                'slug': 'cesu-pils-koncerts',
                'starts_on': '2026-11-01',
                'starts_at': '19:00:00',
                'is_free': false,
                'price_min': 10.0,
                'price_max': 15.0,
                'editorial_priority': 5,
                'recommendations_count': 10,
                'is_new': false,
                'is_recommended_by_me': false,
                'is_followed_by_me': false,
              },
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }

        if (path.startsWith('/events')) {
          final q = options.queryParameters['q'] as String? ?? '';
          final placeId = (options.queryParameters['geo_place_id'] ?? options.queryParameters['place_id']) as String?;

          // If searching in Cēsis for "opera", return empty (to test nationwide fallback)
          if (q.contains('opera') && placeId != null) {
            return ResponseBody.fromString(
              jsonEncode({'data': []}),
              200,
              headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
            );
          }

          if (q.contains('opera') && placeId == null) {
            return ResponseBody.fromString(
              jsonEncode({
                'data': [mockEventNationwide.toJson()],
              }),
              200,
              headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
            );
          }

          return ResponseBody.fromString(
            jsonEncode({
              'data': [mockEvent1.toJson()],
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }

        if (path.startsWith('/places')) {
          final q = options.queryParameters['q'] as String? ?? '';
          final placeId = (options.queryParameters['geo_place_id'] ?? options.queryParameters['place_id']) as String?;

          if (q.contains('opera') && placeId != null) {
            return ResponseBody.fromString(
              jsonEncode({'data': []}),
              200,
              headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
            );
          }

          return ResponseBody.fromString(
            jsonEncode({
              'data': [mockPlace1.toJson()],
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
      eventsRepo = EventsRepository(apiClient: apiClient);
      eventsBloc = EventsBloc(repository: eventsRepo);
      placesRepo = PlacesRepository(apiClient: apiClient);
      placesBloc = PlacesBloc(repository: placesRepo);
      searchBloc = SearchBloc(
        eventsRepository: eventsRepo,
        placesRepository: placesRepo,
      );

      geoRepo = GeoRepository(apiClient: apiClient);
      geoCubit = GeoCubit(geoRepository: geoRepo);
      await geoCubit.loadPlaces(serverChecksum: 'chk1');
      await geoCubit.selectPlace(placeCesis);
    });

    tearDown(() {
      eventsBloc.close();
      placesBloc.close();
      searchBloc.close();
      geoCubit.close();
    });

    testWidgets('renders search bar, scope switchers, and suggestions on initial load', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        PiedzivoApp(
          apiClient: apiClient,
          geoCubit: geoCubit,
          eventsBloc: eventsBloc,
          eventsRepository: eventsRepo,
          placesBloc: placesBloc,
          placesRepository: placesRepo,
          searchBloc: searchBloc,
          router: createAppRouter(
            navigatorKey: GlobalKey<NavigatorState>(),
            initialLocation: '/search',
          ),
          startWithRouter: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SearchScreen), findsOneWidget);
      expect(find.byKey(const Key('search_input_field')), findsOneWidget);
      expect(find.byKey(const Key('search_scope_city')), findsOneWidget);
      expect(find.byKey(const Key('search_scope_all')), findsOneWidget);
      expect(find.text('Cēsis'), findsOneWidget);
      expect(find.text('Visā Latvijā'), findsOneWidget);

      // Suggestions chips
      expect(find.text('Ieteiktie meklējumi'), findsOneWidget);
      expect(find.byKey(const Key('search_chip_Koncerti')), findsOneWidget);
      expect(find.byKey(const Key('search_chip_Teātris')), findsOneWidget);
    });

    testWidgets('clicking suggestion chip triggers immediate search and displays results', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        PiedzivoApp(
          apiClient: apiClient,
          geoCubit: geoCubit,
          eventsBloc: eventsBloc,
          eventsRepository: eventsRepo,
          placesBloc: placesBloc,
          placesRepository: placesRepo,
          searchBloc: searchBloc,
          router: createAppRouter(
            navigatorKey: GlobalKey<NavigatorState>(),
            initialLocation: '/search',
          ),
          startWithRouter: true,
        ),
      );
      await tester.pumpAndSettle();

      // Click on "Koncerti" chip
      await tester.tap(find.byKey(const Key('search_chip_Koncerti')));
      await tester.pump();
      await tester.runAsync(() async {
        if (searchBloc.state.status != SearchStatus.success) {
          await searchBloc.stream.firstWhere((s) => s.status == SearchStatus.success);
        }
      });
      await tester.pumpAndSettle();

      // Results should show tabs and items
      expect(find.byKey(const Key('search_tab_all')), findsOneWidget);
      expect(find.byKey(const Key('search_tab_events')), findsOneWidget);
      expect(find.byKey(const Key('search_tab_places')), findsOneWidget);

      expect(find.text('Cēsu pils koncerts'), findsOneWidget);
      expect(find.text('Cēsu viduslaiku pils'), findsOneWidget);
    });

    testWidgets('switching tabs filters events and places', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        PiedzivoApp(
          apiClient: apiClient,
          geoCubit: geoCubit,
          eventsBloc: eventsBloc,
          eventsRepository: eventsRepo,
          placesBloc: placesBloc,
          placesRepository: placesRepo,
          searchBloc: searchBloc,
          router: createAppRouter(
            navigatorKey: GlobalKey<NavigatorState>(),
            initialLocation: '/search',
          ),
          startWithRouter: true,
        ),
      );
      await tester.pumpAndSettle();

      // Enter search query to load results
      await tester.enterText(find.byKey(const Key('search_input_field')), 'pils');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Cēsu pils koncerts'), findsOneWidget);
      expect(find.text('Cēsu viduslaiku pils'), findsOneWidget);

      // Tap "Pasākumi" tab
      await tester.tap(find.byKey(const Key('search_tab_events')));
      await tester.pump();
      await tester.runAsync(() async {
        if (searchBloc.state.selectedTab != SearchTab.events) {
          await searchBloc.stream.firstWhere((s) => s.selectedTab == SearchTab.events);
        }
      });
      await tester.pumpAndSettle();

      expect(find.text('Cēsu pils koncerts'), findsOneWidget);
      expect(find.text('Cēsu viduslaiku pils'), findsNothing);

      // Tap "Vietas" tab
      await tester.tap(find.byKey(const Key('search_tab_places')));
      await tester.pump();
      await tester.runAsync(() async {
        if (searchBloc.state.selectedTab != SearchTab.places) {
          await searchBloc.stream.firstWhere((s) => s.selectedTab == SearchTab.places);
        }
      });
      await tester.pumpAndSettle();

      expect(find.text('Cēsu pils koncerts'), findsNothing);
      expect(find.text('Cēsu viduslaiku pils'), findsOneWidget);

      expect(find.text('Cēsu pils koncerts'), findsNothing);
      expect(find.text('Cēsu viduslaiku pils'), findsOneWidget);
    });

    testWidgets('typing text debounces 300ms, clear button clears input and state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        PiedzivoApp(
          apiClient: apiClient,
          geoCubit: geoCubit,
          eventsBloc: eventsBloc,
          eventsRepository: eventsRepo,
          placesBloc: placesBloc,
          placesRepository: placesRepo,
          searchBloc: searchBloc,
          router: createAppRouter(
            navigatorKey: GlobalKey<NavigatorState>(),
            initialLocation: '/search',
          ),
          startWithRouter: true,
        ),
      );
      await tester.pumpAndSettle();

      // Enter query
      await tester.enterText(find.byKey(const Key('search_input_field')), 'pils');
      await tester.pump();

      // Clear button should be visible
      expect(find.byKey(const Key('search_clear_button')), findsOneWidget);

      // Advance debounce timer (300 ms)
      await tester.pump(const Duration(milliseconds: 350));
      await tester.runAsync(() async {
        if (searchBloc.state.status != SearchStatus.success) {
          await searchBloc.stream.firstWhere((s) => s.status == SearchStatus.success);
        }
      });
      await tester.pumpAndSettle();

      expect(find.text('Cēsu pils koncerts'), findsOneWidget);

      // Tap clear button
      await tester.tap(find.byKey(const Key('search_clear_button')));
      await tester.pumpAndSettle();

      // Input should be empty and suggestion chips back
      expect(find.text('Ieteiktie meklējumi'), findsOneWidget);
      expect(find.byKey(const Key('search_clear_button')), findsNothing);
    });

    testWidgets('0-result fallback prompts to search nationwide and executes search', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        PiedzivoApp(
          apiClient: apiClient,
          geoCubit: geoCubit,
          eventsBloc: eventsBloc,
          eventsRepository: eventsRepo,
          placesBloc: placesBloc,
          placesRepository: placesRepo,
          searchBloc: searchBloc,
          router: createAppRouter(
            navigatorKey: GlobalKey<NavigatorState>(),
            initialLocation: '/search',
          ),
          startWithRouter: true,
        ),
      );
      await tester.pumpAndSettle();

      // Type "opera" which returns empty in Cēsis
      await tester.enterText(find.byKey(const Key('search_input_field')), 'opera');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.runAsync(() async {
        if (searchBloc.state.status != SearchStatus.success) {
          await searchBloc.stream.firstWhere((s) => s.status == SearchStatus.success);
        }
      });
      await tester.pumpAndSettle();

      // Should show 0-result fallback with city name
      expect(find.text('Nav atrasts Cēsis'), findsOneWidget);
      expect(find.byKey(const Key('search_nationwide_button')), findsOneWidget);

      // Tap "Meklēt visā Latvijā"
      await tester.tap(find.byKey(const Key('search_nationwide_button')));
      await tester.pump();
      await tester.runAsync(() async {
        if (searchBloc.state.status != SearchStatus.success || !searchBloc.state.isLatviaWide) {
          await searchBloc.stream.firstWhere((s) => s.status == SearchStatus.success && s.isLatviaWide);
        }
      });
      await tester.pumpAndSettle();

      // Now nationwide results should appear
      expect(find.text('Nacionālā Opera Rīgā'), findsOneWidget);
    });

    testWidgets('tapping event card navigates to EventDetailScreen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        PiedzivoApp(
          apiClient: apiClient,
          geoCubit: geoCubit,
          eventsBloc: eventsBloc,
          eventsRepository: eventsRepo,
          placesBloc: placesBloc,
          placesRepository: placesRepo,
          searchBloc: searchBloc,
          router: createAppRouter(
            navigatorKey: GlobalKey<NavigatorState>(),
            initialLocation: '/search',
          ),
          startWithRouter: true,
        ),
      );
      await tester.pumpAndSettle();

      // Search
      await tester.tap(find.byKey(const Key('search_chip_Koncerti')));
      await tester.pump();
      await tester.runAsync(() async {
        if (searchBloc.state.status != SearchStatus.success) {
          await searchBloc.stream.firstWhere((s) => s.status == SearchStatus.success);
        }
      });
      await tester.pumpAndSettle();

      // Tap event card
      await tester.tap(find.text('Cēsu pils koncerts'));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // Should navigate to EventDetailScreen
      expect(find.byType(EventDetailScreen), findsOneWidget);
    });
  });
}
