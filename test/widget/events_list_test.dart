import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piedzivo/app.dart';
import 'package:piedzivo/core/theme/app_theme.dart';
import 'package:piedzivo/core/navigation/app_router.dart';
import 'package:piedzivo/core/network/api_client.dart';
import 'package:piedzivo/features/auth/bloc/auth_bloc.dart';
import 'package:piedzivo/features/auth/bloc/auth_state.dart';
import 'package:piedzivo/features/auth/models/user.dart';
import 'package:piedzivo/features/auth/repositories/auth_repository.dart';
import 'package:piedzivo/features/events/bloc/events_bloc.dart';
import 'package:piedzivo/features/events/bloc/events_state.dart';
import 'package:piedzivo/features/events/models/event_list_item.dart';
import 'package:piedzivo/features/events/repositories/events_repository.dart';
import 'package:piedzivo/features/events/widgets/event_card.dart';
import 'package:piedzivo/features/geo/cubit/geo_cubit.dart';
import 'package:piedzivo/features/geo/models/geo_place.dart';
import 'package:piedzivo/features/geo/repositories/geo_repository.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../unit/api_client_test.dart';

void main() {
  group('Uzdevums 5: EventsListScreen & EventCard UI tests', () {
    late FakeSecureStorage fakeStorage;
    late MockAdapter mockAdapter;
    late ApiClient apiClient;
    late EventsRepository eventsRepo;
    late EventsBloc eventsBloc;
    late GeoRepository geoRepo;
    late GeoCubit geoCubit;
    late AuthRepository authRepo;
    late AuthBloc authBloc;

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final tomorrowStr = DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 1)));

    late final mockEvent1 = EventListItem(
      id: 'evt-1',
      slug: 'koncerts-cesis',
      title: 'Akustiskais koncerts pilī',
      editorialPriority: 10,
      recommendationsCount: 15,
      isNew: true,
      isRecommendedByMe: false,
      isFollowedByMe: false,
      primaryTaxonomyName: 'Koncerts',
      priceLabel: 'no 12 €',
      isFree: false,
      startsOn: todayStr,
      startsAt: '19:00:00',
      placeTitle: 'Cēsu viduslaiku pils',
      placeCity: 'Cēsis',
    );

    late final mockEvent2 = EventListItem(
      id: 'evt-2',
      slug: 'izstade-cesis',
      title: 'Keramikas meistarklase',
      editorialPriority: 0,
      recommendationsCount: 8,
      isNew: false,
      isRecommendedByMe: true,
      isFollowedByMe: true,
      primaryTaxonomyName: 'Izstāde',
      priceLabel: 'Bezmaksas',
      isFree: true,
      startsOn: tomorrowStr,
      startsAt: '14:00:00',
      placeTitle: 'Cēsu Izstāžu nams',
      placeCity: 'Cēsis',
    );

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
        if (options.path.contains('/events') && !options.path.contains('/recommend')) {
          return ResponseBody.fromString(
            jsonEncode({
              'data': [mockEvent1.toJson(), mockEvent2.toJson()],
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        } else if (options.path.contains('/recommend')) {
          return ResponseBody.fromString(jsonEncode({'status': 'ok'}), 200);
        }
        return ResponseBody.fromString(jsonEncode({'status': 'ok'}), 200);
      };

      final dio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
      dio.httpClientAdapter = mockAdapter;

      apiClient = ApiClient(secureStorage: fakeStorage, dioClient: dio);
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

    testWidgets('renders EventCard elements (title, badges, place, time) and day headers', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        PiedzivoApp(
          apiClient: apiClient,
          authBloc: authBloc,
          geoCubit: geoCubit,
          eventsBloc: eventsBloc,
          eventsRepository: eventsRepo,
          router: createAppRouter(navigatorKey: GlobalKey<NavigatorState>()),
          startWithRouter: true,
        ),
      );
      await tester.runAsync(() async {
        if (eventsBloc.state is! EventsLoaded) {
          await eventsBloc.stream.firstWhere((s) => s is EventsLoaded);
        }
      });
      await tester.pumpAndSettle();

      // Pārbaudām dienas virsrakstus
      expect(find.textContaining('ŠODIEN'), findsOneWidget);
      expect(find.textContaining('RĪT'), findsOneWidget);

      // Pārbaudām 1. pasākuma datus
      expect(find.text('Akustiskais koncerts pilī'), findsOneWidget);
      expect(find.text('19:00 • Koncerts'), findsOneWidget);
      expect(find.text('Cēsu viduslaiku pils, Cēsis'), findsOneWidget);
      expect(find.text('🎟️ no 12 €'), findsOneWidget);
      expect(find.text('⭐ Piedzīvo'), findsOneWidget);
      expect(find.text('✨ JAUNS'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);

      // Pārbaudām 2. pasākuma datus
      expect(find.text('Keramikas meistarklase'), findsOneWidget);
      expect(
        find.descendant(of: find.byType(EventCard), matching: find.text('🎟️ Bezmaksas')),
        findsOneWidget,
      );

      // Taps uz '🎟️ Bezmaksas' filtra čipa
      await tester.tap(find.byKey(const Key('filter_chip_free')));
      await tester.runAsync(() async {
        final st = eventsBloc.state;
        if (st is! EventsLoaded || !st.isFreeOnly) {
          await eventsBloc.stream.firstWhere((s) => s is EventsLoaded && s.isFreeOnly);
        }
      });
      await tester.pumpAndSettle();

      // Tikai bezmaksas pasākums ir redzams
      expect(find.text('Keramikas meistarklase'), findsOneWidget);
      expect(find.text('Akustiskais koncerts pilī'), findsNothing);
    });

    testWidgets('Tapping recommend button increments counter optimistically', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        PiedzivoApp(
          apiClient: apiClient,
          authBloc: authBloc,
          geoCubit: geoCubit,
          eventsBloc: eventsBloc,
          eventsRepository: eventsRepo,
          router: createAppRouter(navigatorKey: GlobalKey<NavigatorState>()),
          startWithRouter: true,
        ),
      );
      await tester.runAsync(() async {
        if (eventsBloc.state is! EventsLoaded) {
          await eventsBloc.stream.firstWhere((s) => s is EventsLoaded);
        }
      });
      await tester.pumpAndSettle();

      expect(find.text('15'), findsOneWidget);

      // Nospiežam 'Iesaku' pogu 1. pasākumam
      await tester.tap(find.byKey(const Key('recommend_button_evt-1')));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(find.text('16'), findsOneWidget);
    });
  });
}
