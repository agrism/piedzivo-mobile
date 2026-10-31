import 'package:flutter_bloc/flutter_bloc.dart';
import '../../events/models/event_list_item.dart';
import '../models/followed_place_item.dart';
import '../repositories/following_repository.dart';
import 'following_event.dart';
import 'following_state.dart';

class FollowingBloc extends Bloc<FollowingEvent, FollowingState> {
  final FollowingRepository repository;

  FollowingBloc({
    required this.repository,
    FollowingState? initialState,
  }) : super(initialState ?? const FollowingState()) {
    on<FollowingLoadRequested>(_onLoadRequested);
    on<FollowingRefreshRequested>(_onRefreshRequested);
    on<FollowingTabChanged>(_onTabChanged);
    on<FollowingPlaceMarkViewed>(_onPlaceMarkViewed);
  }

  Future<void> _onLoadRequested(
    FollowingLoadRequested event,
    Emitter<FollowingState> emit,
  ) async {
    emit(state.copyWith(status: FollowingStatus.loading, clearError: true));

    try {
      final results = await Future.wait([
        repository.getFollowedEvents(),
        repository.getFollowedPlaces(),
      ]);

      final events = List<EventListItem>.from(results[0] as List);
      final places = List<FollowedPlaceItem>.from(results[1] as List);

      // Sort events chronologically by startsOn and startsAt
      events.sort((a, b) {
        final cmpDate = a.startsOn.compareTo(b.startsOn);
        if (cmpDate != 0) return cmpDate;
        final aTime = a.startsAt ?? '';
        final bTime = b.startsAt ?? '';
        return aTime.compareTo(bTime);
      });

      emit(state.copyWith(
        status: FollowingStatus.success,
        events: events,
        places: places,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FollowingStatus.failure,
        errorMessage: 'Neizdevās ielādēt sekoto saturu: $e',
      ));
    }
  }

  Future<void> _onRefreshRequested(
    FollowingRefreshRequested event,
    Emitter<FollowingState> emit,
  ) async {
    try {
      final results = await Future.wait([
        repository.getFollowedEvents(),
        repository.getFollowedPlaces(),
      ]);

      final events = List<EventListItem>.from(results[0] as List);
      final places = List<FollowedPlaceItem>.from(results[1] as List);

      events.sort((a, b) {
        final cmpDate = a.startsOn.compareTo(b.startsOn);
        if (cmpDate != 0) return cmpDate;
        final aTime = a.startsAt ?? '';
        final bTime = b.startsAt ?? '';
        return aTime.compareTo(bTime);
      });

      emit(state.copyWith(
        status: FollowingStatus.success,
        events: events,
        places: places,
      ));
    } catch (_) {
      // Keep existing state on pull-to-refresh failure
    }
  }

  void _onTabChanged(
    FollowingTabChanged event,
    Emitter<FollowingState> emit,
  ) {
    emit(state.copyWith(selectedTab: event.tab));
  }

  Future<void> _onPlaceMarkViewed(
    FollowingPlaceMarkViewed event,
    Emitter<FollowingState> emit,
  ) async {
    final updatedPlaces = state.places.map((item) {
      if (item.place.id == event.placeId) {
        return item.copyWith(unreadEventsCount: 0);
      }
      return item;
    }).toList();

    emit(state.copyWith(places: updatedPlaces));

    // Call API in background
    await repository.markPlaceViewed(event.placeId);
  }
}
