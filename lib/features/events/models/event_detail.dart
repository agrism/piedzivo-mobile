import 'package:equatable/equatable.dart';

class EventDetail extends Equatable {
  final String id;
  final String? publicId;
  final String slug;
  final String title;
  final String? description;
  final String? imageUrl;
  final int editorialPriority;
  final int recommendationsCount;
  final bool isNew;
  final bool isRecommendedByMe;
  final bool isFollowedByMe;
  final String? primaryTaxonomyName;
  final String priceLabel;
  final String? priceDetails;
  final bool isFree;
  final String? ticketUrl;
  final String? websiteUrl;
  final String startsOn;
  final String? startsAt;
  final String? endsOn;
  final String? endsAt;
  final String? placeId;
  final String? placeTitle;
  final String? placeCity;
  final String? placeAddress;
  final double? placeLatitude;
  final double? placeLongitude;
  final String? placePrimaryImageUrl;

  const EventDetail({
    required this.id,
    this.publicId,
    required this.slug,
    required this.title,
    this.description,
    this.imageUrl,
    required this.editorialPriority,
    required this.recommendationsCount,
    required this.isNew,
    required this.isRecommendedByMe,
    required this.isFollowedByMe,
    this.primaryTaxonomyName,
    required this.priceLabel,
    this.priceDetails,
    required this.isFree,
    this.ticketUrl,
    this.websiteUrl,
    required this.startsOn,
    this.startsAt,
    this.endsOn,
    this.endsAt,
    this.placeId,
    this.placeTitle,
    this.placeCity,
    this.placeAddress,
    this.placeLatitude,
    this.placeLongitude,
    this.placePrimaryImageUrl,
  });

  factory EventDetail.fromJson(Map<String, dynamic> source) {
    final json = (source['data'] is Map<String, dynamic>)
        ? source['data'] as Map<String, dynamic>
        : (source['data'] is Map)
            ? Map<String, dynamic>.from(source['data'] as Map)
            : source;

    final priceBadge = json['price_badge'] as Map<String, dynamic>? ??
        (json['price_badge'] is Map ? Map<String, dynamic>.from(json['price_badge'] as Map) : null);
    final occurrence = json['next_occurrence'] as Map<String, dynamic>? ??
        (json['next_occurrence'] is Map ? Map<String, dynamic>.from(json['next_occurrence'] as Map) : null);
    final place = json['place'] as Map<String, dynamic>? ??
        (json['place'] is Map ? Map<String, dynamic>.from(json['place'] as Map) : null);
    final primaryTaxonomy = json['primary_taxonomy'] as Map<String, dynamic>? ??
        (json['primary_taxonomy'] is Map ? Map<String, dynamic>.from(json['primary_taxonomy'] as Map) : null);

    return EventDetail(
      id: json['id']?.toString() ?? '',
      publicId: json['public_id']?.toString(),
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: json['image_url']?.toString(),
      editorialPriority: (json['editorial_priority'] as num?)?.toInt() ?? 0,
      recommendationsCount: (json['recommendations_count'] as num?)?.toInt() ?? 0,
      isNew: json['is_new'] == true,
      isRecommendedByMe: json['is_recommended_by_me'] == true,
      isFollowedByMe: json['is_followed_by_me'] == true,
      primaryTaxonomyName: primaryTaxonomy?['name']?.toString(),
      priceLabel: priceBadge?['label']?.toString() ?? (json['price_label']?.toString() ?? ''),
      priceDetails: priceBadge?['details']?.toString(),
      isFree: priceBadge?['type'] == 'free' || json['is_free'] == true,
      ticketUrl: json['ticket_url']?.toString(),
      websiteUrl: json['website_url']?.toString(),
      startsOn: occurrence?['starts_on']?.toString() ?? json['starts_on']?.toString() ?? '',
      startsAt: occurrence?['starts_at']?.toString() ?? json['starts_at']?.toString(),
      endsOn: occurrence?['ends_on']?.toString() ?? json['ends_on']?.toString(),
      endsAt: occurrence?['ends_at']?.toString() ?? json['ends_at']?.toString(),
      placeId: place?['id']?.toString() ?? json['place_id']?.toString(),
      placeTitle: place?['title']?.toString() ?? json['place_title']?.toString(),
      placeCity: place?['city']?.toString() ?? json['place_city']?.toString(),
      placeAddress: place?['address']?.toString(),
      placeLatitude: place?['latitude'] != null ? (place!['latitude'] as num).toDouble() : null,
      placeLongitude: place?['longitude'] != null ? (place!['longitude'] as num).toDouble() : null,
      placePrimaryImageUrl: place?['primary_image_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'public_id': publicId,
      'slug': slug,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'editorial_priority': editorialPriority,
      'recommendations_count': recommendationsCount,
      'is_new': isNew,
      'is_recommended_by_me': isRecommendedByMe,
      'is_followed_by_me': isFollowedByMe,
      'ticket_url': ticketUrl,
      'website_url': websiteUrl,
      'price_badge': {
        'label': priceLabel,
        'type': isFree ? 'free' : 'paid',
        'details': priceDetails,
      },
      'next_occurrence': {
        'starts_on': startsOn,
        'starts_at': startsAt,
        'ends_on': endsOn,
        'ends_at': endsAt,
      },
      'primary_taxonomy': primaryTaxonomyName != null ? {'name': primaryTaxonomyName} : null,
      'place': placeId != null
          ? {
              'id': placeId,
              'title': placeTitle,
              'city': placeCity,
              'address': placeAddress,
              'latitude': placeLatitude,
              'longitude': placeLongitude,
              'primary_image_url': placePrimaryImageUrl,
            }
          : null,
    };
  }

  EventDetail copyWith({
    String? id,
    String? publicId,
    String? slug,
    String? title,
    String? description,
    String? imageUrl,
    int? editorialPriority,
    int? recommendationsCount,
    bool? isNew,
    bool? isRecommendedByMe,
    bool? isFollowedByMe,
    String? primaryTaxonomyName,
    String? priceLabel,
    String? priceDetails,
    bool? isFree,
    String? ticketUrl,
    String? websiteUrl,
    String? startsOn,
    String? startsAt,
    String? endsOn,
    String? endsAt,
    String? placeId,
    String? placeTitle,
    String? placeCity,
    String? placeAddress,
    double? placeLatitude,
    double? placeLongitude,
    String? placePrimaryImageUrl,
  }) {
    return EventDetail(
      id: id ?? this.id,
      publicId: publicId ?? this.publicId,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      editorialPriority: editorialPriority ?? this.editorialPriority,
      recommendationsCount: recommendationsCount ?? this.recommendationsCount,
      isNew: isNew ?? this.isNew,
      isRecommendedByMe: isRecommendedByMe ?? this.isRecommendedByMe,
      isFollowedByMe: isFollowedByMe ?? this.isFollowedByMe,
      primaryTaxonomyName: primaryTaxonomyName ?? this.primaryTaxonomyName,
      priceLabel: priceLabel ?? this.priceLabel,
      priceDetails: priceDetails ?? this.priceDetails,
      isFree: isFree ?? this.isFree,
      ticketUrl: ticketUrl ?? this.ticketUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      startsOn: startsOn ?? this.startsOn,
      startsAt: startsAt ?? this.startsAt,
      endsOn: endsOn ?? this.endsOn,
      endsAt: endsAt ?? this.endsAt,
      placeId: placeId ?? this.placeId,
      placeTitle: placeTitle ?? this.placeTitle,
      placeCity: placeCity ?? this.placeCity,
      placeAddress: placeAddress ?? this.placeAddress,
      placeLatitude: placeLatitude ?? this.placeLatitude,
      placeLongitude: placeLongitude ?? this.placeLongitude,
      placePrimaryImageUrl: placePrimaryImageUrl ?? this.placePrimaryImageUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        publicId,
        slug,
        title,
        description,
        imageUrl,
        editorialPriority,
        recommendationsCount,
        isNew,
        isRecommendedByMe,
        isFollowedByMe,
        primaryTaxonomyName,
        priceLabel,
        priceDetails,
        isFree,
        ticketUrl,
        websiteUrl,
        startsOn,
        startsAt,
        endsOn,
        endsAt,
        placeId,
        placeTitle,
        placeCity,
        placeAddress,
        placeLatitude,
        placeLongitude,
        placePrimaryImageUrl,
      ];
}

