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
import 'package:piedzivo/features/events/models/event_detail.dart';
import 'package:piedzivo/features/events/repositories/events_repository.dart';
import 'package:piedzivo/features/events/screens/event_detail_screen.dart';
import 'package:piedzivo/features/feedback/models/feedback_submission.dart';
import 'package:piedzivo/features/feedback/repositories/feedback_repository.dart';
import 'package:piedzivo/features/feedback/widgets/feedback_bottom_sheet.dart';
import 'package:piedzivo/features/places/models/place_detail.dart';
import 'package:piedzivo/features/places/repositories/places_repository.dart';
import 'package:piedzivo/features/places/screens/place_detail_screen.dart';
import '../unit/api_client_test.dart';

void main() {
  group('Uzdevums 13: FeedbackBottomSheet Widget Tests', () {
    late FakeSecureStorage fakeStorage;
    late MockAdapter mockAdapter;
    late Dio dio;
    late ApiClient apiClient;
    late AuthRepository authRepository;
    late AuthBloc authBloc;
    late FeedbackRepository feedbackRepository;
    late EventsRepository eventsRepository;
    late PlacesRepository placesRepository;

    const dummyUser = User(id: 'usr-1', email: 'janis@example.com', name: 'Jānis');

    const dummyEvent = EventDetail(
      id: 'ev-1',
      slug: 'rudens-kamermuzika',
      title: 'Rudens kamermūzika',
      editorialPriority: 5,
      recommendationsCount: 8,
      isNew: false,
      isRecommendedByMe: false,
      isFollowedByMe: false,
      priceLabel: '15 €',
      isFree: false,
      startsOn: '2026-11-05',
      startsAt: '19:00:00',
      description: 'Lielisks kamermūzikas vakars.',
    );

    const dummyPlace = PlaceDetail(
      id: 'pl-1',
      slug: 'cesu-koncertzale',
      title: 'Cēsu Koncertzāle',
      city: 'Cēsis',
      editorialPriority: 10,
      recommendationsCount: 15,
      upcomingEventsCount: 0,
      isNew: false,
      isRecommendedByMe: false,
      isFollowedByMe: false,
      isOpen: true,
      openingLabel: 'Atvērts',
      description: 'Reģionālā koncertzāle.',
      weeklySchedule: [],
      images: [],
      upcomingEvents: [],
    );

    setUp(() {
      AppTheme.isTestMode = true;
      fakeStorage = FakeSecureStorage();
      mockAdapter = MockAdapter();
      dio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
      dio.httpClientAdapter = mockAdapter;
      apiClient = ApiClient(secureStorage: fakeStorage, dioClient: dio);

      mockAdapter.handler = (options) {
        if (options.path.contains('/feedback')) {
          return ResponseBody.fromString(
            jsonEncode({'status': 'success', 'message': 'Paldies!'}),
            201,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString(jsonEncode({'status': 'ok'}), 200);
      };

      authRepository = AuthRepository(apiClient: apiClient);
      authBloc = AuthBloc(
        authRepository: authRepository,
        initialState: const AuthState(status: AuthStatus.authenticated, user: dummyUser),
      );

      feedbackRepository = FeedbackRepository(apiClient: apiClient);
      eventsRepository = EventsRepository(apiClient: apiClient);
      placesRepository = PlacesRepository(apiClient: apiClient);
    });

    tearDown(() {
      authBloc.close();
    });

    Widget createTestApp(Widget child) {
      return MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: feedbackRepository),
          RepositoryProvider.value(value: authRepository),
          RepositoryProvider.value(value: eventsRepository),
          RepositoryProvider.value(value: placesRepository),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: authBloc),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(body: child),
          ),
        ),
      );
    }

    testWidgets('Opens FeedbackBottomSheet, selects category, types message and submits successfully', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          Builder(
            builder: (context) {
              return ElevatedButton(
                key: const Key('open_feedback_button'),
                onPressed: () => showFeedbackBottomSheet(
                  context,
                  contextType: FeedbackContextType.event,
                  contextId: 'ev-1',
                  contextTitle: 'Rudens kamermūzika',
                ),
                child: const Text('Open'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open bottom sheet
      await tester.tap(find.byKey(const Key('open_feedback_button')));
      await tester.pumpAndSettle();

      // Verify header and context title
      expect(find.text('Ziņot par kļūdu vai labojumu'), findsOneWidget);
      expect(find.text('Pasākums: Rudens kamermūzika'), findsOneWidget);

      // Verify category choices are visible
      expect(find.byKey(const Key('feedback_category_content_issue')), findsOneWidget);
      expect(find.byKey(const Key('feedback_category_bug')), findsOneWidget);
      expect(find.byKey(const Key('feedback_category_suggestion')), findsOneWidget);

      // Select 'Darbības kļūda lietotnē'
      await tester.tap(find.byKey(const Key('feedback_category_bug')));
      await tester.pumpAndSettle();

      // Enter message
      await tester.enterText(
        find.byKey(const Key('feedback_message_input')),
        'Nestrādā biļešu pirkšanas poga',
      );
      await tester.pumpAndSettle();

      // Submit feedback
      await tester.ensureVisible(find.byKey(const Key('feedback_submit_button')));
      await tester.tap(find.byKey(const Key('feedback_submit_button')));
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify success view is displayed
      expect(find.byKey(const Key('feedback_success_view')), findsOneWidget);
      expect(find.text('Paldies par Tavu ziņojumu!'), findsOneWidget);

      // Close success view
      await tester.tap(find.byKey(const Key('feedback_success_close_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('feedback_success_view')), findsNothing);
    });

    testWidgets('EventDetailScreen feedback button opens bottom sheet with event context', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          const EventDetailScreen(
            eventId: 'ev-1',
            initialDetail: dummyEvent,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down to find the feedback button
      final feedbackButtonFinder = find.byKey(const Key('event_feedback_button'));
      await tester.scrollUntilVisible(feedbackButtonFinder, 300);
      expect(feedbackButtonFinder, findsOneWidget);

      await tester.tap(feedbackButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Pasākums: Rudens kamermūzika'), findsOneWidget);
      expect(find.byKey(const Key('feedback_message_input')), findsOneWidget);

      // Dismiss with close button
      await tester.tap(find.byKey(const Key('feedback_close_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('feedback_message_input')), findsNothing);
    });

    testWidgets('PlaceDetailScreen feedback button opens bottom sheet with place context', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          const PlaceDetailScreen(
            placeId: 'pl-1',
            initialDetail: dummyPlace,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down to find the feedback button
      final feedbackButtonFinder = find.byKey(const Key('place_feedback_button'));
      await tester.scrollUntilVisible(feedbackButtonFinder, 400);
      expect(feedbackButtonFinder, findsOneWidget);

      await tester.tap(feedbackButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Vieta: Cēsu Koncertzāle'), findsOneWidget);
      expect(find.byKey(const Key('feedback_message_input')), findsOneWidget);

      // Dismiss
      await tester.tap(find.byKey(const Key('feedback_close_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('feedback_message_input')), findsNothing);
    });
  });
}
