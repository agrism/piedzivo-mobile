import 'package:equatable/equatable.dart';
import '../../events/models/event_list_item.dart';

class PlaceDaySchedule extends Equatable {
  final String dayName;
  final String hours;
  final bool isClosed;
  final bool isToday;

  const PlaceDaySchedule({
    required this.dayName,
    required this.hours,
    this.isClosed = false,
    this.isToday = false,
  });

  factory PlaceDaySchedule.fromJson(Map<String, dynamic> json) {
    return PlaceDaySchedule(
      dayName: json['day_name']?.toString() ?? json['day']?.toString() ?? '',
      hours: json['hours']?.toString() ?? (json['is_closed'] == true ? 'Slēgts' : ''),
      isClosed: json['is_closed'] == true || json['hours'] == 'Slēgts',
      isToday: json['is_today'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day_name': dayName,
      'hours': hours,
      'is_closed': isClosed,
      'is_today': isToday,
    };
  }

  @override
  List<Object?> get props => [dayName, hours, isClosed, isToday];
}

class PlaceDetail extends Equatable {
  final String id;
  final String? publicId;
  final String slug;
  final String title;
  final String? description;
  final String city;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? email;
  final String? websiteUrl;
  final String? primaryImageUrl;
  final List<String> images;
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
  final List<PlaceDaySchedule> weeklySchedule;
  final List<EventListItem> upcomingEvents;

  const PlaceDetail({
    required this.id,
    this.publicId,
    required this.slug,
    required this.title,
    this.description,
    required this.city,
    this.address,
    this.latitude,
    this.longitude,
    this.phone,
    this.email,
    this.websiteUrl,
    this.primaryImageUrl,
    required this.images,
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
    required this.weeklySchedule,
    required this.upcomingEvents,
  });

  factory PlaceDetail.fromJson(Map<String, dynamic> json) {
    // Apstrādājam iespējamo { "data": { ... } } iesaiņojumu
    final raw = (json.containsKey('data') && json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : (json.containsKey('data') && json['data'] is Map)
            ? Map<String, dynamic>.from(json['data'] as Map)
            : json;

    final openingStatus = raw['opening_status'] as Map<String, dynamic>? ??
        (raw['opening_status'] is Map
            ? Map<String, dynamic>.from(raw['opening_status'] as Map)
            : null);

    // Attēlu saraksta parsēšana
    final List<String> parsedImages = [];
    final rawImages = raw['images'];
    if (rawImages is List) {
      for (final img in rawImages) {
        if (img is String && img.isNotEmpty) {
          parsedImages.add(img);
        } else if (img is Map && img['url'] != null) {
          parsedImages.add(img['url'].toString());
        }
      }
    }
    final primaryImg = raw['primary_image_url']?.toString();
    if (parsedImages.isEmpty && primaryImg != null && primaryImg.isNotEmpty) {
      parsedImages.add(primaryImg);
    }

    // Nedēļas darba laika parsēšana
    final List<PlaceDaySchedule> parsedSchedule = [];
    final rawSchedule = raw['weekly_schedule'] ?? raw['opening_hours'];
    if (rawSchedule is List) {
      for (final item in rawSchedule) {
        if (item is Map<String, dynamic>) {
          parsedSchedule.add(PlaceDaySchedule.fromJson(item));
        } else if (item is Map) {
          parsedSchedule.add(PlaceDaySchedule.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    } else if (rawSchedule is Map) {
      final daysMap = {
        'monday': 'Pirmdiena',
        'tuesday': 'Otrdiena',
        'wednesday': 'Trešdiena',
        'thursday': 'Ceturtdiena',
        'friday': 'Piektdiena',
        'saturday': 'Sestdiena',
        'sunday': 'Svētdiena',
      };
      daysMap.forEach((key, latvianName) {
        if (rawSchedule.containsKey(key)) {
          final val = rawSchedule[key]?.toString() ?? '';
          parsedSchedule.add(PlaceDaySchedule(
            dayName: latvianName,
            hours: val.isEmpty ? 'Slēgts' : val,
            isClosed: val.isEmpty || val.toLowerCase() == 'slēgts' || val.toLowerCase() == 'closed',
          ));
        }
      });
    }

    // Gaidāmo pasākumu parsēšana
    final List<EventListItem> parsedEvents = [];
    final rawUpcoming = raw['upcoming_events'];
    if (rawUpcoming is List) {
      for (final e in rawUpcoming) {
        if (e is Map<String, dynamic>) {
          parsedEvents.add(EventListItem.fromJson(e));
        } else if (e is Map) {
          parsedEvents.add(EventListItem.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    return PlaceDetail(
      id: raw['id']?.toString() ?? '',
      publicId: raw['public_id']?.toString(),
      slug: raw['slug']?.toString() ?? '',
      title: raw['title']?.toString() ?? '',
      description: raw['description']?.toString() ?? raw['content']?.toString() ?? raw['short_description']?.toString(),
      city: raw['city']?.toString() ?? '',
      address: raw['address']?.toString(),
      latitude: raw['latitude'] != null ? (raw['latitude'] as num).toDouble() : null,
      longitude: raw['longitude'] != null ? (raw['longitude'] as num).toDouble() : null,
      phone: raw['phone']?.toString(),
      email: raw['email']?.toString(),
      websiteUrl: raw['website_url']?.toString() ?? raw['website']?.toString(),
      primaryImageUrl: primaryImg,
      images: parsedImages,
      editorialPriority: raw['editorial_priority'] != null ? (raw['editorial_priority'] as num).toInt() : 0,
      recommendationsCount: raw['recommendations_count'] != null ? (raw['recommendations_count'] as num).toInt() : 0,
      upcomingEventsCount: raw['upcoming_events_count'] != null
          ? (raw['upcoming_events_count'] as num).toInt()
          : parsedEvents.length,
      isNew: raw['is_new'] == true,
      isRecommendedByMe: raw['is_recommended_by_me'] == true,
      isFollowedByMe: raw['is_followed_by_me'] == true,
      isOpen: openingStatus?['is_open'] == true,
      openingLabel: openingStatus?['label']?.toString() ?? '',
      rootCategoryName: raw['root_category']?['name']?.toString(),
      primaryTaxonomyName: raw['primary_taxonomy']?['name']?.toString(),
      weeklySchedule: parsedSchedule,
      upcomingEvents: parsedEvents,
    );
  }

  PlaceDetail copyWith({
    String? id,
    String? publicId,
    String? slug,
    String? title,
    String? description,
    String? city,
    String? address,
    double? latitude,
    double? longitude,
    String? phone,
    String? email,
    String? websiteUrl,
    String? primaryImageUrl,
    List<String>? images,
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
    List<PlaceDaySchedule>? weeklySchedule,
    List<EventListItem>? upcomingEvents,
  }) {
    return PlaceDetail(
      id: id ?? this.id,
      publicId: publicId ?? this.publicId,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      description: description ?? this.description,
      city: city ?? this.city,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      primaryImageUrl: primaryImageUrl ?? this.primaryImageUrl,
      images: images ?? this.images,
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
      weeklySchedule: weeklySchedule ?? this.weeklySchedule,
      upcomingEvents: upcomingEvents ?? this.upcomingEvents,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'public_id': publicId,
      'slug': slug,
      'title': title,
      'description': description,
      'city': city,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'email': email,
      'website_url': websiteUrl,
      'primary_image_url': primaryImageUrl,
      'images': images,
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
      'weekly_schedule': weeklySchedule.map((s) => s.toJson()).toList(),
      'upcoming_events': upcomingEvents.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        publicId,
        slug,
        title,
        description,
        city,
        address,
        latitude,
        longitude,
        phone,
        email,
        websiteUrl,
        primaryImageUrl,
        images,
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
        weeklySchedule,
        upcomingEvents,
      ];
}

