import 'package:equatable/equatable.dart';

class GeoPlace extends Equatable {
  final String id;
  final String? parentId;
  final String name;
  final String slug;
  final String type; // 'city', 'municipality', 'region'
  final bool isStateCity;
  final GeoPlaceParent? parent;

  const GeoPlace({
    required this.id,
    this.parentId,
    required this.name,
    required this.slug,
    required this.type,
    required this.isStateCity,
    this.parent,
  });

  factory GeoPlace.fromJson(Map<String, dynamic> json) {
    return GeoPlace(
      id: json['id']?.toString() ?? '',
      parentId: json['parent_id']?.toString(),
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      type: json['type']?.toString() ?? 'city',
      isStateCity: json['is_state_city'] == true,
      parent: json['parent'] != null
          ? GeoPlaceParent.fromJson(
              json['parent'] is Map<String, dynamic>
                  ? json['parent'] as Map<String, dynamic>
                  : Map<String, dynamic>.from(json['parent'] as Map),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent_id': parentId,
      'name': name,
      'slug': slug,
      'type': type,
      'is_state_city': isStateCity,
      'parent': parent?.toJson(),
    };
  }

  @override
  List<Object?> get props => [id, parentId, name, slug, type, isStateCity, parent];
}

class GeoPlaceParent extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String type;

  const GeoPlaceParent({
    required this.id,
    required this.name,
    required this.slug,
    required this.type,
  });

  factory GeoPlaceParent.fromJson(Map<String, dynamic> json) {
    return GeoPlaceParent(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'type': type,
    };
  }

  @override
  List<Object?> get props => [id, name, slug, type];
}

