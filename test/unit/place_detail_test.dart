import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piedzivo/core/network/api_client.dart';
import 'package:piedzivo/features/places/models/place_detail.dart';
import 'package:piedzivo/features/places/repositories/places_repository.dart';
import 'api_client_test.dart';

void main() {
  group('Uzdevums 9: PlaceDetail Model & Repository Tests', () {
    final mockPlaceDetailJson = {
      'id': 'p1',
      'public_id': 'cesis-castle',
      'slug': 'cesu-pils',
      'title': 'Cēsu viduslaiku pils',
      'description': 'Vēsturisks cietoksnis un muzejs Cēsu centrā.',
      'city': 'Cēsis',
      'address': 'Pils laukums 9',
      'latitude': 57.3131,
      'longitude': 25.2715,
      'phone': '+371 64121815',
      'email': 'pils@cesis.lv',
      'website_url': 'https://cesupils.lv',
      'primary_image_url': 'https://cdn.piedzivo.lv/places/p1-1.jpg',
      'images': [
        'https://cdn.piedzivo.lv/places/p1-1.jpg',
        'https://cdn.piedzivo.lv/places/p1-2.jpg',
        'https://cdn.piedzivo.lv/places/p1-3.jpg',
      ],
      'editorial_priority': 10,
      'recommendations_count': 50,
      'upcoming_events_count': 2,
      'is_new': false,
      'is_recommended_by_me': false,
      'is_followed_by_me': false,
      'opening_status': {
        'is_open': true,
        'label': '🟢 Atvērts līdz 18:00',
      },
      'root_category': {'name': 'Apskates objekti'},
      'primary_taxonomy': {'name': 'Vēsturiskās vietas'},
      'weekly_schedule': [
        {'day_name': 'Pirmdiena', 'hours': 'Slēgts', 'is_closed': true},
        {'day_name': 'Otrdiena', 'hours': '10:00 - 18:00', 'is_closed': false, 'is_today': true},
        {'day_name': 'Trešdiena', 'hours': '10:00 - 18:00', 'is_closed': false},
      ],
      'upcoming_events': [
        {
          'id': 'evt-1',
          'slug': 'koncerts-pili',
          'title': 'Akustiskais koncerts pilī',
          'city': 'Cēsis',
          'price_badge': {'type': 'paid', 'label': '🎟️ no 12 €'},
          'primary_taxonomy': {'name': 'Koncerts'},
          'occurrence': {'starts_on': 'Šodien', 'starts_at': '19:00'},
        },
      ],
    };

    test('PlaceDetail.fromJson parses nested API response correctly', () {
      final detail = PlaceDetail.fromJson(mockPlaceDetailJson);

      expect(detail.id, 'p1');
      expect(detail.title, 'Cēsu viduslaiku pils');
      expect(detail.city, 'Cēsis');
      expect(detail.address, 'Pils laukums 9');
      expect(detail.latitude, 57.3131);
      expect(detail.longitude, 25.2715);
      expect(detail.phone, '+371 64121815');
      expect(detail.email, 'pils@cesis.lv');
      expect(detail.websiteUrl, 'https://cesupils.lv');
      expect(detail.images.length, 3);
      expect(detail.isOpen, isTrue);
      expect(detail.openingLabel, '🟢 Atvērts līdz 18:00');
      expect(detail.rootCategoryName, 'Apskates objekti');
      expect(detail.weeklySchedule.length, 3);
      expect(detail.weeklySchedule[0].dayName, 'Pirmdiena');
      expect(detail.weeklySchedule[0].isClosed, isTrue);
      expect(detail.weeklySchedule[1].isToday, isTrue);
      expect(detail.upcomingEvents.length, 1);
      expect(detail.upcomingEvents.first.title, 'Akustiskais koncerts pilī');
    });

    test('PlaceDetail.fromJson also handles wrapped { "data": ... } format', () {
      final wrapped = {'data': mockPlaceDetailJson};
      final detail = PlaceDetail.fromJson(wrapped);
      expect(detail.id, 'p1');
      expect(detail.title, 'Cēsu viduslaiku pils');
    });

    test('PlaceDetail copyWith works as expected', () {
      final detail = PlaceDetail.fromJson(mockPlaceDetailJson);
      final updated = detail.copyWith(
        isRecommendedByMe: true,
        recommendationsCount: 51,
        isFollowedByMe: true,
      );

      expect(updated.isRecommendedByMe, isTrue);
      expect(updated.recommendationsCount, 51);
      expect(updated.isFollowedByMe, isTrue);
      expect(updated.id, detail.id);
    });

    test('PlacesRepository.getPlaceDetail fetches and maps PlaceDetail correctly', () async {
      final fakeStorage = FakeSecureStorage();
      final mockAdapter = MockAdapter();

      mockAdapter.handler = (options) {
        if (options.path == '/places/p1') {
          return ResponseBody.fromString(
            jsonEncode({'data': mockPlaceDetailJson}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString(jsonEncode({'error': 'not found'}), 404);
      };

      final dio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
      dio.httpClientAdapter = mockAdapter;

      final apiClient = ApiClient(secureStorage: fakeStorage, dioClient: dio);
      final repo = PlacesRepository(apiClient: apiClient);

      final result = await repo.getPlaceDetail('p1');
      expect(result.id, 'p1');
      expect(result.title, 'Cēsu viduslaiku pils');
      expect(result.latitude, 57.3131);
      expect(result.images.length, 3);
    });

    test('PlacesRepository.toggleRecommend and toggleFollow succeed on 200', () async {
      final fakeStorage = FakeSecureStorage();
      final mockAdapter = MockAdapter();

      mockAdapter.handler = (options) {
        return ResponseBody.fromString(jsonEncode({'status': 'ok'}), 200);
      };

      final dio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
      dio.httpClientAdapter = mockAdapter;

      final apiClient = ApiClient(secureStorage: fakeStorage, dioClient: dio);
      final repo = PlacesRepository(apiClient: apiClient);

      final recOk = await repo.toggleRecommend('p1');
      expect(recOk, isTrue);

      final followOk = await repo.toggleFollow('p1');
      expect(followOk, isTrue);
    });
  });
}

