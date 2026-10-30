import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piedzivo/core/network/api_client.dart';
import 'package:piedzivo/features/app_config/repositories/app_config_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client_test.dart';

void main() {
  group('AppConfigRepository', () {
    late FakeSecureStorage fakeStorage;
    late MockAdapter mockAdapter;
    late ApiClient apiClient;
    late AppConfigRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      fakeStorage = FakeSecureStorage();
      mockAdapter = MockAdapter();

      final dio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
      dio.httpClientAdapter = mockAdapter;

      apiClient = ApiClient(secureStorage: fakeStorage, dioClient: dio);
      repository = AppConfigRepository(apiClient: apiClient);
    });

    test('getAppConfig fetches configuration and caches checksums', () async {
      mockAdapter.handler = (options) {
        expect(options.path, '/app-config');
        return ResponseBody.fromString(
          jsonEncode({
            'data': {
              'app_control': {
                'min_supported_version': '1.0.0',
                'latest_version': '1.0.2',
                'force_update': false,
              },
              'legal': {
                'terms_version': '1.0',
                'terms_url': 'https://piedzivo.lv/noteikumi',
                'privacy_url': 'https://piedzivo.lv/privatums',
              },
              'classifications': {
                'taxonomy': {'checksum': 'tax-hash-111'},
                'tags': {'checksum': 'tags-hash-222'},
                'geo_places': {'checksum': 'geo-hash-333'},
              },
              'changelog': [],
            },
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final config = await repository.getAppConfig();

      expect(config.latestVersion, '1.0.2');
      expect(config.checksums['geo_places'], 'geo-hash-333');

      final cachedGeoChecksum = await repository.getCachedChecksum('geo_places');
      expect(cachedGeoChecksum, 'geo-hash-333');

      final cachedTaxChecksum = await repository.getCachedChecksum('taxonomy');
      expect(cachedTaxChecksum, 'tax-hash-111');
    });
  });
}

