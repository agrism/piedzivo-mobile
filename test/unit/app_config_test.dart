import 'package:flutter_test/flutter_test.dart';
import 'package:piedzivo/features/app_config/models/app_config.dart';

void main() {
  group('AppConfig model', () {
    test('fromJson correctly parses valid backend payload', () {
      final json = {
        'data': {
          'app_control': {
            'min_supported_version': '1.0.0',
            'latest_version': '1.2.0',
            'force_update': true,
            'store_urls': {
              'android': 'https://play.google.com/store/apps/details?id=lv.piedzivo.app',
            },
          },
          'legal': {
            'terms_version': '2.0',
            'terms_url': 'https://piedzivo.lv/noteikumi',
            'privacy_url': 'https://piedzivo.lv/privatums',
          },
          'classifications': {
            'taxonomy': {'checksum': 'chk_tax_123'},
            'tags': {'checksum': 'chk_tags_456'},
            'geo_places': {'checksum': 'chk_geo_789'},
          },
          'changelog': [
            {
              'version': '1.2.0',
              'date': '2026-10-30',
              'title': 'Jaunas iespējas',
              'items': ['Interaktīvā karte', 'Ātra filtrēšana'],
            },
          ],
        },
      };

      final config = AppConfig.fromJson(json);

      expect(config.minSupportedVersion, '1.0.0');
      expect(config.latestVersion, '1.2.0');
      expect(config.forceUpdate, isTrue);
      expect(config.androidStoreUrl, 'https://play.google.com/store/apps/details?id=lv.piedzivo.app');
      expect(config.termsVersion, '2.0');
      expect(config.termsUrl, 'https://piedzivo.lv/noteikumi');
      expect(config.privacyUrl, 'https://piedzivo.lv/privatums');
      expect(config.checksums['taxonomy'], 'chk_tax_123');
      expect(config.checksums['tags'], 'chk_tags_456');
      expect(config.checksums['geo_places'], 'chk_geo_789');

      expect(config.changelog.length, 1);
      final changelog = config.changelog.first;
      expect(changelog.version, '1.2.0');
      expect(changelog.date, '2026-10-30');
      expect(changelog.title, 'Jaunas iespējas');
      expect(changelog.items, ['Interaktīvā karte', 'Ātra filtrēšana']);
    });

    test('fromJson handles empty / fallback data gracefully', () {
      final config = AppConfig.fromJson({'data': {}});

      expect(config.minSupportedVersion, '1.0.0');
      expect(config.latestVersion, '1.0.0');
      expect(config.forceUpdate, isFalse);
      expect(config.androidStoreUrl, isNull);
      expect(config.termsVersion, '1.0');
      expect(config.termsUrl, 'https://piedzivo.lv/noteikumi');
      expect(config.privacyUrl, 'https://piedzivo.lv/privatums');
      expect(config.checksums['taxonomy'], '');
      expect(config.checksums['tags'], '');
      expect(config.checksums['geo_places'], '');
      expect(config.changelog, isEmpty);
    });
  });
}

