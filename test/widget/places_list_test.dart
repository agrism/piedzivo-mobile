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
import 'package:piedzivo/features/places/widgets/places_mini_map.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../unit/api_client_test.dart';

void main() {
  group('Uzdevums 7: PlacesListScreen UI tests', () {
    late FakeSecureStorage fakeStorage;
    late MockAdapter mockAdapter;
    late ApiClient apiClient;
    late PlacesRepository placesRepo;
    late PlacesBloc placesBloc;
    late EventsRepository eventsRepo;
    late EventsBloc eventsBloc;
    late GeoRepository geoRepo;
    late GeoCubit geoCubit;

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

    const mockPlace2 = PlaceListItem(
      id: 'p2',
      slug: 'restorans-janoga',
      title: 'Restorāns Jāņoga',
      city: 'Cēsis',
      latitude: 57.315,
      longitude: 25.275,
      primaryImageUrl: 'https://piedzivo.lv/storage/places/janoga.jpg',
      imagesCount: 6,
      editorialPriority: 5,
      recommendationsCount: 80,
      upcomingEventsCount: 0,
      isNew: true,
      isRecommendedByMe: false,
      isFollowedByMe: false,
      isOpen: false,
      openingLabel: 'Slēgts (atvērsies 12:00)',
      rootCategoryName: 'Ēdināšana',
      primaryTaxonomyName: 'Restorāni',
    );

    const placeCesis = GeoPlace(
      id: 'city-cesis',
      name: 'Cēsis',
      slug: 'cesis',
      type: 'city',
      isStateCity: false,
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
        if (options.path.contains('/places') && !options.path.contains('/recommend') && !options.path.contains('/follow')) {
          return ResponseBody.fromString(
            jsonEncode({
              'data': [mockPlace1.toJson(), mockPlace2.toJson()],
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        } else if (options.path.contains('/events')) {
          return ResponseBody.fromString(jsonEncode({'data': []}), 200);
        } else if (options.path.contains('/recommend') || options.path.contains('/follow')) {
          return ResponseBody.fromString(jsonEncode({'status': 'ok'}), 200);
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

    testWidgets('renders PlacesMiniMap, category headers and PlaceCard elements', (
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

      // Pārbaudām mini-karti
      expect(find.byType(PlacesMiniMap), findsOneWidget);
      expect(find.byKey(const Key('open_fullscreen_map_button')), findsOneWidget);

      // Pārbaudām sadaļu virsrakstus
      expect(find.text('APSKATES OBJEKTI (1)'), findsOneWidget);
      expect(find.text('ĒDINĀŠANA (1)'), findsOneWidget);

      // Pārbaudām 1. vietas kartīti
      expect(find.text('Cēsu viduslaiku pils'), findsOneWidget);
      expect(find.text('🟢 Atvērts līdz 18:00'), findsOneWidget);
      expect(find.text('⭐ Piedzīvo'), findsNWidgets(2));
      expect(find.text('4'), findsOneWidget); // 4 bildes
      expect(find.text('🎟️ 3 gaidāmi pasākumi'), findsOneWidget);
      expect(find.text('50'), findsOneWidget); // Ieteikumi

      // Pārbaudām 2. vietas kartīti
      expect(find.text('Restorāns Jāņoga'), findsOneWidget);
      expect(find.text('🔴 Slēgts (atvērsies 12:00)'), findsOneWidget);
      expect(find.text('✨ JAUNS'), findsOneWidget);
      expect(find.text('6'), findsOneWidget); // 6 bildes
      expect(find.text('80'), findsOneWidget); // Ieteikumi

      // Taps uz 'Ēdināšana' kategorijas čipa
      await tester.tap(find.byKey(const Key('places_category_chip_Ēdināšana')));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // Redzams tikai ēdināšanas objekts
      expect(find.text('Restorāns Jāņoga'), findsOneWidget);
      expect(find.text('Cēsu viduslaiku pils'), findsNothing);
    });

    testWidgets('Tapping recommend button on PlaceCard increments counter optimistically', (
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

      expect(find.text('50'), findsOneWidget);

      // Taps uz 'Iesaku' pogas Cēsu pilij
      await tester.tap(find.byKey(const Key('place_recommend_p1')));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(find.text('51'), findsOneWidget);
    });

    testWidgets('Tapping open map button navigates to /places/map', (
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

      // Nospiežam "Atvērt karti"
      await tester.tap(find.byKey(const Key('open_fullscreen_map_button')));
      await tester.pumpAndSettle();

      // Pārbaudām, ka esam FullscreenMapScreen
      expect(find.byType(FullscreenMapScreen), findsOneWidget);
      expect(find.byKey(const Key('map_back_button')), findsOneWidget);
    });

    testWidgets('Tapping PlaceCard navigates to /places/:id', (
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

      // Nospiežam uz Cēsu pils kartītes
      await tester.tap(find.text('Cēsu viduslaiku pils'));
      await tester.pumpAndSettle();

      // Pārbaudām, ka esam PlaceDetailScreen
      expect(find.textContaining('p1'), findsOneWidget);
    });
  });
}

