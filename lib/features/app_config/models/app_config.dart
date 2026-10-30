class AppConfig {
  final String minSupportedVersion;
  final String latestVersion;
  final bool forceUpdate;
  final String? androidStoreUrl;
  final String termsVersion;
  final String termsUrl;
  final String privacyUrl;
  final Map<String, String> checksums; // {'taxonomy': '...', 'tags': '...', 'geo_places': '...'}
  final List<ChangelogItem> changelog;

  AppConfig({
    required this.minSupportedVersion,
    required this.latestVersion,
    required this.forceUpdate,
    this.androidStoreUrl,
    required this.termsVersion,
    required this.termsUrl,
    required this.privacyUrl,
    required this.checksums,
    required this.changelog,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final dynamic rawData = json['data'];
    final Map<dynamic, dynamic> data = (rawData is Map) ? rawData : json;
    final Map<dynamic, dynamic> appControl = (data['app_control'] is Map) ? data['app_control'] : const {};
    final Map<dynamic, dynamic> legal = (data['legal'] is Map) ? data['legal'] : const {};
    final Map<dynamic, dynamic> classifications = (data['classifications'] is Map) ? data['classifications'] : const {};

    return AppConfig(
      minSupportedVersion: appControl['min_supported_version']?.toString() ?? '1.0.0',
      latestVersion: appControl['latest_version']?.toString() ?? '1.0.0',
      forceUpdate: appControl['force_update'] == true,
      androidStoreUrl: appControl['store_urls']?['android']?.toString(),
      termsVersion: legal['terms_version']?.toString() ?? '1.0',
      termsUrl: legal['terms_url']?.toString() ?? 'https://piedzivo.lv/noteikumi',
      privacyUrl: legal['privacy_url']?.toString() ?? 'https://piedzivo.lv/privatums',
      checksums: {
        'taxonomy': classifications['taxonomy']?['checksum']?.toString() ?? '',
        'tags': classifications['tags']?['checksum']?.toString() ?? '',
        'geo_places': classifications['geo_places']?['checksum']?.toString() ?? '',
      },
      changelog: (data['changelog'] as List<dynamic>? ?? [])
          .map((item) => ChangelogItem.fromJson(
                (item is Map<String, dynamic>)
                    ? item
                    : Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
    );
  }
}

class ChangelogItem {
  final String version;
  final String date;
  final String title;
  final List<String> items;

  ChangelogItem({
    required this.version,
    required this.date,
    required this.title,
    required this.items,
  });

  factory ChangelogItem.fromJson(Map<String, dynamic> json) {
    return ChangelogItem(
      version: json['version'] ?? '',
      date: json['date'] ?? '',
      title: json['title'] ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
