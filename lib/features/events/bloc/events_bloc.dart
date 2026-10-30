import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/events_repository.dart';
import 'events_event.dart';
import 'events_state.dart';

class EventsBloc extends Bloc<EventsEvent, EventsState> {
  final EventsRepository repository;

  EventsBloc({required this.repository}) : super(EventsInitial()) {
    on<LoadEvents>(_onLoadEvents);
    on<FilterEvents>(_onFilterEvents);
    on<ToggleRecommendEvent>(_onToggleRecommend);
    on<ToggleFollowEvent>(_onToggleFollow);
  }

  Future<void> _onLoadEvents(LoadEvents event, Emitter<EventsState> emit) async {
    emit(EventsLoading());
    try {
      final events = await repository.getEvents(placeId: event.placeId);
      emit(EventsLoaded(
        allEvents: events,
        filteredEvents: events,
        currentPlaceId: event.placeId,
      ));
    } catch (e) {
      emit(EventsError('Neizdevās ielādēt pasākumus: $e'));
    }
  }

  void _onFilterEvents(FilterEvents event, Emitter<EventsState> emit) {
    final currentState = state;
    if (currentState is! EventsLoaded) return;

    final newCategory = event.category;
    final newFree = event.isFreeOnly ?? currentState.isFreeOnly;

    final filtered = currentState.allEvents.where((e) {
      if (newCategory != null && e.primaryTaxonomyName != newCategory) {
        return false;
      }
      if (newFree && !e.isFree) {
        return false;
      }
      return true;
    }).toList();

    emit(EventsLoaded(
      allEvents: currentState.allEvents,
      filteredEvents: filtered,
      selectedCategory: newCategory,
      isFreeOnly: newFree,
      currentPlaceId: currentState.currentPlaceId,
    ));
  }

  Future<void> _onToggleRecommend(ToggleRecommendEvent event, Emitter<EventsState> emit) async {
    final currentState = state;
    if (currentState is! EventsLoaded) return;

    final updatedAll = currentState.allEvents.map((e) {
      if (e.id == event.eventId) {
        final willRecommend = !e.isRecommendedByMe;
        return e.copyWith(
          isRecommendedByMe: willRecommend,
          recommendationsCount: willRecommend
              ? e.recommendationsCount + 1
              : (e.recommendationsCount > 0 ? e.recommendationsCount - 1 : 0),
        );
      }
      return e;
    }).toList();

    final updatedFiltered = currentState.filteredEvents.map((e) {
      if (e.id == event.eventId) {
        final willRecommend = !e.isRecommendedByMe;
        return e.copyWith(
          isRecommendedByMe: willRecommend,
          recommendationsCount: willRecommend
              ? e.recommendationsCount + 1
              : (e.recommendationsCount > 0 ? e.recommendationsCount - 1 : 0),
        );
      }
      return e;
    }).toList();

    emit(EventsLoaded(
      allEvents: updatedAll,
      filteredEvents: updatedFiltered,
      selectedCategory: currentState.selectedCategory,
      isFreeOnly: currentState.isFreeOnly,
      currentPlaceId: currentState.currentPlaceId,
    ));

    await repository.toggleRecommend(event.eventId);
  }

  Future<void> _onToggleFollow(ToggleFollowEvent event, Emitter<EventsState> emit) async {
    final currentState = state;
    if (currentState is! EventsLoaded) return;

    final updatedAll = currentState.allEvents.map((e) {
      if (e.id == event.eventId) {
        return e.copyWith(isFollowedByMe: !e.isFollowedByMe);
      }
      return e;
    }).toList();

    final updatedFiltered = currentState.filteredEvents.map((e) {
      if (e.id == event.eventId) {
        return e.copyWith(isFollowedByMe: !e.isFollowedByMe);
      }
      return e;
    }).toList();

    emit(EventsLoaded(
      allEvents: updatedAll,
      filteredEvents: updatedFiltered,
      selectedCategory: currentState.selectedCategory,
      isFreeOnly: currentState.isFreeOnly,
      currentPlaceId: currentState.currentPlaceId,
    ));

    await repository.toggleFollow(event.eventId);
  }
}
