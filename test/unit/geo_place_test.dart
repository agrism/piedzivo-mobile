import 'package:flutter_test/flutter_test.dart';
import 'package:piedzivo/features/geo/models/geo_place.dart';

void main() {
  group('GeoPlace model', () {
    test('fromJson and toJson with parent municipality', () {
      final json = {
        'id': 'city-cesis',
        'parent_id': 'muni-cesis',
        'name': 'Cēsis',
        'slug': 'cesis',
        'type': 'city',
        'is_state_city': false,
        'parent': {
          'id': 'muni-cesis',
          'name': 'Cēsu novads',
          'slug': 'cesu-novads',
          'type': 'municipality',
        },
      };

      final place = GeoPlace.fromJson(json);

      expect(place.id, 'city-cesis');
      expect(place.parentId, 'muni-cesis');
      expect(place.name, 'Cēsis');
      expect(place.slug, 'cesis');
      expect(place.type, 'city');
      expect(place.isStateCity, isFalse);
      expect(place.parent, isNotNull);
      expect(place.parent!.id, 'muni-cesis');
      expect(place.parent!.name, 'Cēsu novads');

      final serialized = place.toJson();
      expect(serialized['id'], 'city-cesis');
      expect(serialized['parent']['name'], 'Cēsu novads');
    });

    test('fromJson for State City (Valstspilsēta) without parent', () {
      final json = {
        'id': 'city-riga',
        'parent_id': null,
        'name': 'Rīga',
        'slug': 'riga',
        'type': 'city',
        'is_state_city': true,
        'parent': null,
      };

      final place = GeoPlace.fromJson(json);

      expect(place.id, 'city-riga');
      expect(place.isStateCity, isTrue);
      expect(place.parent, isNull);
    });

    test('Equatable value equality', () {
      const place1 = GeoPlace(
        id: '1',
        name: 'Sigulda',
        slug: 'sigulda',
        type: 'city',
        isStateCity: false,
      );
      const place2 = GeoPlace(
        id: '1',
        name: 'Sigulda',
        slug: 'sigulda',
        type: 'city',
        isStateCity: false,
      );

      expect(place1, equals(place2));
    });
  });
}

