import 'package:equatable/equatable.dart';

abstract class EventsEvent extends Equatable {
  const EventsEvent();

  @override
  List<Object?> get props => [];
}

class LoadEvents extends EventsEvent {
  final String? placeId;
  final bool forceRefresh;

  const LoadEvents({this.placeId, this.forceRefresh = false});

  @override
  List<Object?> get props => [placeId, forceRefresh];
}

class FilterEvents extends EventsEvent {
  final String? category;
  final bool? isFreeOnly;

  const FilterEvents({this.category, this.isFreeOnly});

  @override
  List<Object?> get props => [category, isFreeOnly];
}

class ToggleRecommendEvent extends EventsEvent {
  final String eventId;

  const ToggleRecommendEvent(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

class ToggleFollowEvent extends EventsEvent {
  final String eventId;

  const ToggleFollowEvent(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

