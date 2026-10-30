import 'package:flutter_test/flutter_test.dart';
import 'package:piedzivo/features/events/models/event_list_item.dart';
import 'package:piedzivo/features/events/utils/event_date_formatter.dart';

void main() {
  group('EventListItem model', () {
    test('fromJson parses full API response payload', () {
      final json = {
        'id': 'evt-101',
        'public_id': 'PUB101',
        'slug': 'imanta-kalnina-koncerts',
        'title': 'Imanta Kalniņa mūzikas koncerts',
        'short_description': 'Īpašs koncerts Vidzemes koncertzālē',
        'image_url': 'https://piedzivo.lv/storage/events/101.jpg',
        'editorial_priority': 10,
        'recommendations_count': 42,
        'is_new': true,
        'is_recommended_by_me': false,
        'is_followed_by_me': true,
        'primary_taxonomy': {'name': 'Koncerts'},
        'price_badge': {
          'label': 'no 15 €',
          'type': 'paid',
        },
        'next_occurrence': {
          'starts_on': '2026-10-30',
          'starts_at': '19:00:00',
        },
        'place': {
          'id': 'pl-cesis',
          'title': 'Vidzemes koncertzāle "Cēsis"',
          'city': 'Cēsis',
        },
      };

      final event = EventListItem.fromJson(json);

      expect(event.id, 'evt-101');
      expect(event.publicId, 'PUB101');
      expect(event.slug, 'imanta-kalnina-koncerts');
      expect(event.title, 'Imanta Kalniņa mūzikas koncerts');
      expect(event.imageUrl, 'https://piedzivo.lv/storage/events/101.jpg');
      expect(event.editorialPriority, 10);
      expect(event.recommendationsCount, 42);
      expect(event.isNew, isTrue);
      expect(event.isRecommendedByMe, isFalse);
      expect(event.isFollowedByMe, isTrue);
      expect(event.primaryTaxonomyName, 'Koncerts');
      expect(event.priceLabel, 'no 15 €');
      expect(event.isFree, isFalse);
      expect(event.startsOn, '2026-10-30');
      expect(event.startsAt, '19:00:00');
      expect(event.placeId, 'pl-cesis');
      expect(event.placeTitle, 'Vidzemes koncertzāle "Cēsis"');
      expect(event.placeCity, 'Cēsis');
    });

    test('EventDateFormatter groups events by day (ŠODIEN, RĪT, DATUMS)', () {
      final now = DateTime(2026, 10, 30, 10, 0); // Piektdiena

      const eventToday = EventListItem(
        id: '1',
        slug: 'e1',
        title: 'Pasākums šodien',
        editorialPriority: 0,
        recommendationsCount: 5,
        isNew: false,
        isRecommendedByMe: false,
        isFollowedByMe: false,
        priceLabel: 'Bezmaksas',
        isFree: true,
        startsOn: '2026-10-30',
        startsAt: '19:00:00',
      );

      const eventTomorrow = EventListItem(
        id: '2',
        slug: 'e2',
        title: 'Pasākums rīt',
        editorialPriority: 0,
        recommendationsCount: 1,
        isNew: true,
        isRecommendedByMe: false,
        isFollowedByMe: false,
        priceLabel: '5 €',
        isFree: false,
        startsOn: '2026-10-31',
        startsAt: '12:00:00',
      );

      const eventSunday = EventListItem(
        id: '3',
        slug: 'e3',
        title: 'Pasākums svētdien',
        editorialPriority: 0,
        recommendationsCount: 0,
        isNew: false,
        isRecommendedByMe: false,
        isFollowedByMe: false,
        priceLabel: '10 €',
        isFree: false,
        startsOn: '2026-11-01',
        startsAt: '18:00:00',
      );

      final grouped = EventDateFormatter.groupEventsByDay(
        [eventSunday, eventToday, eventTomorrow],
        customNow: now,
      );

      final headers = grouped.keys.toList();
      expect(headers.length, 3);
      expect(headers[0], startsWith('ŠODIEN'));
      expect(headers[1], startsWith('RĪT'));
      expect(headers[2], contains('SVĒTDIENA'));

      expect(grouped[headers[0]]!.first.id, '1');
      expect(grouped[headers[1]]!.first.id, '2');
      expect(grouped[headers[2]]!.first.id, '3');
    });
  });
}

