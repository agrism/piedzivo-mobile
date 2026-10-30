import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piedzivo/core/network/api_client.dart';
import 'package:piedzivo/features/places/bloc/places_bloc.dart';
import 'package:piedzivo/features/places/bloc/places_event.dart';
import 'package:piedzivo/features/places/bloc/places_state.dart';
import 'package:piedzivo/features/places/models/place_list_item.dart';
import 'package:piedzivo/features/places/repositories/places_repository.dart';
import 'api_client_test.dart';

void main() {
  group('Places Module Unit Tests', () {
    late FakeSecureStorage fakeStorage;
    late MockAdapter mockAdapter;
    late ApiClient apiClient;
    late PlacesRepository repository;

    const mockPlace1 = PlaceListItem(
      id: 'p1',
      slug: 'cesu-pils',
      title: 'Cēsu viduslaiku pils',
      shortDescription: 'Senākais Cēsu vēstures simbols.',
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
      slug: 'restorans-cesis',
      title: 'Restorāns Jāņoga',
      shortDescription: 'Mūsdienīga latviešu virtuve.',
      city: 'Cēsis',
      latitude: 57.315,
      longitude: 25.275,
      primaryImageUrl: 'https://piedzivo.lv/storage/places/janoga.jpg',
      imagesCount: 6,
      editorialPriority: 5,
      recommendationsCount: 80,
      upcomingEventsCount: 0,
      isNew: true,
      isRecommendedByMe: true,
      isFollowedByMe: true,
      isOpen: false,
      openingLabel: 'Slēgts (atvērsies 12:00)',
      rootCategoryName: 'Ēdināšana',
      primaryTaxonomyName: 'Restorāni',
    );

    const mockPlace3 = PlaceListItem(
      id: 'p3',
      slug: 'ungurmuiza',
      title: 'Ungurmuiža',
      shortDescription: 'Vienīgā koka muiža Latvijā.',
      city: 'Cēsis',
      latitude: 57.362,
      longitude: 25.088,
      primaryImageUrl: 'https://piedzivo.lv/storage/places/ungurmuiza.jpg',
      imagesCount: 2,
      editorialPriority: 10,
      recommendationsCount: 95, // Augstāks recommendationsCount nekā p1
      upcomingEventsCount: 2,
      isNew: false,
      isRecommendedByMe: false,
      isFollowedByMe: false,
      isOpen: true,
      openingLabel: 'Atvērts līdz 19:00',
      rootCategoryName: 'Apskates objekti',
      primaryTaxonomyName: 'Pilis un muižas',
    );

    setUp(() {
      fakeStorage = FakeSecureStorage();
      mockAdapter = MockAdapter();

      final dio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
      dio.httpClientAdapter = mockAdapter;

      apiClient = ApiClient(secureStorage: fakeStorage, dioClient: dio);
      repository = PlacesRepository(apiClient: apiClient);
    });

    test('PlaceListItem.fromJson and toJson parses API format correctly', () {
      final json = mockPlace1.toJson();
      final parsed = PlaceListItem.fromJson(json);

      expect(parsed.id, 'p1');
      expect(parsed.title, 'Cēsu viduslaiku pils');
      expect(parsed.city, 'Cēsis');
      expect(parsed.latitude, 57.313);
      expect(parsed.longitude, 25.271);
      expect(parsed.imagesCount, 4);
      expect(parsed.editorialPriority, 10);
      expect(parsed.recommendationsCount, 50);
      expect(parsed.upcomingEventsCount, 3);
      expect(parsed.isOpen, true);
      expect(parsed.openingLabel, 'Atvērts līdz 18:00');
      expect(parsed.rootCategoryName, 'Apskates objekti');
    });

    test('PlacesRepository.getPlaces fetches places with query params', () async {
      mockAdapter.handler = (options) {
        if (options.path == '/places') {
          return ResponseBody.fromString(
            jsonEncode({
              'data': [mockPlace1.toJson(), mockPlace2.toJson()],
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString(jsonEncode({'error': 'Not found'}), 404);
      };

      final places = await repository.getPlaces(placeId: 'city-cesis');
      expect(places.length, 2);
      expect(places[0].title, 'Cēsu viduslaiku pils');
      expect(places[1].title, 'Restorāns Jāņoga');
    });

    test('PlacesBloc LoadPlaces orders places by rank and groups by category', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({
            'data': [mockPlace1.toJson(), mockPlace2.toJson(), mockPlace3.toJson()],
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final bloc = PlacesBloc(repository: repository);
      expect(
        bloc.stream,
        emitsInOrder([
          isA<PlacesLoading>(),
          predicate<PlacesLoaded>((state) {
            // Rank pārbaude:
            // p3 (priority 10, rec 95) jābūt pirms p1 (priority 10, rec 50)
            final apskatesObjekti = state.groupedPlaces['Apskates objekti']!;
            return apskatesObjekti.length == 2 &&
                apskatesObjekti[0].id == 'p3' &&
                apskatesObjekti[1].id == 'p1' &&
                state.groupedPlaces.containsKey('Ēdināšana');
          }),
        ]),
      );

      bloc.add(const LoadPlaces(placeId: 'city-cesis'));
    });

    test('PlacesBloc FilterPlaces filters by root category', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({
            'data': [mockPlace1.toJson(), mockPlace2.toJson(), mockPlace3.toJson()],
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final bloc = PlacesBloc(repository: repository);
      bloc.add(const LoadPlaces());

      await bloc.stream.firstWhere((s) => s is PlacesLoaded);

      // Filtrējam tikai 'Ēdināšana'
      bloc.add(const FilterPlaces(category: 'Ēdināšana'));
      final state = await bloc.stream.firstWhere((s) => s is PlacesLoaded) as PlacesLoaded;

      expect(state.filteredPlaces.length, 1);
      expect(state.filteredPlaces.first.title, 'Restorāns Jāņoga');
      expect(state.selectedCategory, 'Ēdināšana');
    });

    test('PlacesBloc ToggleRecommendPlace and ToggleFollowPlace update optimistically', () async {
      mockAdapter.handler = (options) {
        if (options.path.contains('/recommend') || options.path.contains('/follow')) {
          return ResponseBody.fromString(jsonEncode({'status': 'ok'}), 200);
        }
        return ResponseBody.fromString(
          jsonEncode({
            'data': [mockPlace1.toJson()],
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final bloc = PlacesBloc(repository: repository);
      bloc.add(const LoadPlaces());

      await bloc.stream.firstWhere((s) => s is PlacesLoaded);

      // Toggle recommend
      bloc.add(const ToggleRecommendPlace('p1'));
      var state = await bloc.stream.firstWhere((s) => s is PlacesLoaded) as PlacesLoaded;
      expect(state.allPlaces.first.isRecommendedByMe, true);
      expect(state.allPlaces.first.recommendationsCount, 51);

      // Toggle follow
      bloc.add(const ToggleFollowPlace('p1'));
      state = await bloc.stream.firstWhere((s) => s is PlacesLoaded) as PlacesLoaded;
      expect(state.allPlaces.first.isFollowedByMe, true);
    });
  });
}

