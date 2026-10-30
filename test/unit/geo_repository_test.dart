import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piedzivo/core/network/api_client.dart';
import 'package:piedzivo/features/geo/repositories/geo_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client_test.dart';

void main() {
  group('GeoRepository', () {
    late FakeSecureStorage fakeStorage;
    late MockAdapter mockAdapter;
    late ApiClient apiClient;
    late GeoRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      fakeStorage = FakeSecureStorage();
      mockAdapter = MockAdapter();

      final dio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
      dio.httpClientAdapter = mockAdapter;

      apiClient = ApiClient(secureStorage: fakeStorage, dioClient: dio);
      repository = GeoRepository(apiClient: apiClient);
    });

    test('fetches from API when cache is empty and saves to local storage', () async {
      int networkCalls = 0;
      mockAdapter.handler = (options) {
        networkCalls++;
        expect(options.path, '/geo-places');
        return ResponseBody.fromString(
          jsonEncode({
            'data': [
              {
                'id': 'city-valmiera',
                'name': 'Valmiera',
                'slug': 'valmiera',
                'type': 'city',
                'is_state_city': true,
              },
            ],
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final places = await repository.getGeoPlaces(serverChecksum: 'hash123');

      expect(networkCalls, 1);
      expect(places.length, 1);
      expect(places.first.name, 'Valmiera');

      final cachedChecksum = await repository.getCachedChecksum();
      expect(cachedChecksum, 'hash123');

      final cachedPlaces = await repository.getCachedPlaces();
      expect(cachedPlaces.length, 1);
      expect(cachedPlaces.first.id, 'city-valmiera');
    });

    test('skips network call and returns cached places when checksum matches', () async {
      // Sagatavojam esošu kešu
      SharedPreferences.setMockInitialValues({
        GeoRepository.cacheKeyChecksum: 'matching_hash',
        GeoRepository.cacheKeyPlacesJson: jsonEncode([
          {
            'id': 'city-cesis',
            'name': 'Cēsis',
            'slug': 'cesis',
            'type': 'city',
            'is_state_city': false,
          },
        ]),
      });

      int networkCalls = 0;
      mockAdapter.handler = (options) {
        networkCalls++;
        throw Exception('Network should not be called!');
      };

      final places = await repository.getGeoPlaces(serverChecksum: 'matching_hash');

      expect(networkCalls, 0);
      expect(places.length, 1);
      expect(places.first.name, 'Cēsis');
    });

    test('calls network when checksum does not match even if cache exists', () async {
      SharedPreferences.setMockInitialValues({
        GeoRepository.cacheKeyChecksum: 'old_hash',
        GeoRepository.cacheKeyPlacesJson: jsonEncode([
          {'id': 'old-city', 'name': 'Vecā pilsēta', 'slug': 'old', 'type': 'city', 'is_state_city': false},
        ]),
      });

      int networkCalls = 0;
      mockAdapter.handler = (options) {
        networkCalls++;
        return ResponseBody.fromString(
          jsonEncode({
            'data': [
              {
                'id': 'new-city',
                'name': 'Jaunā pilsēta',
                'slug': 'new',
                'type': 'city',
                'is_state_city': false,
              },
            ],
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final places = await repository.getGeoPlaces(serverChecksum: 'new_hash');

      expect(networkCalls, 1);
      expect(places.first.name, 'Jaunā pilsēta');

      final updatedChecksum = await repository.getCachedChecksum();
      expect(updatedChecksum, 'new_hash');
    });
  });
}
