import 'package:equatable/equatable.dart';
import '../models/event_list_item.dart';
import '../utils/event_date_formatter.dart';

abstract class EventsState extends Equatable {
  const EventsState();

  @override
  List<Object?> get props => [];
}

class EventsInitial extends EventsState {}

class EventsLoading extends EventsState {}

class EventsLoaded extends EventsState {
  final List<EventListItem> allEvents;
  final List<EventListItem> filteredEvents;
  final String? selectedCategory;
  final bool isFreeOnly;
  final String? currentPlaceId;
  final Map<String, List<EventListItem>> groupedEvents;

  EventsLoaded({
    required this.allEvents,
    required this.filteredEvents,
    this.selectedCategory,
    this.isFreeOnly = false,
    this.currentPlaceId,
    Map<String, List<EventListItem>>? groupedEvents,
  }) : groupedEvents = groupedEvents ?? EventDateFormatter.groupEventsByDay(filteredEvents);

  EventsLoaded copyWith({
    List<EventListItem>? allEvents,
    List<EventListItem>? filteredEvents,
    String? selectedCategory,
    bool clearCategory = false,
    bool? isFreeOnly,
    String? currentPlaceId,
  }) {
    final newCategory = clearCategory ? null : (selectedCategory ?? this.selectedCategory);
    final newFree = isFreeOnly ?? this.isFreeOnly;
    final newAll = allEvents ?? this.allEvents;

    final newFiltered = filteredEvents ??
        newAll.where((e) {
          if (newCategory != null && e.primaryTaxonomyName != newCategory) {
            return false;
          }
          if (newFree && !e.isFree) {
            return false;
          }
          return true;
        }).toList();

    return EventsLoaded(
      allEvents: newAll,
      filteredEvents: newFiltered,
      selectedCategory: newCategory,
      isFreeOnly: newFree,
      currentPlaceId: currentPlaceId ?? this.currentPlaceId,
    );
  }

  @override
  List<Object?> get props => [
        allEvents,
        filteredEvents,
        selectedCategory,
        isFreeOnly,
        currentPlaceId,
        groupedEvents,
      ];
}

class EventsError extends EventsState {
  final String message;

  const EventsError(this.message);

  @override
  List<Object?> get props => [message];
}

