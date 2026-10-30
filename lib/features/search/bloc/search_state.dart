import 'package:equatable/equatable.dart';
import '../../events/models/event_list_item.dart';
import '../../places/models/place_list_item.dart';

enum SearchStatus { initial, loading, success, failure }

enum SearchTab { all, events, places }

class SearchState extends Equatable {
  final SearchStatus status;
  final String query;
  final bool isLatviaWide;
  final String? placeId;
  final List<EventListItem> events;
  final List<PlaceListItem> places;
  final SearchTab selectedTab;
  final String? errorMessage;

  const SearchState({
    this.status = SearchStatus.initial,
    this.query = '',
    this.isLatviaWide = false,
    this.placeId,
    this.events = const [],
    this.places = const [],
    this.selectedTab = SearchTab.all,
    this.errorMessage,
  });

  int get totalCount => events.length + places.length;
  bool get isEmpty => query.trim().isNotEmpty && totalCount == 0 && status == SearchStatus.success;

  SearchState copyWith({
    SearchStatus? status,
    String? query,
    bool? isLatviaWide,
    String? placeId,
    List<EventListItem>? events,
    List<PlaceListItem>? places,
    SearchTab? selectedTab,
    String? errorMessage,
  }) {
    return SearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      isLatviaWide: isLatviaWide ?? this.isLatviaWide,
      placeId: placeId ?? this.placeId,
      events: events ?? this.events,
      places: places ?? this.places,
      selectedTab: selectedTab ?? this.selectedTab,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        query,
        isLatviaWide,
        placeId,
        events,
        places,
        selectedTab,
        errorMessage,
      ];
}
