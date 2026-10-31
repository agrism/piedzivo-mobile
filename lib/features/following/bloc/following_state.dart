import 'package:equatable/equatable.dart';
import '../../events/models/event_list_item.dart';
import '../../events/utils/event_date_formatter.dart';
import '../models/followed_place_item.dart';
import 'following_event.dart';

enum FollowingStatus {
  initial,
  loading,
  success,
  failure,
}

class FollowingState extends Equatable {
  final FollowingStatus status;
  final FollowingTab selectedTab;
  final List<EventListItem> events;
  final List<FollowedPlaceItem> places;
  final String? errorMessage;

  const FollowingState({
    this.status = FollowingStatus.initial,
    this.selectedTab = FollowingTab.events,
    this.events = const [],
    this.places = const [],
    this.errorMessage,
  });

  int get totalUnreadPlacesCount => places.where((p) => p.hasUnread).length;

  int get totalUnreadEventsCount =>
      places.fold<int>(0, (sum, p) => sum + p.unreadEventsCount);

  Map<String, List<EventListItem>> get groupedEvents =>
      EventDateFormatter.groupEventsByDay(events);

  FollowingState copyWith({
    FollowingStatus? status,
    FollowingTab? selectedTab,
    List<EventListItem>? events,
    List<FollowedPlaceItem>? places,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FollowingState(
      status: status ?? this.status,
      selectedTab: selectedTab ?? this.selectedTab,
      events: events ?? this.events,
      places: places ?? this.places,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        selectedTab,
        events,
        places,
        errorMessage,
      ];
}
