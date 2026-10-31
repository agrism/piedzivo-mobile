import 'package:equatable/equatable.dart';
import '../../places/models/place_list_item.dart';

class FollowedPlaceItem extends Equatable {
  final PlaceListItem place;
  final int unreadEventsCount;

  const FollowedPlaceItem({
    required this.place,
    this.unreadEventsCount = 0,
  });

  bool get hasUnread => unreadEventsCount > 0;

  FollowedPlaceItem copyWith({
    PlaceListItem? place,
    int? unreadEventsCount,
  }) {
    return FollowedPlaceItem(
      place: place ?? this.place,
      unreadEventsCount: unreadEventsCount ?? this.unreadEventsCount,
    );
  }

  factory FollowedPlaceItem.fromJson(Map<String, dynamic> json) {
    final placeJson = json.containsKey('place') && json['place'] is Map<String, dynamic>
        ? json['place'] as Map<String, dynamic>
        : json;
    final unread = json['unread_events_count'] ??
        json['new_events_count'] ??
        placeJson['unread_events_count'] ??
        placeJson['new_events_count'] ??
        0;

    return FollowedPlaceItem(
      place: PlaceListItem.fromJson(placeJson),
      unreadEventsCount: (unread as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'place': place.toJson(),
      'unread_events_count': unreadEventsCount,
    };
  }

  @override
  List<Object?> get props => [place, unreadEventsCount];
}
