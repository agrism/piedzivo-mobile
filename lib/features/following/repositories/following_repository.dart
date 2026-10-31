import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../events/models/event_list_item.dart';
import '../models/followed_place_item.dart';

class FollowingRepository {
  final ApiClient apiClient;

  FollowingRepository({required this.apiClient});

  Future<List<EventListItem>> getFollowedEvents() async {
    try {
      final response = await apiClient.dio.get(
        '/me/events',
        options: Options(validateStatus: (status) => status != null && status < 500),
      );

      if (response.statusCode == 200 && response.data != null) {
        final dynamic data = response.data is String ? jsonDecode(response.data as String) : response.data;
        final list = data is Map<String, dynamic> && data.containsKey('data') ? data['data'] : data;

        if (list is List) {
          return list
              .whereType<Map<String, dynamic>>()
              .map((e) => EventListItem.fromJson(e))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<FollowedPlaceItem>> getFollowedPlaces() async {
    try {
      final response = await apiClient.dio.get(
        '/me/places',
        options: Options(validateStatus: (status) => status != null && status < 500),
      );

      if (response.statusCode == 200 && response.data != null) {
        final dynamic data = response.data is String ? jsonDecode(response.data as String) : response.data;
        final list = data is Map<String, dynamic> && data.containsKey('data') ? data['data'] : data;

        if (list is List) {
          return list
              .whereType<Map<String, dynamic>>()
              .map((e) => FollowedPlaceItem.fromJson(e))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> markPlaceViewed(String placeId) async {
    try {
      final response = await apiClient.dio.post(
        '/me/places/$placeId/viewed',
        data: {'place_id': placeId},
        options: Options(validateStatus: (status) => status != null && status < 500),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }
}
