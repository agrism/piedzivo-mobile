import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piedzivo/app.dart';
import 'package:piedzivo/core/navigation/app_router.dart';
import 'package:piedzivo/core/network/api_client.dart';
import 'package:piedzivo/core/theme/app_theme.dart';
import 'package:piedzivo/features/auth/bloc/auth_bloc.dart';
import 'package:piedzivo/features/auth/bloc/auth_state.dart';
import 'package:piedzivo/features/auth/models/user.dart';
import 'package:piedzivo/features/auth/repositories/auth_repository.dart';
import 'package:piedzivo/features/events/bloc/events_bloc.dart';
import 'package:piedzivo/features/events/repositories/events_repository.dart';
import 'package:piedzivo/features/events/screens/event_detail_screen.dart';
import 'package:piedzivo/features/geo/cubit/geo_cubit.dart';
import 'package:piedzivo/features/geo/models/geo_place.dart';
import 'package:piedzivo/features/geo/repositories/geo_repository.dart';
import 'package:piedzivo/features/places/bloc/places_bloc.dart';
import 'package:piedzivo/features/places/bloc/places_state.dart';
import 'package:piedzivo/features/places/models/place_detail.dart';
import 'package:piedzivo/features/places/repositories/places_repository.dart';
import 'package:piedzivo/features/places/screens/place_detail_screen.dart';
import 'package:piedzivo/features/places/widgets/place_gallery_zoom_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../unit/api_client_test.dart';

void main() {
  group('Uzdevums 9: PlaceDetailScreen & Navigation tests', () {
    late FakeSecureStorage fakeStorage;
    late MockAdapter mockAdapter;
    late ApiClient apiClient;
    late PlacesRepository placesRepo;
    late PlacesBloc placesBloc;
    late EventsRepository eventsRepo;
    late EventsBloc eventsBloc;
    late GeoRepository geoRepo;
    late GeoCubit geoCubit;
    late AuthRepository authRepo;
    late AuthBloc authBloc;

    const placeCesis = GeoPlace(
      id: 'city-cesis',
      name: 'Cēsis',
      slug: 'cesis',
      type: 'city',
      isStateCity: false,
    );

    final mockPlaceDetail = PlaceDetail.fromJson(const {
      'id': 'p1',
      'public_id': 'cesis-castle',
      'slug': 'cesu-pils',
      'title': 'Cēsu viduslaiku pils',
      'description': 'Vēsturisks cietoksnis un muzejs Cēsu centrā.',
      'city': 'Cēsis',
      'address': 'Pils laukums 9',
      'latitude': 57.3131,
      'longitude': 25.2715,
      'phone': '+371 64121815',
      'email': 'pils@cesis.lv',
      'website_url': 'https://cesupils.lv',
      'primary_image_url': 'https://cdn.piedzivo.lv/places/p1-1.jpg',
      'images': [
        'https://cdn.piedzivo.lv/places/p1-1.jpg',
        'https://cdn.piedzivo.lv/places/p1-2.jpg',
        'https://cdn.piedzivo.lv/places/p1-3.jpg',
      ],
      'editorial_priority': 10,
      'recommendations_count': 50,
      'upcoming_events_count': 1,
      'is_new': false,
      'is_recommended_by_me': false,
      'is_followed_by_me': false,
      'opening_status': {
        'is_open': true,
        'label': '🟢 Atvērts līdz 18:00',
      },
      'root_category': {'name': 'Apskates objekti'},
      'primary_taxonomy': {'name': 'Vēsturiskās vietas'},
      'weekly_schedule': [
        {'day_name': 'Pirmdiena', 'hours': 'Slēgts', 'is_closed': true},
        {'day_name': 'Otrdiena', 'hours': '10:00 - 18:00', 'is_closed': false, 'is_today': true},
        {'day_name': 'Trešdiena', 'hours': '10:00 - 18:00', 'is_closed': false},
      ],
      'upcoming_events': [
        {
          'id': 'evt-1',
          'slug': 'koncerts-pili',
          'title': 'Akustiskais koncerts pilī',
          'city': 'Cēsis',
          'price_badge': {'type': 'paid', 'label': '🎟️ no 12 €'},
          'primary_taxonomy': {'name': 'Koncerts'},
          'occurrence': {'starts_on': 'Šodien', 'starts_at': '19:00'},
        },
      ],
    });

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
        if (options.path == '/places/p1' || options.path.contains('/places/p1')) {
          return ResponseBody.fromString(
            jsonEncode({'data': mockPlaceDetail.toJson()}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.startsWith('/places')) {
          return ResponseBody.fromString(
            jsonEncode({'data': [mockPlaceDetail.toJson()]}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.startsWith('/events/')) {
          return ResponseBody.fromString(
            jsonEncode({
              'data': {
                'id': 'evt-1',
                'title': 'Akustiskais koncerts pilī',
                'slug': 'akustiskais-koncerts',
                'description': 'Apraksts',
                'primary_taxonomy': {'name': 'Koncerts'},
                'price_badge': {'type': 'paid', 'label': '🎟️ no 12 €'},
                'occurrence': {'starts_on': 'Šodien', 'starts_at': '19:00'},
                'place': {'id': 'p1', 'title': 'Cēsu viduslaiku pils', 'city': 'Cēsis'},
              }
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
      authRepo = AuthRepository(apiClient: apiClient);
      authBloc = AuthBloc(
        authRepository: authRepo,
        initialState: const AuthState(
          status: AuthStatus.authenticated,
          user: User(id: 'u1', email: 'janis@test.lv', name: 'Jānis'),
        ),
      );
      geoRepo = GeoRepository(apiClient: apiClient);
      geoCubit = GeoCubit(geoRepository: geoRepo);
      await geoCubit.loadPlaces(serverChecksum: 'chk1');
    });

    tearDown(() {
      authBloc.close();
    });

    testWidgets('renders all place detail elements correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        PiedzivoApp(
          apiClient: apiClient,
          authBloc: authBloc,
          geoCubit: geoCubit,
          eventsBloc: eventsBloc,
          eventsRepository: eventsRepo,
          placesBloc: placesBloc,
          placesRepository: placesRepo,
          router: createAppRouter(
            navigatorKey: GlobalKey<NavigatorState>(),
            initialLocation: '/places/p1',
          ),
          startWithRouter: true,
        ),
      );

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 150));
      });
      await tester.pumpAndSettle();

      expect(find.byType(PlaceDetailScreen), findsOneWidget);

      // Galerija un skaitītājs
      expect(find.text('1 / 3'), findsOneWidget);
      expect(find.byKey(const Key('place_image_zoom_button')), findsOneWidget);

      // Nosaukums, adrese, birkas
      expect(find.text('Cēsu viduslaiku pils'), findsOneWidget);
      expect(find.text('Pils laukums 9, Cēsis'), findsOneWidget);
      expect(find.text('APSKATES OBJEKTI'), findsOneWidget);
      expect(find.text('⭐ Piedzīvo'), findsOneWidget);

      // Darba laiks
      expect(find.text('🟢 Atvērts līdz 18:00'), findsOneWidget);
      expect(find.byKey(const Key('toggle_opening_schedule_button')), findsOneWidget);

      // Ārējā navigācija
      expect(find.byKey(const Key('open_waze_button')), findsOneWidget);
      expect(find.byKey(const Key('open_google_maps_button')), findsOneWidget);

      // Sociālās pogas
      expect(find.byKey(const Key('place_detail_recommend_button')), findsOneWidget);
      expect(find.text('Iesaku (50)'), findsOneWidget);
      expect(find.byKey(const Key('place_detail_follow_button')), findsOneWidget);

      // Apraksts un kontakti
      expect(find.text('Par vietu'), findsOneWidget);
      expect(find.text('Vēsturisks cietoksnis un muzejs Cēsu centrā.'), findsOneWidget);
      expect(find.text('+371 64121815'), findsOneWidget);
      expect(find.text('https://cesupils.lv'), findsOneWidget);

      // Gaidāmie pasākumi
      expect(find.text('Gaidāmie pasākumi (1)'), findsOneWidget);
      expect(find.text('Akustiskais koncerts pilī'), findsOneWidget);
    });

    testWidgets('Tapping gallery image zoom opens PlaceGalleryZoomDialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        PiedzivoApp(
          apiClient: apiClient,
          authBloc: authBloc,
          geoCubit: geoCubit,
          eventsBloc: eventsBloc,
          eventsRepository: eventsRepo,
          placesBloc: placesBloc,
          placesRepository: placesRepo,
          router: createAppRouter(
            navigatorKey: GlobalKey<NavigatorState>(),
            initialLocation: '/places/p1',
          ),
          startWithRouter: true,
        ),
      );

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 150));
      });
      await tester.pumpAndSettle();

      // Nospiežam palielināšanas pogu
      await tester.tap(find.byKey(const Key('place_image_zoom_button')));
      await tester.pumpAndSettle();

      expect(find.byType(PlaceGalleryZoomDialog), findsOneWidget);
      expect(find.byKey(const Key('close_gallery_zoom_dialog')), findsOneWidget);

      // Aizveram dialogu
      await tester.tap(find.byKey(const Key('close_gallery_zoom_dialog')));
      await tester.pumpAndSettle();

      expect(find.byType(PlaceGalleryZoomDialog), findsNothing);
    });

    testWidgets('Tapping opening hours expands and collapses weekly schedule', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        PiedzivoApp(
          apiClient: apiClient,
          authBloc: authBloc,
          geoCubit: geoCubit,
          eventsBloc: eventsBloc,
          eventsRepository: eventsRepo,
          placesBloc: placesBloc,
          placesRepository: placesRepo,
          router: createAppRouter(
            navigatorKey: GlobalKey<NavigatorState>(),
            initialLocation: '/places/p1',
          ),
          startWithRouter: true,
        ),
      );

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 150));
      });
      await tester.pumpAndSettle();

      // Sākumā nedēļas dienas nav izvērstas
      expect(find.text('Pirmdiena'), findsNothing);

      // Izvēršam darba laiku
      await tester.tap(find.byKey(const Key('toggle_opening_schedule_button')));
      await tester.pumpAndSettle();

      expect(find.text('Pirmdiena'), findsOneWidget);
      expect(find.text('Otrdiena'), findsOneWidget);
      expect(find.text('Trešdiena'), findsOneWidget);

      // Sakļaujam atpakaļ
      await tester.tap(find.byKey(const Key('toggle_opening_schedule_button')));
      await tester.pumpAndSettle();

      expect(find.text('Pirmdiena'), findsNothing);
    });

    testWidgets('Tapping recommend and follow buttons updates UI optimistically', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        PiedzivoApp(
          apiClient: apiClient,
          authBloc: authBloc,
          geoCubit: geoCubit,
          eventsBloc: eventsBloc,
          eventsRepository: eventsRepo,
          placesBloc: placesBloc,
          placesRepository: placesRepo,
          router: createAppRouter(
            navigatorKey: GlobalKey<NavigatorState>(),
            initialLocation: '/places/p1',
          ),
          startWithRouter: true,
        ),
      );

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 150));
      });
      await tester.pumpAndSettle();

      // "Iesaku" optimistisks skaitītājs
      await tester.ensureVisible(find.byKey(const Key('place_detail_recommend_button')));
      expect(find.text('Iesaku (50)'), findsOneWidget);
      await tester.tap(find.byKey(const Key('place_detail_recommend_button')));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(find.text('Iesaku (51)'), findsOneWidget);

      // "Sekoju" optimistisks toggle
      await tester.ensureVisible(find.byKey(const Key('place_detail_follow_button')));
      expect(find.text('Sekot'), findsOneWidget);
      await tester.tap(find.byKey(const Key('place_detail_follow_button')));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(find.text('Sekoju'), findsOneWidget);
    });

    testWidgets('Tapping upcoming event tile navigates to /events/:id', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        PiedzivoApp(
          apiClient: apiClient,
          authBloc: authBloc,
          geoCubit: geoCubit,
          eventsBloc: eventsBloc,
          eventsRepository: eventsRepo,
          placesBloc: placesBloc,
          placesRepository: placesRepo,
          router: createAppRouter(
            navigatorKey: GlobalKey<NavigatorState>(),
            initialLocation: '/places/p1',
          ),
          startWithRouter: true,
        ),
      );

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 150));
      });
      await tester.pumpAndSettle();

      // Nospiežam uz gaidāmā pasākuma
      await tester.ensureVisible(find.byKey(const Key('place_event_tile_evt-1')));
      await tester.tap(find.byKey(const Key('place_event_tile_evt-1')));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 150));
      });
      await tester.pumpAndSettle();

      // Esam EventDetailScreen
      expect(find.byType(EventDetailScreen), findsOneWidget);
      expect(find.text('Akustiskais koncerts pilī'), findsOneWidget);
    });

    testWidgets('Tapping back button pops back to previous screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        PiedzivoApp(
          apiClient: apiClient,
          authBloc: authBloc,
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

      // Nospiežam uz kartītes sarakstā
      await tester.tap(find.text('Cēsu viduslaiku pils'));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 150));
      });
      await tester.pumpAndSettle();

      expect(find.byType(PlaceDetailScreen), findsOneWidget);

      // Nospiežam atpakaļ
      await tester.tap(find.byKey(const Key('place_detail_back_button')));
      await tester.pumpAndSettle();

      // Atpakaļ sarakstā
      expect(find.byType(PlaceDetailScreen), findsNothing);
    });
  });
}

