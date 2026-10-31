import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piedzivo/app.dart';
import 'package:piedzivo/core/network/api_client.dart';
import 'package:piedzivo/core/theme/app_theme.dart';
import 'package:piedzivo/features/auth/bloc/auth_bloc.dart';
import 'package:piedzivo/features/auth/bloc/auth_state.dart';
import 'package:piedzivo/features/auth/models/user.dart';
import 'package:piedzivo/features/auth/repositories/auth_repository.dart';
import 'package:piedzivo/features/auth/widgets/auth_bottom_sheet.dart';
import 'package:piedzivo/features/events/bloc/events_bloc.dart';
import 'package:piedzivo/features/events/models/event_list_item.dart';
import 'package:piedzivo/features/events/repositories/events_repository.dart';
import 'package:piedzivo/features/following/bloc/following_bloc.dart';
import 'package:piedzivo/features/following/bloc/following_event.dart';
import 'package:piedzivo/features/following/bloc/following_state.dart';
import 'package:piedzivo/features/following/models/followed_place_item.dart';
import 'package:piedzivo/features/following/repositories/following_repository.dart';
import 'package:piedzivo/features/following/widgets/followed_place_card.dart';
import 'package:piedzivo/features/geo/cubit/geo_cubit.dart';
import 'package:piedzivo/features/geo/models/geo_place.dart';
import 'package:piedzivo/features/geo/repositories/geo_repository.dart';
import 'package:piedzivo/features/places/bloc/places_bloc.dart';
import 'package:piedzivo/features/places/models/place_list_item.dart';
import 'package:piedzivo/features/places/repositories/places_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../unit/api_client_test.dart';

void main() {
  group('Uzdevums 12: FollowingScreen Widget Tests', () {
    late FakeSecureStorage fakeStorage;
    late MockAdapter mockAdapter;
    late Dio dio;
    late ApiClient apiClient;
    late AuthRepository authRepository;
    late AuthBloc authBloc;
    late FollowingRepository followingRepository;
    late FollowingBloc followingBloc;
    late EventsRepository eventsRepository;
    late EventsBloc eventsBloc;
    late PlacesRepository placesRepository;
    late PlacesBloc placesBloc;
    late GeoRepository geoRepository;
    late GeoCubit geoCubit;

    const dummyUser = User(id: 'usr-1', email: 'janis@example.com', name: 'Jānis');

    const dummyPlace = PlaceListItem(
      id: 'pl-1',
      slug: 'cesu-koncertzale',
      title: 'Cēsu Koncertzāle',
      city: 'Cēsis',
      editorialPriority: 10,
      recommendationsCount: 15,
      upcomingEventsCount: 2,
      imagesCount: 1,
      isNew: false,
      isRecommendedByMe: false,
      isFollowedByMe: true,
      isOpen: true,
      openingLabel: 'Atvērts',
    );

    const dummyEvent = EventListItem(
      id: 'ev-1',
      slug: 'rudens-kamermuzika',
      title: 'Rudens kamermūzika',
      editorialPriority: 5,
      recommendationsCount: 8,
      isNew: false,
      isRecommendedByMe: false,
      isFollowedByMe: true,
      priceLabel: '15 €',
      isFree: false,
      startsOn: '2026-11-05',
      startsAt: '19:00:00',
      placeId: 'pl-1',
      placeTitle: 'Cēsu Koncertzāle',
      placeCity: 'Cēsis',
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
      dio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
      dio.httpClientAdapter = mockAdapter;
      apiClient = ApiClient(secureStorage: fakeStorage, dioClient: dio);

      mockAdapter.handler = (options) {
        if (options.path.contains('/me/events')) {
          return ResponseBody.fromString(
            jsonEncode({'data': []}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('/me/places')) {
          return ResponseBody.fromString(
            jsonEncode({'data': []}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString(jsonEncode({'status': 'ok'}), 200);
      };

      authRepository = AuthRepository(apiClient: apiClient);
      authBloc = AuthBloc(
        authRepository: authRepository,
        initialState: const AuthState(status: AuthStatus.unauthenticated),
      );

      followingRepository = FollowingRepository(apiClient: apiClient);
      followingBloc = FollowingBloc(repository: followingRepository);

      eventsRepository = EventsRepository(apiClient: apiClient);
      eventsBloc = EventsBloc(repository: eventsRepository);

      placesRepository = PlacesRepository(apiClient: apiClient);
      placesBloc = PlacesBloc(repository: placesRepository);

      geoRepository = GeoRepository(apiClient: apiClient);
      geoCubit = GeoCubit(geoRepository: geoRepository);
      await geoCubit.loadPlaces(serverChecksum: 'chk1');
    });

    tearDown(() {
      authBloc.close();
      followingBloc.close();
      eventsBloc.close();
      placesBloc.close();
      geoCubit.close();
    });

    Widget createTestApp({required AuthBloc authBloc, required FollowingBloc followingBloc}) {
      return PiedzivoApp(
        apiClient: apiClient,
        geoCubit: geoCubit,
        eventsBloc: eventsBloc,
        eventsRepository: eventsRepository,
        placesBloc: placesBloc,
        placesRepository: placesRepository,
        authBloc: authBloc,
        authRepository: authRepository,
        followingBloc: followingBloc,
        followingRepository: followingRepository,
        startWithRouter: true,
      );
    }

    testWidgets('Unauthenticated user sees CTA banner and can open AuthBottomSheet', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(authBloc: authBloc, followingBloc: followingBloc));
      await tester.pumpAndSettle();

      // Navigē uz 2. cilni (Sekotie)
      await tester.tap(find.byKey(const Key('bottom_nav_item_2')));
      await tester.pumpAndSettle();

      // Pārbaudām CTA saturu
      expect(find.text('Tavi sekotie notikumi un vietas'), findsOneWidget);
      expect(find.text('Pieslēdzies savam profilam, lai sekotu līdzi sev interesējošo vietu un pasākumu jaunumiem vienuviet.'), findsOneWidget);
      expect(find.byKey(const Key('following_login_button')), findsOneWidget);

      // Nospiežam pogu "Ienākt profilā" -> jāatveras AuthBottomSheet
      await tester.tap(find.byKey(const Key('following_login_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AuthBottomSheet), findsOneWidget);
      expect(find.byKey(const Key('auth_google_button')), findsOneWidget);
      expect(find.byKey(const Key('auth_send_otp_button')), findsOneWidget);
    });

    testWidgets('Authenticated user sees subtabs and empty states for events and places', (
      WidgetTester tester,
    ) async {
      final authBlocAuthenticated = AuthBloc(
        authRepository: authRepository,
        initialState: const AuthState(status: AuthStatus.authenticated, user: dummyUser),
      );

      final followingBlocEmpty = FollowingBloc(
        repository: followingRepository,
        initialState: const FollowingState(
          status: FollowingStatus.success,
          selectedTab: FollowingTab.events,
          events: [],
          places: [],
        ),
      );

      await tester.pumpWidget(
        createTestApp(authBloc: authBlocAuthenticated, followingBloc: followingBlocEmpty),
      );
      await tester.pumpAndSettle();

      // Pārslēdzamies uz Sekotajiem
      await tester.tap(find.byKey(const Key('bottom_nav_item_2')));
      await tester.pumpAndSettle();

      // Pārbaudām subtabs
      expect(find.byKey(const Key('following_tab_events')), findsOneWidget);
      expect(find.byKey(const Key('following_tab_places')), findsOneWidget);

      // Mani Pasākumi tukšais stāvoklis
      expect(find.text('Nav sekotu pasākumu'), findsOneWidget);
      expect(find.byKey(const Key('following_browse_events_button')), findsOneWidget);

      // Pārslēdzamies uz "Manas Vietas"
      await tester.tap(find.byKey(const Key('following_tab_places')));
      await tester.pumpAndSettle();

      expect(followingBlocEmpty.state.selectedTab, FollowingTab.places);
      expect(find.text('Nav sekotu vietu'), findsOneWidget);
      expect(find.byKey(const Key('following_browse_places_button')), findsOneWidget);

      authBlocAuthenticated.close();
      followingBlocEmpty.close();
    });

    testWidgets('Displays followed events grouped by day and followed places with unread badge', (
      WidgetTester tester,
    ) async {
      final authBlocAuthenticated = AuthBloc(
        authRepository: authRepository,
        initialState: const AuthState(status: AuthStatus.authenticated, user: dummyUser),
      );

      const followedPlaceItem = FollowedPlaceItem(
        place: dummyPlace,
        unreadEventsCount: 3,
      );

      final followingBlocWithData = FollowingBloc(
        repository: followingRepository,
        initialState: const FollowingState(
          status: FollowingStatus.success,
          selectedTab: FollowingTab.events,
          events: [dummyEvent],
          places: [followedPlaceItem],
        ),
      );

      await tester.pumpWidget(
        createTestApp(authBloc: authBlocAuthenticated, followingBloc: followingBlocWithData),
      );
      await tester.pumpAndSettle();

      // Pārslēdzamies uz Sekotajiem
      await tester.tap(find.byKey(const Key('bottom_nav_item_2')));
      await tester.pumpAndSettle();

      // Pārbaudām pasākumu sarakstu
      expect(find.text('Rudens kamermūzika'), findsOneWidget);
      expect(find.text('🎟️ 15 €'), findsOneWidget);

      // Pārbaudām, ka uz apakšcilnes "Manas Vietas" redzams sarkans jaunumu skaitītājs '1'
      expect(find.text('1'), findsWidgets);

      // Pārslēdzamies uz cilni "Manas Vietas"
      await tester.tap(find.byKey(const Key('following_tab_places')));
      await tester.pumpAndSettle();

      // Pārbaudām vietas kartīti un sarkano birku
      expect(find.byType(FollowedPlaceCard), findsOneWidget);
      expect(find.text('Cēsu Koncertzāle'), findsOneWidget);
      expect(find.byKey(const Key('unread_badge_pl-1')), findsOneWidget);
      expect(find.text('🔴 +3 jauni!'), findsOneWidget);

      // Nospiežot uz vietas kartītes, birka tiek nodzēsta
      await tester.tap(find.byType(FollowedPlaceCard));
      await tester.pumpAndSettle();

      // Birka vairs neparādās, jo FollowingPlaceMarkViewed atiestatīja skaitītāju uz 0
      expect(followingBlocWithData.state.places.first.unreadEventsCount, 0);

      authBlocAuthenticated.close();
      followingBlocWithData.close();
    });
  });
}
