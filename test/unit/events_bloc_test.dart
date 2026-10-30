import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piedzivo/core/network/api_client.dart';
import 'package:piedzivo/features/events/bloc/events_bloc.dart';
import 'package:piedzivo/features/events/bloc/events_event.dart';
import 'package:piedzivo/features/events/bloc/events_state.dart';
import 'package:piedzivo/features/events/models/event_list_item.dart';
import 'package:piedzivo/features/events/repositories/events_repository.dart';
import 'api_client_test.dart';

void main() {
  group('EventsBloc', () {
    late FakeSecureStorage fakeStorage;
    late MockAdapter mockAdapter;
    late ApiClient apiClient;
    late EventsRepository repository;

    const mockEvent1 = EventListItem(
      id: 'e1',
      slug: 'koncerts-1',
      title: 'Džeza vakars',
      editorialPriority: 5,
      recommendationsCount: 10,
      isNew: false,
      isRecommendedByMe: false,
      isFollowedByMe: false,
      primaryTaxonomyName: 'Koncerts',
      priceLabel: 'no 10 €',
      isFree: false,
      startsOn: '2026-10-30',
    );

    const mockEvent2 = EventListItem(
      id: 'e2',
      slug: 'izstade-2',
      title: 'Mākslas izstāde',
      editorialPriority: 0,
      recommendationsCount: 20,
      isNew: true,
      isRecommendedByMe: true,
      isFollowedByMe: false,
      primaryTaxonomyName: 'Izstāde',
      priceLabel: 'Bezmaksas',
      isFree: true,
      startsOn: '2026-10-31',
    );

    setUp(() {
      fakeStorage = FakeSecureStorage();
      mockAdapter = MockAdapter();

      final dio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
      dio.httpClientAdapter = mockAdapter;

      apiClient = ApiClient(secureStorage: fakeStorage, dioClient: dio);
      repository = EventsRepository(apiClient: apiClient);
    });

    test('LoadEvents fetches events and groups them by day', () async {
      mockAdapter.handler = (options) {
        expect(options.path, '/events');
        return ResponseBody.fromString(
          jsonEncode({
            'data': [mockEvent1.toJson(), mockEvent2.toJson()],
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final bloc = EventsBloc(repository: repository);
      bloc.add(const LoadEvents(placeId: 'city-cesis'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<EventsLoading>(),
          predicate<EventsLoaded>((state) {
            return state.allEvents.length == 2 &&
                state.filteredEvents.length == 2 &&
                state.currentPlaceId == 'city-cesis';
          }),
        ]),
      );
    });

    test('FilterEvents filters by category and isFreeOnly', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({
            'data': [mockEvent1.toJson(), mockEvent2.toJson()],
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final bloc = EventsBloc(repository: repository);
      bloc.add(const LoadEvents());

      await bloc.stream.firstWhere((s) => s is EventsLoaded);

      // Filtrējam tikai 'Koncerts'
      bloc.add(const FilterEvents(category: 'Koncerts'));
      var state = await bloc.stream.firstWhere((s) => s is EventsLoaded) as EventsLoaded;
      expect(state.filteredEvents.length, 1);
      expect(state.filteredEvents.first.title, 'Džeza vakars');

      // Filtrējam tikai bezmaksas
      bloc.add(const FilterEvents(isFreeOnly: true));
      state = await bloc.stream.firstWhere((s) => s is EventsLoaded) as EventsLoaded;
      expect(state.filteredEvents.length, 1);
      expect(state.filteredEvents.first.title, 'Mākslas izstāde');
    });

    test('ToggleRecommendEvent updates recommendation count optimistically', () async {
      mockAdapter.handler = (options) {
        if (options.path == '/events') {
          return ResponseBody.fromString(
            jsonEncode({'data': [mockEvent1.toJson()]}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        } else if (options.path == '/events/e1/recommend') {
          return ResponseBody.fromString(jsonEncode({'status': 'ok'}), 200);
        }
        throw Exception('Unexpected path: ${options.path}');
      };

      final bloc = EventsBloc(repository: repository);
      bloc.add(const LoadEvents());
      await bloc.stream.firstWhere((s) => s is EventsLoaded);

      bloc.add(const ToggleRecommendEvent('e1'));
      final state = await bloc.stream.firstWhere((s) => s is EventsLoaded) as EventsLoaded;

      final updated = state.filteredEvents.first;
      expect(updated.isRecommendedByMe, isTrue);
      expect(updated.recommendationsCount, 11);
    });
  });
}

