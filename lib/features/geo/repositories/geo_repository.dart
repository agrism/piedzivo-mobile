import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../models/geo_place.dart';

class GeoRepository {
  static const String cacheKeyPlacesJson = 'cached_geo_places_json';
  static const String cacheKeyChecksum = 'cached_geo_places_checksum';

  final ApiClient apiClient;
  final SharedPreferences? _prefs;

  GeoRepository({
    required this.apiClient,
    SharedPreferences? prefs,
  }) : _prefs = prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  Future<List<GeoPlace>> getGeoPlaces({String? serverChecksum}) async {
    final prefs = await _getPrefs();
    final cachedChecksum = prefs.getString(cacheKeyChecksum);
    final cachedJson = prefs.getString(cacheKeyPlacesJson);

    // Ja servera kontrolsumma sakrīt ar lokālo un kešs eksistē, izmantojam lokālos datus bez tīkla pieprasījuma
    final bool isCacheValid = serverChecksum != null &&
        serverChecksum.isNotEmpty &&
        serverChecksum == cachedChecksum &&
        cachedJson != null &&
        cachedJson.isNotEmpty;

    if (isCacheValid) {
      try {
        final decoded = jsonDecode(cachedJson) as List<dynamic>;
        return decoded
            .map((item) => GeoPlace.fromJson(
                  item is Map<String, dynamic>
                      ? item
                      : Map<String, dynamic>.from(item as Map),
                ))
            .toList();
      } catch (_) {
        // Ja kešs ir bojāts, turpinām ar tīkla pieprasījumu
      }
    }

    try {
      final response = await apiClient.dio.get('/geo-places');
      final dynamic rawData = response.data;
      final List<dynamic> listData;

      if (rawData is Map && rawData['data'] is List) {
        listData = rawData['data'] as List<dynamic>;
      } else if (rawData is List) {
        listData = rawData;
      } else {
        listData = const [];
      }

      final places = listData
          .map((item) => GeoPlace.fromJson(
                item is Map<String, dynamic>
                    ? item
                    : Map<String, dynamic>.from(item as Map),
              ))
          .toList();

      // Saglabājam kešā
      await prefs.setString(
        cacheKeyPlacesJson,
        jsonEncode(places.map((p) => p.toJson()).toList()),
      );

      if (serverChecksum != null && serverChecksum.isNotEmpty) {
        await prefs.setString(cacheKeyChecksum, serverChecksum);
      }

      return places;
    } on DioException {
      // Ja tīkls nav pieejams, mēģinām atgriezt kešotos datus
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final decoded = jsonDecode(cachedJson) as List<dynamic>;
        return decoded
            .map((item) => GeoPlace.fromJson(
                  item is Map<String, dynamic>
                      ? item
                      : Map<String, dynamic>.from(item as Map),
                ))
            .toList();
      }
      rethrow;
    }
  }

  Future<String?> getCachedChecksum() async {
    final prefs = await _getPrefs();
    return prefs.getString(cacheKeyChecksum);
  }

  Future<List<GeoPlace>> getCachedPlaces() async {
    final prefs = await _getPrefs();
    final cachedJson = prefs.getString(cacheKeyPlacesJson);
    if (cachedJson == null || cachedJson.isEmpty) return const [];

    final decoded = jsonDecode(cachedJson) as List<dynamic>;
    return decoded
        .map((item) => GeoPlace.fromJson(
              item is Map<String, dynamic>
                  ? item
                  : Map<String, dynamic>.from(item as Map),
            ))
        .toList();
  }
}

