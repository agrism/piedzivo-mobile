import 'package:flutter_bloc/flutter_bloc.dart';
import '../../events/models/event_list_item.dart';
import '../../events/repositories/events_repository.dart';
import '../../places/models/place_list_item.dart';
import '../../places/repositories/places_repository.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final EventsRepository eventsRepository;
  final PlacesRepository placesRepository;

  SearchBloc({
    required this.eventsRepository,
    required this.placesRepository,
  }) : super(const SearchState()) {
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<SearchScopeChanged>(_onSearchScopeChanged);
    on<SearchTabChanged>(_onSearchTabChanged);
    on<SearchClear>(_onSearchClear);
  }

  Future<void> _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(state.copyWith(
        status: SearchStatus.initial,
        query: '',
        events: const [],
        places: const [],
      ));
      return;
    }

    final isLatviaWide = event.isLatviaWide ?? state.isLatviaWide;
    final placeId = event.placeId ?? state.placeId;

    emit(state.copyWith(
      status: SearchStatus.loading,
      query: query,
      isLatviaWide: isLatviaWide,
      placeId: placeId,
    ));

    try {
      final effectivePlaceId = isLatviaWide ? null : placeId;

      final results = await Future.wait([
        eventsRepository.getEvents(
          search: query,
          placeId: effectivePlaceId,
        ),
        placesRepository.getPlaces(
          search: query,
          placeId: effectivePlaceId,
        ),
      ]);

      final events = results[0] as List<EventListItem>;
      final places = results[1] as List<PlaceListItem>;

      emit(state.copyWith(
        status: SearchStatus.success,
        events: events,
        places: places,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SearchStatus.failure,
        errorMessage: 'Meklēšanas kļūda: $e',
      ));
    }
  }

  Future<void> _onSearchScopeChanged(
    SearchScopeChanged event,
    Emitter<SearchState> emit,
  ) async {
    final query = state.query.trim();
    if (query.isEmpty) {
      emit(state.copyWith(
        isLatviaWide: event.isLatviaWide,
        placeId: event.placeId ?? state.placeId,
      ));
      return;
    }

    add(SearchQueryChanged(
      query,
      isLatviaWide: event.isLatviaWide,
      placeId: event.placeId ?? state.placeId,
    ));
  }

  void _onSearchTabChanged(
    SearchTabChanged event,
    Emitter<SearchState> emit,
  ) {
    emit(state.copyWith(selectedTab: event.tab));
  }

  void _onSearchClear(
    SearchClear event,
    Emitter<SearchState> emit,
  ) {
    emit(state.copyWith(
      status: SearchStatus.initial,
      query: '',
      events: const [],
      places: const [],
    ));
  }
}
