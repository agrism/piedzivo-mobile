import '../../../core/network/api_client.dart';
import '../models/event_detail.dart';
import '../models/event_list_item.dart';

class EventsRepository {
  final ApiClient apiClient;

  EventsRepository({required this.apiClient});

  Future<EventDetail> getEventDetail(String eventId) async {
    final response = await apiClient.dio.get('/events/$eventId');
    final dynamic rawData = response.data;
    final Map<String, dynamic> dataMap = (rawData is Map && rawData['data'] is Map)
        ? (rawData['data'] is Map<String, dynamic>
            ? rawData['data'] as Map<String, dynamic>
            : Map<String, dynamic>.from(rawData['data'] as Map))
        : (rawData is Map<String, dynamic>
            ? rawData
            : Map<String, dynamic>.from(rawData as Map));

    return EventDetail.fromJson(dataMap);
  }

  Future<List<EventListItem>> getEvents({
    String? placeId,
    String? category,
    bool? isFree,
    String? date,
    String? search,
  }) async {
    final Map<String, dynamic> queryParams = {};

    if (placeId != null && placeId.isNotEmpty) {
      queryParams['place_id'] = placeId;
    }
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (isFree == true) {
      queryParams['is_free'] = '1';
    }
    if (date != null && date.isNotEmpty) {
      queryParams['date'] = date;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['q'] = search;
    }

    final response = await apiClient.dio.get(
      '/events',
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
        .map((item) => EventListItem.fromJson(
              item is Map<String, dynamic>
                  ? item
                  : Map<String, dynamic>.from(item as Map),
            ))
        .toList();
  }

  Future<bool> toggleRecommend(String eventId) async {
    try {
      final response = await apiClient.dio.post('/events/$eventId/recommend');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleFollow(String eventId) async {
    try {
      final response = await apiClient.dio.post('/events/$eventId/follow');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
