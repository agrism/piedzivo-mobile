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
import 'package:piedzivo/features/events/models/event_detail.dart';
import 'package:piedzivo/features/events/repositories/events_repository.dart';
import 'package:piedzivo/features/events/screens/event_detail_screen.dart';
import 'package:piedzivo/features/places/bloc/places_bloc.dart';
import 'package:piedzivo/features/places/repositories/places_repository.dart';
import 'package:piedzivo/features/places/screens/place_detail_screen.dart';
import 'package:piedzivo/features/geo/cubit/geo_cubit.dart';
import 'package:piedzivo/features/geo/models/geo_place.dart';
import 'package:piedzivo/features/geo/repositories/geo_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../unit/api_client_test.dart';

void main() {
  group('Uzdevums 6: EventDetailScreen UI & Navigation tests', () {
    late FakeSecureStorage fakeStorage;
    late MockAdapter mockAdapter;
    late ApiClient apiClient;
    late EventsRepository eventsRepo;
    late EventsBloc eventsBloc;
    late PlacesRepository placesRepo;
    late PlacesBloc placesBloc;
    late GeoRepository geoRepo;
    late GeoCubit geoCubit;
    late AuthRepository authRepo;
    late AuthBloc authBloc;

    const sampleDetail = EventDetail(
      id: 'evt-100',
      slug: 'dso-koncerts',
      title: 'Daugavpils Simfoniskā orķestra koncerts',
      description: 'Lielisks klasiskās mūzikas koncerts Vienības namā ar izciliem solistiem.',
      imageUrl: 'https://piedzivo.lv/storage/events/dso.jpg',
      editorialPriority: 10,
      recommendationsCount: 42,
      isNew: true,
      isRecommendedByMe: false,
      isFollowedByMe: false,
      primaryTaxonomyName: 'Koncerts',
      priceLabel: 'no 10 €',
      priceDetails: 'Skolēniem un pensionāriem 5 €',
      isFree: false,
      ticketUrl: 'https://bilesuparadize.lv/lv/event/100',
      websiteUrl: 'https://vienibasnams.lv',
      startsOn: '2026-11-05',
      startsAt: '18:00:00',
      endsOn: '2026-11-05',
      endsAt: '20:30:00',
      placeId: 'place-daugavpils-vn',
      placeTitle: 'Vienības nams',
      placeCity: 'Daugavpils',
      placeAddress: 'Rīgas iela 22a',
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
        if (options.path.contains('/recommend') || options.path.contains('/follow')) {
          return ResponseBody.fromString(jsonEncode({'status': 'ok'}), 200);
        }
        if (options.path == '/events/evt-100') {
          return ResponseBody.fromString(
            jsonEncode({'data': sampleDetail.toJson()}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('/places/')) {
          return ResponseBody.fromString(
            jsonEncode({
              'data': {
                'id': 'place-daugavpils-vn',
                'title': 'Vienības nams',
                'slug': 'vienibas-nams',
                'city': 'Daugavpils',
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
      eventsRepo = EventsRepository(apiClient: apiClient);
      eventsBloc = EventsBloc(repository: eventsRepo);
      placesRepo = PlacesRepository(apiClient: apiClient);
      placesBloc = PlacesBloc(repository: placesRepo);
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

    testWidgets('renders all event detail elements correctly', (
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
            initialLocation: '/events/evt-100',
          ),
          startWithRouter: true,
        ),
      );

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();

      // Pārbaudām virsrakstu un aprakstu
      expect(find.text('Daugavpils Simfoniskā orķestra koncerts'), findsOneWidget);
      expect(find.text('Par pasākumu'), findsOneWidget);
      expect(
        find.text('Lielisks klasiskās mūzikas koncerts Vienības namā ar izciliem solistiem.'),
        findsOneWidget,
      );

      // Pārbaudām birkas
      expect(find.text('Koncerts'), findsOneWidget);
      expect(find.text('🎟️ no 10 €'), findsOneWidget);
      expect(find.text('⭐ Piedzīvo ieteikums'), findsOneWidget);
      expect(find.text('✨ JAUNS'), findsOneWidget);

      // Pārbaudām norises vietu
      expect(find.text('Vienības nams'), findsOneWidget);
      expect(find.text('Rīgas iela 22a, Daugavpils'), findsOneWidget);

      // Pārbaudām pogas
      expect(find.byKey(const Key('event_detail_ticket_button')), findsOneWidget);
      expect(find.text('Pirkt biļetes'), findsOneWidget);
      expect(find.text('Skolēniem un pensionāriem 5 €'), findsOneWidget);
      expect(find.text('Iesaku (42)'), findsOneWidget);
      expect(find.text('Sekot'), findsOneWidget);

      // Pārbaudām zoom pogu un atpakaļ pogu
      expect(find.byKey(const Key('event_detail_zoom_button')), findsOneWidget);
      expect(find.byKey(const Key('event_detail_back_button')), findsOneWidget);
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
            initialLocation: '/events/evt-100',
          ),
          startWithRouter: true,
        ),
      );

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();

      // Sākotnēji: 42 ieteikumi, "Sekot"
      expect(find.text('Iesaku (42)'), findsOneWidget);
      expect(find.text('Sekot'), findsOneWidget);

      // Nospiežam "Iesaku"
      await tester.ensureVisible(find.byKey(const Key('event_detail_recommend_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('event_detail_recommend_button')));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      // Skaitītājs palielinās uz 43
      expect(find.text('Iesaku (43)'), findsOneWidget);

      // Nospiežam "Sekot"
      await tester.ensureVisible(find.byKey(const Key('event_detail_follow_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('event_detail_follow_button')));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      // Statuss nomainās uz "Sekoju"
      expect(find.text('Sekoju'), findsOneWidget);
    });

    testWidgets('Tapping venue card navigates to PlaceDetailScreen', (
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
            initialLocation: '/events/evt-100',
          ),
          startWithRouter: true,
        ),
      );

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();

      // Nospiežam uz norises vietas kartītes
      await tester.ensureVisible(find.byKey(const Key('event_venue_card')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('event_venue_card')));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 150));
      });
      await tester.pumpAndSettle();

      // Pārbaudām, ka esam pārgājuši uz PlaceDetailScreen
      expect(find.byType(PlaceDetailScreen), findsOneWidget);
      expect(find.text('Vienības nams'), findsOneWidget);
    });

    testWidgets('Tapping back button pops back to previous screen', (
      WidgetTester tester,
    ) async {
      final navKey = GlobalKey<NavigatorState>();
      final router = createAppRouter(
        navigatorKey: navKey,
        initialLocation: '/events',
      );

      mockAdapter.handler = (options) {
        if (options.path.contains('/events/evt-100')) {
          return ResponseBody.fromString(
            jsonEncode({'data': sampleDetail.toJson()}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        } else if (options.path.contains('/events')) {
          return ResponseBody.fromString(
            jsonEncode({
              'data': [
                {
                  'id': 'evt-100',
                  'slug': 'dso-koncerts',
                  'title': 'Daugavpils Simfoniskā orķestra koncerts',
                  'starts_on': '2026-11-05',
                  'price_badge': {'label': 'no 10 €', 'type': 'paid'},
                }
              ]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString(jsonEncode({'status': 'ok'}), 200);
      };

      await tester.pumpWidget(
        PiedzivoApp(
          apiClient: apiClient,
          authBloc: authBloc,
          geoCubit: geoCubit,
          eventsBloc: eventsBloc,
          eventsRepository: eventsRepo,
          placesBloc: placesBloc,
          placesRepository: placesRepo,
          router: router,
          startWithRouter: true,
        ),
      );

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();

      // Atveram pasākuma detaļas
      router.push('/events/evt-100');
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();

      expect(find.byType(EventDetailScreen), findsOneWidget);

      // Nospiežam atpakaļ pogu
      await tester.tap(find.byKey(const Key('event_detail_back_button')));
      await tester.pumpAndSettle();

      // Esam atgriezušies pasākumu sarakstā
      expect(find.byType(EventDetailScreen), findsNothing);
    });
  });
}

