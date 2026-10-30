import 'package:equatable/equatable.dart';

class PlaceListItem extends Equatable {
  final String id;
  final String? publicId;
  final String slug;
  final String title;
  final String? shortDescription;
  final String city;
  final double? latitude;
  final double? longitude;
  final String? primaryImageUrl;
  final int imagesCount;
  final int editorialPriority;
  final int recommendationsCount;
  final int upcomingEventsCount;
  final bool isNew;
  final bool isRecommendedByMe;
  final bool isFollowedByMe;
  final bool isOpen;
  final String openingLabel;
  final String? rootCategoryName;
  final String? primaryTaxonomyName;

  const PlaceListItem({
    required this.id,
    this.publicId,
    required this.slug,
    required this.title,
    this.shortDescription,
    required this.city,
    this.latitude,
    this.longitude,
    this.primaryImageUrl,
    required this.imagesCount,
    required this.editorialPriority,
    required this.recommendationsCount,
    required this.upcomingEventsCount,
    required this.isNew,
    required this.isRecommendedByMe,
    required this.isFollowedByMe,
    required this.isOpen,
    required this.openingLabel,
    this.rootCategoryName,
    this.primaryTaxonomyName,
  });

  factory PlaceListItem.fromJson(Map<String, dynamic> json) {
    final openingStatus = json['opening_status'] as Map<String, dynamic>? ??
        (json['opening_status'] is Map ? Map<String, dynamic>.from(json['opening_status'] as Map) : null);
    final rootCategory = json['root_category'] as Map<String, dynamic>? ??
        (json['root_category'] is Map ? Map<String, dynamic>.from(json['root_category'] as Map) : null);
    final primaryTaxonomy = json['primary_taxonomy'] as Map<String, dynamic>? ??
        (json['primary_taxonomy'] is Map ? Map<String, dynamic>.from(json['primary_taxonomy'] as Map) : null);

    return PlaceListItem(
      id: json['id']?.toString() ?? '',
      publicId: json['public_id']?.toString(),
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      shortDescription: json['short_description']?.toString(),
      city: json['city']?.toString() ?? '',
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      primaryImageUrl: json['primary_image_url']?.toString(),
      imagesCount: (json['images_count'] as num?)?.toInt() ?? 1,
      editorialPriority: (json['editorial_priority'] as num?)?.toInt() ?? 0,
      recommendationsCount: (json['recommendations_count'] as num?)?.toInt() ?? 0,
      upcomingEventsCount: (json['upcoming_events_count'] as num?)?.toInt() ?? 0,
      isNew: json['is_new'] == true,
      isRecommendedByMe: json['is_recommended_by_me'] == true,
      isFollowedByMe: json['is_followed_by_me'] == true,
      isOpen: openingStatus?['is_open'] == true,
      openingLabel: openingStatus?['label']?.toString() ?? '',
      rootCategoryName: rootCategory?['name']?.toString(),
      primaryTaxonomyName: primaryTaxonomy?['name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'public_id': publicId,
      'slug': slug,
      'title': title,
      'short_description': shortDescription,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'primary_image_url': primaryImageUrl,
      'images_count': imagesCount,
      'editorial_priority': editorialPriority,
      'recommendations_count': recommendationsCount,
      'upcoming_events_count': upcomingEventsCount,
      'is_new': isNew,
      'is_recommended_by_me': isRecommendedByMe,
      'is_followed_by_me': isFollowedByMe,
      'opening_status': {
        'is_open': isOpen,
        'label': openingLabel,
      },
      'root_category': rootCategoryName != null ? {'name': rootCategoryName} : null,
      'primary_taxonomy': primaryTaxonomyName != null ? {'name': primaryTaxonomyName} : null,
    };
  }

  PlaceListItem copyWith({
    String? id,
    String? publicId,
    String? slug,
    String? title,
    String? shortDescription,
    String? city,
    double? latitude,
    double? longitude,
    String? primaryImageUrl,
    int? imagesCount,
    int? editorialPriority,
    int? recommendationsCount,
    int? upcomingEventsCount,
    bool? isNew,
    bool? isRecommendedByMe,
    bool? isFollowedByMe,
    bool? isOpen,
    String? openingLabel,
    String? rootCategoryName,
    String? primaryTaxonomyName,
  }) {
    return PlaceListItem(
      id: id ?? this.id,
      publicId: publicId ?? this.publicId,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      shortDescription: shortDescription ?? this.shortDescription,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      primaryImageUrl: primaryImageUrl ?? this.primaryImageUrl,
      imagesCount: imagesCount ?? this.imagesCount,
      editorialPriority: editorialPriority ?? this.editorialPriority,
      recommendationsCount: recommendationsCount ?? this.recommendationsCount,
      upcomingEventsCount: upcomingEventsCount ?? this.upcomingEventsCount,
      isNew: isNew ?? this.isNew,
      isRecommendedByMe: isRecommendedByMe ?? this.isRecommendedByMe,
      isFollowedByMe: isFollowedByMe ?? this.isFollowedByMe,
      isOpen: isOpen ?? this.isOpen,
      openingLabel: openingLabel ?? this.openingLabel,
      rootCategoryName: rootCategoryName ?? this.rootCategoryName,
      primaryTaxonomyName: primaryTaxonomyName ?? this.primaryTaxonomyName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        publicId,
        slug,
        title,
        shortDescription,
        city,
        latitude,
        longitude,
        primaryImageUrl,
        imagesCount,
        editorialPriority,
        recommendationsCount,
        upcomingEventsCount,
        isNew,
        isRecommendedByMe,
        isFollowedByMe,
        isOpen,
        openingLabel,
        rootCategoryName,
        primaryTaxonomyName,
      ];
}

