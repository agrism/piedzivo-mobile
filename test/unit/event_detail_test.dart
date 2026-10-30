import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piedzivo/core/network/api_client.dart';
import 'package:piedzivo/features/events/models/event_detail.dart';
import 'package:piedzivo/features/events/repositories/events_repository.dart';
import 'api_client_test.dart';

void main() {
  group('EventDetail Model & Repository Tests', () {
    final sampleJson = {
      'id': 'evt-100',
      'public_id': 'pub-100',
      'slug': 'daugavpils-simfoniskais-orkestris',
      'title': 'Daugavpils Simfoniskā orķestra koncerts',
      'description': 'Lielisks klasiskās mūzikas koncerts Vienības namā ar izciliem solistiem.',
      'image_url': 'https://piedzivo.lv/storage/events/dso.jpg',
      'editorial_priority': 10,
      'recommendations_count': 42,
      'is_new': true,
      'is_recommended_by_me': false,
      'is_followed_by_me': true,
      'ticket_url': 'https://bilesuparadize.lv/lv/event/100',
      'website_url': 'https://vienibasnams.lv',
      'price_badge': {
        'label': 'no 10 €',
        'type': 'paid',
        'details': 'Pensionāriem un skolēniem 5 €',
      },
      'next_occurrence': {
        'starts_on': '2026-11-05',
        'starts_at': '18:00:00',
        'ends_on': '2026-11-05',
        'ends_at': '20:30:00',
      },
      'primary_taxonomy': {
        'id': 'tax-1',
        'name': 'Koncerts',
      },
      'place': {
        'id': 'place-daugavpils-vn',
        'title': 'Vienības nams',
        'city': 'Daugavpils',
        'address': 'Rīgas iela 22a',
        'latitude': 55.871,
        'longitude': 26.516,
        'primary_image_url': 'https://piedzivo.lv/storage/places/vn.jpg',
      },
    };

    test('EventDetail.fromJson parses nested API response correctly', () {
      final detail = EventDetail.fromJson(sampleJson);

      expect(detail.id, 'evt-100');
      expect(detail.publicId, 'pub-100');
      expect(detail.slug, 'daugavpils-simfoniskais-orkestris');
      expect(detail.title, 'Daugavpils Simfoniskā orķestra koncerts');
      expect(detail.description, contains('Lielisks klasiskās mūzikas koncerts'));
      expect(detail.imageUrl, 'https://piedzivo.lv/storage/events/dso.jpg');
      expect(detail.editorialPriority, 10);
      expect(detail.recommendationsCount, 42);
      expect(detail.isNew, true);
      expect(detail.isRecommendedByMe, false);
      expect(detail.isFollowedByMe, true);
      expect(detail.ticketUrl, 'https://bilesuparadize.lv/lv/event/100');
      expect(detail.websiteUrl, 'https://vienibasnams.lv');
      expect(detail.primaryTaxonomyName, 'Koncerts');
      expect(detail.priceLabel, 'no 10 €');
      expect(detail.priceDetails, 'Pensionāriem un skolēniem 5 €');
      expect(detail.isFree, false);
      expect(detail.startsOn, '2026-11-05');
      expect(detail.startsAt, '18:00:00');
      expect(detail.endsOn, '2026-11-05');
      expect(detail.endsAt, '20:30:00');
      expect(detail.placeId, 'place-daugavpils-vn');
      expect(detail.placeTitle, 'Vienības nams');
      expect(detail.placeCity, 'Daugavpils');
      expect(detail.placeAddress, 'Rīgas iela 22a');
      expect(detail.placeLatitude, 55.871);
      expect(detail.placeLongitude, 26.516);
      expect(detail.placePrimaryImageUrl, 'https://piedzivo.lv/storage/places/vn.jpg');
    });

    test('EventDetail.fromJson also handles wrapped { "data": ... } format', () {
      final wrappedJson = {'data': sampleJson};
      final detail = EventDetail.fromJson(wrappedJson);

      expect(detail.id, 'evt-100');
      expect(detail.title, 'Daugavpils Simfoniskā orķestra koncerts');
    });

    test('EventDetail copyWith works as expected', () {
      final original = EventDetail.fromJson(sampleJson);
      final updated = original.copyWith(
        isRecommendedByMe: true,
        recommendationsCount: 43,
      );

      expect(updated.isRecommendedByMe, true);
      expect(updated.recommendationsCount, 43);
      expect(updated.id, original.id);
      expect(updated.title, original.title);
    });

    test('EventsRepository.getEventDetail fetches and maps EventDetail correctly', () async {
      final fakeStorage = FakeSecureStorage();
      final mockAdapter = MockAdapter();

      mockAdapter.handler = (options) {
        if (options.path == '/events/evt-100') {
          return ResponseBody.fromString(
            jsonEncode({'data': sampleJson}),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString(jsonEncode({'error': 'Not found'}), 404);
      };

      final dio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
      dio.httpClientAdapter = mockAdapter;

      final apiClient = ApiClient(secureStorage: fakeStorage, dioClient: dio);
      final repo = EventsRepository(apiClient: apiClient);

      final detail = await repo.getEventDetail('evt-100');

      expect(detail.id, 'evt-100');
      expect(detail.title, 'Daugavpils Simfoniskā orķestra koncerts');
      expect(detail.placeCity, 'Daugavpils');
      expect(detail.recommendationsCount, 42);
    });
  });
}

