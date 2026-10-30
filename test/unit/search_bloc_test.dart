import 'package:flutter_test/flutter_test.dart';
import 'package:piedzivo/features/events/models/event_list_item.dart';
import 'package:piedzivo/features/events/repositories/events_repository.dart';
import 'package:piedzivo/features/places/models/place_list_item.dart';
import 'package:piedzivo/features/places/repositories/places_repository.dart';
import 'package:piedzivo/features/search/bloc/search_bloc.dart';
import 'package:piedzivo/features/search/bloc/search_event.dart';
import 'package:piedzivo/features/search/bloc/search_state.dart';

class FakeEventsRepository implements EventsRepository {
  List<EventListItem> eventsToReturn = [];
  String? lastSearch;
  String? lastPlaceId;
  bool shouldThrow = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<EventListItem>> getEvents({
    String? placeId,
    String? category,
    bool? isFree,
    String? date,
    String? search,
  }) async {
    if (shouldThrow) throw Exception('Server error');
    lastSearch = search;
    lastPlaceId = placeId;
    return eventsToReturn;
  }
}

class FakePlacesRepository implements PlacesRepository {
  List<PlaceListItem> placesToReturn = [];
  String? lastSearch;
  String? lastPlaceId;
  bool shouldThrow = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<PlaceListItem>> getPlaces({
    String? placeId,
    String? search,
    String? category,
    int? limit,
    int? offset,
  }) async {
    if (shouldThrow) throw Exception('Server error');
    lastSearch = search;
    lastPlaceId = placeId;
    return placesToReturn;
  }
}

void main() {
  group('SearchBloc Unit Tests', () {
    late FakeEventsRepository fakeEventsRepo;
    late FakePlacesRepository fakePlacesRepo;
    late SearchBloc searchBloc;

    const mockEvent = EventListItem(
      id: 'e1',
      slug: 'koncerts-cesu-pili',
      title: 'Koncerts Cēsu pilī',
      shortDescription: 'Lielisks akustiskais koncerts.',
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

    const mockPlace = PlaceListItem(
      id: 'p1',
      slug: 'cesu-pils',
      title: 'Cēsu viduslaiku pils',
      shortDescription: 'Vēsturisks simbols.',
      city: 'Cēsis',
      latitude: 57.313,
      longitude: 25.271,
      primaryImageUrl: null,
      imagesCount: 3,
      editorialPriority: 10,
      recommendationsCount: 45,
      upcomingEventsCount: 2,
      isNew: false,
      isRecommendedByMe: false,
      isFollowedByMe: false,
      isOpen: true,
      openingLabel: 'Atvērts līdz 18:00',
      rootCategoryName: 'Apskates objekti',
    );

    setUp(() {
      fakeEventsRepo = FakeEventsRepository();
      fakePlacesRepo = FakePlacesRepository();
      searchBloc = SearchBloc(
        eventsRepository: fakeEventsRepo,
        placesRepository: fakePlacesRepo,
      );
    });

    tearDown(() {
      searchBloc.close();
    });

    test('Initial state is correct', () {
      expect(searchBloc.state.status, equals(SearchStatus.initial));
      expect(searchBloc.state.query, isEmpty);
      expect(searchBloc.state.isLatviaWide, isFalse);
      expect(searchBloc.state.events, isEmpty);
      expect(searchBloc.state.places, isEmpty);
      expect(searchBloc.state.selectedTab, equals(SearchTab.all));
    });

    test('SearchQueryChanged with empty query resets to initial state', () async {
      searchBloc.add(const SearchQueryChanged('   '));
      await expectLater(
        searchBloc.stream,
        emits(predicate<SearchState>((state) =>
            state.status == SearchStatus.initial &&
            state.query == '' &&
            state.events.isEmpty &&
            state.places.isEmpty)),
      );
    });

    test('SearchQueryChanged queries within city when isLatviaWide is false', () async {
      fakeEventsRepo.eventsToReturn = [mockEvent];
      fakePlacesRepo.placesToReturn = [mockPlace];

      searchBloc.add(const SearchQueryChanged(
        'pils',
        placeId: 'cesis-id',
        isLatviaWide: false,
      ));

      await expectLater(
        searchBloc.stream,
        emitsInOrder([
          predicate<SearchState>((state) =>
              state.status == SearchStatus.loading &&
              state.query == 'pils' &&
              state.isLatviaWide == false &&
              state.placeId == 'cesis-id'),
          predicate<SearchState>((state) =>
              state.status == SearchStatus.success &&
              state.events.length == 1 &&
              state.places.length == 1 &&
              state.totalCount == 2),
        ]),
      );

      expect(fakeEventsRepo.lastSearch, equals('pils'));
      expect(fakeEventsRepo.lastPlaceId, equals('cesis-id'));
      expect(fakePlacesRepo.lastSearch, equals('pils'));
      expect(fakePlacesRepo.lastPlaceId, equals('cesis-id'));
    });

    test('SearchQueryChanged searches nationwide when isLatviaWide is true', () async {
      fakeEventsRepo.eventsToReturn = [mockEvent];
      fakePlacesRepo.placesToReturn = [];

      searchBloc.add(const SearchQueryChanged(
        'festivāls',
        placeId: 'cesis-id',
        isLatviaWide: true,
      ));

      await expectLater(
        searchBloc.stream,
        emitsInOrder([
          predicate<SearchState>((state) =>
              state.status == SearchStatus.loading &&
              state.isLatviaWide == true),
          predicate<SearchState>((state) =>
              state.status == SearchStatus.success &&
              state.events.length == 1 &&
              state.places.isEmpty &&
              state.totalCount == 1),
        ]),
      );

      // In nationwide search, placeId sent to repository should be null
      expect(fakeEventsRepo.lastPlaceId, isNull);
      expect(fakePlacesRepo.lastPlaceId, isNull);
    });

    test('SearchScopeChanged re-triggers search with nationwide scope', () async {
      fakeEventsRepo.eventsToReturn = [];
      fakePlacesRepo.placesToReturn = [];

      searchBloc.add(const SearchQueryChanged('teātris', placeId: 'valmiera-id', isLatviaWide: false));
      await searchBloc.stream.firstWhere((s) => s.status == SearchStatus.success);

      expect(searchBloc.state.isEmpty, isTrue);

      fakeEventsRepo.eventsToReturn = [mockEvent];
      searchBloc.add(const SearchScopeChanged(isLatviaWide: true, placeId: 'valmiera-id'));

      await expectLater(
        searchBloc.stream,
        emitsInOrder([
          predicate<SearchState>((state) =>
              state.status == SearchStatus.loading && state.isLatviaWide == true),
          predicate<SearchState>((state) =>
              state.status == SearchStatus.success &&
              state.events.length == 1 &&
              state.isLatviaWide == true),
        ]),
      );

      expect(fakeEventsRepo.lastPlaceId, isNull);
    });

    test('SearchTabChanged updates selectedTab', () async {
      searchBloc.add(const SearchTabChanged(SearchTab.events));
      await expectLater(
        searchBloc.stream,
        emits(predicate<SearchState>((state) => state.selectedTab == SearchTab.events)),
      );

      searchBloc.add(const SearchTabChanged(SearchTab.places));
      await expectLater(
        searchBloc.stream,
        emits(predicate<SearchState>((state) => state.selectedTab == SearchTab.places)),
      );
    });

    test('SearchClear resets state', () async {
      fakeEventsRepo.eventsToReturn = [mockEvent];
      fakePlacesRepo.placesToReturn = [mockPlace];

      searchBloc.add(const SearchQueryChanged('pils'));
      await searchBloc.stream.firstWhere((s) => s.status == SearchStatus.success);

      searchBloc.add(const SearchClear());
      await expectLater(
        searchBloc.stream,
        emits(predicate<SearchState>((state) =>
            state.status == SearchStatus.initial &&
            state.query == '' &&
            state.events.isEmpty &&
            state.places.isEmpty)),
      );
    });

    test('Repository failure emits failure status', () async {
      fakeEventsRepo.shouldThrow = true;

      searchBloc.add(const SearchQueryChanged('kļūda'));
      await expectLater(
        searchBloc.stream,
        emitsInOrder([
          predicate<SearchState>((state) => state.status == SearchStatus.loading),
          predicate<SearchState>((state) =>
              state.status == SearchStatus.failure &&
              state.errorMessage != null &&
              state.errorMessage!.contains('Meklēšanas kļūda')),
        ]),
      );
    });
  });
}
