import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piedzivo/core/network/api_client.dart';
import 'package:piedzivo/features/following/bloc/following_bloc.dart';
import 'package:piedzivo/features/following/bloc/following_event.dart';
import 'package:piedzivo/features/following/bloc/following_state.dart';
import 'package:piedzivo/features/following/models/followed_place_item.dart';
import 'package:piedzivo/features/following/repositories/following_repository.dart';
import 'api_client_test.dart';

void main() {
  group('Uzdevums 12: FollowingBloc and FollowingRepository', () {
    late FakeSecureStorage fakeStorage;
    late MockAdapter mockAdapter;
    late Dio dio;
    late ApiClient apiClient;
    late FollowingRepository repository;
    late FollowingBloc bloc;

    final dummyEvent1 = {
      'id': 'ev-1',
      'title': 'Rītdienas koncerts',
      'slug': 'ritdienas-koncerts',
      'editorial_priority': 1,
      'recommendations_count': 5,
      'is_new': false,
      'price_badge': {'type': 'paid', 'label': '10 €'},
      'next_occurrence': {'starts_on': '2026-11-02', 'starts_at': '19:00:00'},
      'place': {'id': 'pl-1', 'title': 'Cēsu Koncertzāle', 'city': 'Cēsis'},
    };

    final dummyEvent2 = {
      'id': 'ev-2',
      'title': 'Šodienas teātris',
      'slug': 'sodienas-teatris',
      'editorial_priority': 2,
      'recommendations_count': 12,
      'is_new': true,
      'price_badge': {'type': 'free', 'label': 'Bezmaksas'},
      'next_occurrence': {'starts_on': '2026-11-01', 'starts_at': '18:00:00'},
      'place': {'id': 'pl-2', 'title': 'Valmieras Drāmas teātris', 'city': 'Valmiera'},
    };

    final dummyPlace1 = {
      'id': 'pl-1',
      'title': 'Cēsu Koncertzāle',
      'slug': 'cesu-koncertzale',
      'city': 'Cēsis',
      'editorial_priority': 10,
      'recommendations_count': 15,
      'upcoming_events_count': 3,
      'is_new': false,
      'is_open': true,
      'opening_label': 'Atvērts līdz 22:00',
      'unread_events_count': 2,
    };

    final dummyPlace2 = {
      'id': 'pl-2',
      'title': 'Valmieras Teātris',
      'slug': 'valmieras-teatris',
      'city': 'Valmiera',
      'editorial_priority': 5,
      'recommendations_count': 8,
      'upcoming_events_count': 1,
      'is_new': false,
      'is_open': false,
      'opening_label': 'Slēgts',
      'unread_events_count': 0,
    };

    setUp(() {
      fakeStorage = FakeSecureStorage();
      mockAdapter = MockAdapter();
      dio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
      dio.httpClientAdapter = mockAdapter;
      apiClient = ApiClient(secureStorage: fakeStorage, dioClient: dio);
      repository = FollowingRepository(apiClient: apiClient);
      bloc = FollowingBloc(repository: repository);
    });

    tearDown(() {
      bloc.close();
    });

    test('Initial state has default values', () {
      expect(bloc.state.status, FollowingStatus.initial);
      expect(bloc.state.selectedTab, FollowingTab.events);
      expect(bloc.state.events, isEmpty);
      expect(bloc.state.places, isEmpty);
      expect(bloc.state.totalUnreadPlacesCount, 0);
      expect(bloc.state.totalUnreadEventsCount, 0);
    });

    test('FollowingLoadRequested loads and sorts events chronologically', () async {
      mockAdapter.handler = (options) {
        if (options.path.contains('/me/events')) {
          return ResponseBody.fromString(
            jsonEncode({'data': [dummyEvent1, dummyEvent2]}), // event1 is Nov 02, event2 is Nov 01
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('/me/places')) {
          return ResponseBody.fromString(
            jsonEncode({'data': [dummyPlace1, dummyPlace2]}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString(jsonEncode({'status': 'ok'}), 200);
      };

      bloc.add(const FollowingLoadRequested());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const FollowingState(status: FollowingStatus.loading),
          predicate<FollowingState>((state) {
            return state.status == FollowingStatus.success &&
                state.events.length == 2 &&
                state.places.length == 2 &&
                // Chronological check: dummyEvent2 (Nov 01) must come before dummyEvent1 (Nov 02)
                state.events.first.id == 'ev-2' &&
                state.events.last.id == 'ev-1' &&
                state.totalUnreadPlacesCount == 1 &&
                state.totalUnreadEventsCount == 2;
          }),
        ]),
      );
    });

    test('FollowingTabChanged updates selected tab', () async {
      expect(bloc.state.selectedTab, FollowingTab.events);

      bloc.add(const FollowingTabChanged(FollowingTab.places));
      await expectLater(
        bloc.stream,
        emits(predicate<FollowingState>((s) => s.selectedTab == FollowingTab.places)),
      );

      bloc.add(const FollowingTabChanged(FollowingTab.events));
      await expectLater(
        bloc.stream,
        emits(predicate<FollowingState>((s) => s.selectedTab == FollowingTab.events)),
      );
    });

    test('FollowingPlaceMarkViewed clears unread count for place immediately and calls repository', () async {
      final completer = Completer<void>();
      mockAdapter.handler = (options) {
        if (options.path.contains('viewed') || options.uri.toString().contains('viewed')) {
          if (!completer.isCompleted) completer.complete();
          return ResponseBody.fromString(jsonEncode({'success': true}), 200);
        }
        return ResponseBody.fromString(jsonEncode({'status': 'ok'}), 200);
      };

      final initialPlaceItem = FollowedPlaceItem.fromJson(dummyPlace1);
      expect(initialPlaceItem.unreadEventsCount, 2);
      expect(initialPlaceItem.hasUnread, isTrue);

      final blocWithData = FollowingBloc(
        repository: repository,
        initialState: FollowingState(
          status: FollowingStatus.success,
          places: [initialPlaceItem],
        ),
      );

      expect(blocWithData.state.totalUnreadPlacesCount, 1);
      expect(blocWithData.state.totalUnreadEventsCount, 2);

      blocWithData.add(const FollowingPlaceMarkViewed('pl-1'));

      await expectLater(
        blocWithData.stream,
        emits(predicate<FollowingState>((s) {
          final p = s.places.firstWhere((item) => item.place.id == 'pl-1');
          return p.unreadEventsCount == 0 &&
              !p.hasUnread &&
              s.totalUnreadPlacesCount == 0 &&
              s.totalUnreadEventsCount == 0;
        })),
      );

      await completer.future.timeout(const Duration(seconds: 2));
      expect(completer.isCompleted, isTrue);
      blocWithData.close();
    });

    test('FollowingLoadRequested handles failure gracefully', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString('Internal Server Error', 500);
      };

      bloc.add(const FollowingLoadRequested());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const FollowingState(status: FollowingStatus.loading),
          predicate<FollowingState>((state) {
            // Repositories return empty list on network error, so state is success with empty lists
            return state.status == FollowingStatus.success &&
                state.events.isEmpty &&
                state.places.isEmpty;
          }),
        ]),
      );
    });

    test('FollowingRefreshRequested silently refreshes list without resetting status to loading', () async {
      mockAdapter.handler = (options) {
        if (options.path.contains('/me/events')) {
          return ResponseBody.fromString(
            jsonEncode({'data': [dummyEvent2]}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('/me/places')) {
          return ResponseBody.fromString(
            jsonEncode({'data': [dummyPlace2]}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString(jsonEncode({'status': 'ok'}), 200);
      };

      bloc.add(const FollowingRefreshRequested());

      await expectLater(
        bloc.stream,
        emits(predicate<FollowingState>((s) {
          return s.status == FollowingStatus.success &&
              s.events.length == 1 &&
              s.places.length == 1;
        })),
      );
    });
  });
}
