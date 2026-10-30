import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piedzivo/core/network/api_client.dart';
import 'package:piedzivo/features/geo/cubit/geo_cubit.dart';
import 'package:piedzivo/features/geo/models/geo_place.dart';
import 'package:piedzivo/features/geo/repositories/geo_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client_test.dart';

void main() {
  group('GeoCubit', () {
    late FakeSecureStorage fakeStorage;
    late MockAdapter mockAdapter;
    late ApiClient apiClient;
    late GeoRepository repository;

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

    const placeRiga = GeoPlace(
      id: 'city-riga',
      name: 'Rīga',
      slug: 'riga',
      type: 'city',
      isStateCity: true,
      parent: null,
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      fakeStorage = FakeSecureStorage();
      mockAdapter = MockAdapter();

      final dio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
      dio.httpClientAdapter = mockAdapter;

      apiClient = ApiClient(secureStorage: fakeStorage, dioClient: dio);
      repository = GeoRepository(apiClient: apiClient);
    });

    test('loadPlaces restores persisted activePlace and isMunicipalityWide', () async {
      SharedPreferences.setMockInitialValues({
        GeoRepository.cacheKeyPlacesJson: jsonEncode([placeRiga.toJson(), placeCesis.toJson()]),
        GeoRepository.cacheKeyChecksum: 'hash1',
        GeoCubit.keyActivePlaceId: 'city-cesis',
        GeoCubit.keyIsMunicipalityWide: true,
      });

      final cubit = GeoCubit(geoRepository: repository);
      await cubit.loadPlaces(serverChecksum: 'hash1');

      expect(cubit.state.places.length, 2);
      expect(cubit.state.activePlace, equals(placeCesis));
      expect(cubit.state.isMunicipalityWide, isTrue);
      expect(cubit.state.canToggleMunicipality, isTrue);
      expect(cubit.state.currentFilterPlaceId, 'muni-cesis');
      expect(cubit.state.municipalityName, 'Cēsu novads');
    });

    test('selectPlace updates activePlace and persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        GeoRepository.cacheKeyPlacesJson: jsonEncode([placeRiga.toJson(), placeCesis.toJson()]),
        GeoRepository.cacheKeyChecksum: 'hash1',
      });

      final cubit = GeoCubit(geoRepository: repository);
      await cubit.loadPlaces(serverChecksum: 'hash1');

      // Atlasām Cēsis
      await cubit.selectPlace(placeCesis);
      expect(cubit.state.activePlace, equals(placeCesis));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(GeoCubit.keyActivePlaceId), 'city-cesis');

      // Ieslēdzam novada mērogu
      await cubit.toggleMunicipalityWide();
      expect(cubit.state.isMunicipalityWide, isTrue);
      expect(prefs.getBool(GeoCubit.keyIsMunicipalityWide), isTrue);

      // Pārslēdzam uz Rīgu (valstspilsēta) -> novada mērogam jāizslēdzas
      await cubit.selectPlace(placeRiga);
      expect(cubit.state.activePlace, equals(placeRiga));
      expect(cubit.state.isMunicipalityWide, isFalse);
      expect(cubit.state.canToggleMunicipality, isFalse);
      expect(cubit.state.currentFilterPlaceId, 'city-riga');
      expect(prefs.getString(GeoCubit.keyActivePlaceId), 'city-riga');
      expect(prefs.getBool(GeoCubit.keyIsMunicipalityWide), isFalse);
    });
  });
}
