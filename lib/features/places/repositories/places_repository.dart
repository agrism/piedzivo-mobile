import '../../../core/network/api_client.dart';
import '../models/place_detail.dart';
import '../models/place_list_item.dart';

class PlacesRepository {
  final ApiClient apiClient;

  PlacesRepository({required this.apiClient});

  Future<PlaceDetail> getPlaceDetail(String id) async {
    final response = await apiClient.dio.get('/places/$id');
    final dynamic rawData = response.data;
    final Map<String, dynamic> dataMap;
    if (rawData is Map<String, dynamic>) {
      dataMap = rawData;
    } else if (rawData is Map) {
      dataMap = Map<String, dynamic>.from(rawData);
    } else {
      throw Exception('Invalid place detail response format');
    }
    return PlaceDetail.fromJson(dataMap);
  }

  Future<List<PlaceListItem>> getPlaces({
    String? placeId,
    String? geoPlaceId,
    String? category,
    String? search,
  }) async {
    final Map<String, dynamic> queryParams = {};

    final effectiveGeoPlaceId = geoPlaceId ?? placeId;
    if (effectiveGeoPlaceId != null && effectiveGeoPlaceId.isNotEmpty) {
      queryParams['geo_place_id'] = effectiveGeoPlaceId;
    }
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['q'] = search;
    }

    final response = await apiClient.dio.get(
      '/places',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final dynamic rawData = response.data;
    final List<dynamic> listData;

    if (rawData is Map && rawData['data'] is List) {
      listData = rawData['data'] as List<dynamic>;
    } else if (rawData is List) {
      listData = rawData;
    } else {
      listData = const [];
    }

    return listData
        .map((item) => PlaceListItem.fromJson(
              item is Map<String, dynamic>
                  ? item
                  : Map<String, dynamic>.from(item as Map),
            ))
        .toList();
  }

  Future<bool> toggleRecommend(String placeId) async {
    try {
      final response = await apiClient.dio.post('/places/$placeId/recommend');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleFollow(String placeId) async {
    try {
      final response = await apiClient.dio.post('/places/$placeId/follow');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}

