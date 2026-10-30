import 'package:equatable/equatable.dart';

class EventListItem extends Equatable {
  final String id;
  final String? publicId;
  final String slug;
  final String title;
  final String? shortDescription;
  final String? imageUrl;
  final int editorialPriority;
  final int recommendationsCount;
  final bool isNew;
  final bool isRecommendedByMe;
  final bool isFollowedByMe;
  final String? primaryTaxonomyName;
  final String priceLabel;
  final bool isFree;
  final String startsOn; // YYYY-MM-DD
  final String? startsAt; // HH:mm:ss
  final String? placeId;
  final String? placeTitle;
  final String? placeCity;

  String? get primaryImageUrl => imageUrl;

  const EventListItem({
    required this.id,
    this.publicId,
    required this.slug,
    required this.title,
    this.shortDescription,
    this.imageUrl,
    required this.editorialPriority,
    required this.recommendationsCount,
    required this.isNew,
    required this.isRecommendedByMe,
    required this.isFollowedByMe,
    this.primaryTaxonomyName,
    required this.priceLabel,
    required this.isFree,
    required this.startsOn,
    this.startsAt,
    this.placeId,
    this.placeTitle,
    this.placeCity,
  });

  factory EventListItem.fromJson(Map<String, dynamic> json) {
    final priceBadge = json['price_badge'] is Map ? json['price_badge'] as Map : null;
    final occurrence = json['next_occurrence'] is Map ? json['next_occurrence'] as Map : null;
    final place = json['place'] is Map ? json['place'] as Map : null;
    final primaryTaxonomy = json['primary_taxonomy'] is Map ? json['primary_taxonomy'] as Map : null;

    final String priceLabel = priceBadge?['label']?.toString() ??
        (priceBadge?['type'] == 'free' ? 'Bezmaksas' : '');

    return EventListItem(
      id: json['id']?.toString() ?? '',
      publicId: json['public_id']?.toString(),
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      shortDescription: json['short_description']?.toString(),
      imageUrl: json['image_url']?.toString(),
      editorialPriority: (json['editorial_priority'] as num?)?.toInt() ?? 0,
      recommendationsCount: (json['recommendations_count'] as num?)?.toInt() ?? 0,
      isNew: json['is_new'] == true,
      isRecommendedByMe: json['is_recommended_by_me'] == true,
      isFollowedByMe: json['is_followed_by_me'] == true,
      primaryTaxonomyName: primaryTaxonomy?['name']?.toString(),
      priceLabel: priceLabel,
      isFree: priceBadge?['type'] == 'free' || priceLabel.toLowerCase().contains('bezmaksas'),
      startsOn: occurrence?['starts_on']?.toString() ?? json['starts_on']?.toString() ?? '',
      startsAt: occurrence?['starts_at']?.toString() ?? json['starts_at']?.toString(),
      placeId: place?['id']?.toString(),
      placeTitle: place?['title']?.toString() ?? place?['name']?.toString(),
      placeCity: place?['city']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'public_id': publicId,
      'slug': slug,
      'title': title,
      'short_description': shortDescription,
      'image_url': imageUrl,
      'editorial_priority': editorialPriority,
      'recommendations_count': recommendationsCount,
      'is_new': isNew,
      'is_recommended_by_me': isRecommendedByMe,
      'is_followed_by_me': isFollowedByMe,
      'primary_taxonomy': primaryTaxonomyName != null ? {'name': primaryTaxonomyName} : null,
      'price_badge': {
        'label': priceLabel,
        'type': isFree ? 'free' : 'paid',
      },
      'next_occurrence': {
        'starts_on': startsOn,
        'starts_at': startsAt,
      },
      'place': {
        'id': placeId,
        'title': placeTitle,
        'city': placeCity,
      },
    };
  }

  EventListItem copyWith({
    String? id,
    String? publicId,
    String? slug,
    String? title,
    String? shortDescription,
    String? imageUrl,
    int? editorialPriority,
    int? recommendationsCount,
    bool? isNew,
    bool? isRecommendedByMe,
    bool? isFollowedByMe,
    String? primaryTaxonomyName,
    String? priceLabel,
    bool? isFree,
    String? startsOn,
    String? startsAt,
    String? placeId,
    String? placeTitle,
    String? placeCity,
  }) {
    return EventListItem(
      id: id ?? this.id,
      publicId: publicId ?? this.publicId,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      shortDescription: shortDescription ?? this.shortDescription,
      imageUrl: imageUrl ?? this.imageUrl,
      editorialPriority: editorialPriority ?? this.editorialPriority,
      recommendationsCount: recommendationsCount ?? this.recommendationsCount,
      isNew: isNew ?? this.isNew,
      isRecommendedByMe: isRecommendedByMe ?? this.isRecommendedByMe,
      isFollowedByMe: isFollowedByMe ?? this.isFollowedByMe,
      primaryTaxonomyName: primaryTaxonomyName ?? this.primaryTaxonomyName,
      priceLabel: priceLabel ?? this.priceLabel,
      isFree: isFree ?? this.isFree,
      startsOn: startsOn ?? this.startsOn,
      startsAt: startsAt ?? this.startsAt,
      placeId: placeId ?? this.placeId,
      placeTitle: placeTitle ?? this.placeTitle,
      placeCity: placeCity ?? this.placeCity,
    );
  }

  @override
  List<Object?> get props => [
        id,
        publicId,
        slug,
        title,
        shortDescription,
        imageUrl,
        editorialPriority,
        recommendationsCount,
        isNew,
        isRecommendedByMe,
        isFollowedByMe,
        primaryTaxonomyName,
        priceLabel,
        isFree,
        startsOn,
        startsAt,
        placeId,
        placeTitle,
        placeCity,
      ];
}

