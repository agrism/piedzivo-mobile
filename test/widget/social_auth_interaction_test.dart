import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:piedzivo/features/events/widgets/event_card.dart';
import 'package:piedzivo/features/places/bloc/places_bloc.dart';
import 'package:piedzivo/features/places/models/place_list_item.dart';
import 'package:piedzivo/features/places/repositories/places_repository.dart';
import 'package:piedzivo/features/places/widgets/place_card.dart';
import '../unit/api_client_test.dart';

void main() {
  group('Uzdevums 11: Social Auth Interaction Tests', () {
    late FakeSecureStorage fakeStorage;
    late MockAdapter mockAdapter;
    late ApiClient apiClient;
    late AuthRepository authRepo;
    late EventsRepository eventsRepo;
    late EventsBloc eventsBloc;
    late PlacesRepository placesRepo;
    late PlacesBloc placesBloc;

    const mockEvent = EventListItem(
      id: 'evt-test-1',
      slug: 'koncerts',
      title: 'Džeza vakars',
      editorialPriority: 5,
      recommendationsCount: 10,
      isNew: false,
      isRecommendedByMe: false,
      isFollowedByMe: false,
      primaryTaxonomyName: 'Mūzika',
      priceLabel: 'Bezmaksas',
      isFree: true,
      startsOn: '2026-11-01',
      startsAt: '19:00:00',
      placeTitle: 'Kultūras nams',
      placeCity: 'Cēsis',
    );

    const mockPlace = PlaceListItem(
      id: 'plc-test-1',
      slug: 'cesu-pils',
      title: 'Cēsu Viduslaiku Pils',
      city: 'Cēsis',
      primaryImageUrl: null,
      imagesCount: 3,
      editorialPriority: 10,
      recommendationsCount: 25,
      upcomingEventsCount: 2,
      isNew: false,
      isRecommendedByMe: false,
      isFollowedByMe: false,
      isOpen: true,
      openingLabel: 'Līdz 18:00',
    );

    const testUser = User(
      id: 'usr-42',
      email: 'test@piedzivo.lv',
      name: 'Testa Lietotājs',
    );

    setUp(() {
      AppTheme.isTestMode = true;
      fakeStorage = FakeSecureStorage();
      mockAdapter = MockAdapter();

      mockAdapter.handler = (options) {
        if (options.path.contains('/recommend') || options.path.contains('/follow')) {
          return ResponseBody.fromString(jsonEncode({'status': 'ok'}), 200);
        }
        return ResponseBody.fromString(jsonEncode({'status': 'ok'}), 200);
      };

      final dio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
      dio.httpClientAdapter = mockAdapter;

      apiClient = ApiClient(secureStorage: fakeStorage, dioClient: dio);
      authRepo = AuthRepository(apiClient: apiClient);
      eventsRepo = EventsRepository(apiClient: apiClient);
      eventsBloc = EventsBloc(repository: eventsRepo);
      placesRepo = PlacesRepository(apiClient: apiClient);
      placesBloc = PlacesBloc(repository: placesRepo);
    });

    tearDown(() {
      eventsBloc.close();
      placesBloc.close();
    });

    testWidgets('Unauthenticated user clicking Iesaku on EventCard opens AuthBottomSheet', (
      WidgetTester tester,
    ) async {
      final unauthedBloc = AuthBloc(
        authRepository: authRepo,
        initialState: const AuthState(status: AuthStatus.unauthenticated),
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: unauthedBloc),
            BlocProvider<EventsBloc>.value(value: eventsBloc),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: EventCard(event: mockEvent),
            ),
          ),
        ),
      );

      // Tap recommend button
      await tester.tap(find.byKey(const Key('recommend_button_evt-test-1')));
      await tester.pumpAndSettle();

      // AuthBottomSheet opens
      expect(find.byType(AuthBottomSheet), findsOneWidget);
      expect(find.text('Pieslēgties vai reģistrēties'), findsOneWidget);

      unauthedBloc.close();
    });

    testWidgets('Unauthenticated user clicking Sekot on EventCard opens AuthBottomSheet', (
      WidgetTester tester,
    ) async {
      final unauthedBloc = AuthBloc(
        authRepository: authRepo,
        initialState: const AuthState(status: AuthStatus.unauthenticated),
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: unauthedBloc),
            BlocProvider<EventsBloc>.value(value: eventsBloc),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: EventCard(event: mockEvent),
            ),
          ),
        ),
      );

      // Tap follow button
      await tester.tap(find.byKey(const Key('follow_button_evt-test-1')));
      await tester.pumpAndSettle();

      // AuthBottomSheet opens
      expect(find.byType(AuthBottomSheet), findsOneWidget);

      unauthedBloc.close();
    });

    testWidgets('Unauthenticated user clicking Iesaku on PlaceCard opens AuthBottomSheet', (
      WidgetTester tester,
    ) async {
      final unauthedBloc = AuthBloc(
        authRepository: authRepo,
        initialState: const AuthState(status: AuthStatus.unauthenticated),
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: unauthedBloc),
            BlocProvider<PlacesBloc>.value(value: placesBloc),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: PlaceCard(place: mockPlace),
            ),
          ),
        ),
      );

      // Tap recommend button
      await tester.tap(find.byKey(const Key('place_recommend_plc-test-1')));
      await tester.pumpAndSettle();

      // AuthBottomSheet opens
      expect(find.byType(AuthBottomSheet), findsOneWidget);

      unauthedBloc.close();
    });

    testWidgets('Unauthenticated user clicking Sekot on PlaceCard opens AuthBottomSheet', (
      WidgetTester tester,
    ) async {
      final unauthedBloc = AuthBloc(
        authRepository: authRepo,
        initialState: const AuthState(status: AuthStatus.unauthenticated),
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: unauthedBloc),
            BlocProvider<PlacesBloc>.value(value: placesBloc),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: PlaceCard(place: mockPlace),
            ),
          ),
        ),
      );

      // Tap follow button
      await tester.tap(find.byKey(const Key('place_follow_plc-test-1')));
      await tester.pumpAndSettle();

      // AuthBottomSheet opens
      expect(find.byType(AuthBottomSheet), findsOneWidget);

      unauthedBloc.close();
    });

    testWidgets('Authenticated user clicking Iesaku on EventCard toggles immediately without bottom sheet', (
      WidgetTester tester,
    ) async {
      final authedBloc = AuthBloc(
        authRepository: authRepo,
        initialState: const AuthState(status: AuthStatus.authenticated, user: testUser),
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authedBloc),
            BlocProvider<EventsBloc>.value(value: eventsBloc),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: EventCard(event: mockEvent),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('recommend_button_evt-test-1')));
      await tester.pump();

      // No bottom sheet
      expect(find.byType(AuthBottomSheet), findsNothing);

      authedBloc.close();
    });

    testWidgets('Authenticated user clicking Iesaku on PlaceCard toggles immediately without bottom sheet', (
      WidgetTester tester,
    ) async {
      final authedBloc = AuthBloc(
        authRepository: authRepo,
        initialState: const AuthState(status: AuthStatus.authenticated, user: testUser),
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authedBloc),
            BlocProvider<PlacesBloc>.value(value: placesBloc),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: PlaceCard(place: mockPlace),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('place_recommend_plc-test-1')));
      await tester.pump();

      // No bottom sheet
      expect(find.byType(AuthBottomSheet), findsNothing);

      authedBloc.close();
    });
  });
}
