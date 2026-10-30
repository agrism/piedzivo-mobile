import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/places_repository.dart';
import 'places_event.dart';
import 'places_state.dart';

class PlacesBloc extends Bloc<PlacesEvent, PlacesState> {
  final PlacesRepository repository;

  PlacesBloc({required this.repository}) : super(PlacesInitial()) {
    on<LoadPlaces>(_onLoadPlaces);
    on<FilterPlaces>(_onFilterPlaces);
    on<ToggleRecommendPlace>(_onToggleRecommend);
    on<ToggleFollowPlace>(_onToggleFollow);
  }

  Future<void> _onLoadPlaces(LoadPlaces event, Emitter<PlacesState> emit) async {
    emit(PlacesLoading());
    try {
      final places = await repository.getPlaces(placeId: event.placeId);
      emit(PlacesLoaded(
        allPlaces: places,
        filteredPlaces: places,
        currentPlaceId: event.placeId,
      ));
    } catch (e) {
      emit(PlacesError('Neizdevās ielādēt vietas: $e'));
    }
  }

  void _onFilterPlaces(FilterPlaces event, Emitter<PlacesState> emit) {
    final currentState = state;
    if (currentState is! PlacesLoaded) return;

    final newCategory = event.category;

    final filtered = currentState.allPlaces.where((p) {
      if (newCategory != null) {
        final category = p.rootCategoryName ?? p.primaryTaxonomyName;
        if (category != newCategory) return false;
      }
      return true;
    }).toList();

    emit(PlacesLoaded(
      allPlaces: currentState.allPlaces,
      filteredPlaces: filtered,
      selectedCategory: newCategory,
      currentPlaceId: currentState.currentPlaceId,
    ));
  }

  Future<void> _onToggleRecommend(ToggleRecommendPlace event, Emitter<PlacesState> emit) async {
    final currentState = state;
    if (currentState is! PlacesLoaded) return;

    final updatedAll = currentState.allPlaces.map((p) {
      if (p.id == event.placeId) {
        final wasRecommended = p.isRecommendedByMe;
        final newCount = wasRecommended
            ? (p.recommendationsCount > 0 ? p.recommendationsCount - 1 : 0)
            : p.recommendationsCount + 1;
        return p.copyWith(
          isRecommendedByMe: !wasRecommended,
          recommendationsCount: newCount,
        );
      }
      return p;
    }).toList();

    final updatedFiltered = currentState.filteredPlaces.map((p) {
      if (p.id == event.placeId) {
        final wasRecommended = p.isRecommendedByMe;
        final newCount = wasRecommended
            ? (p.recommendationsCount > 0 ? p.recommendationsCount - 1 : 0)
            : p.recommendationsCount + 1;
        return p.copyWith(
          isRecommendedByMe: !wasRecommended,
          recommendationsCount: newCount,
        );
      }
      return p;
    }).toList();

    emit(PlacesLoaded(
      allPlaces: updatedAll,
      filteredPlaces: updatedFiltered,
      selectedCategory: currentState.selectedCategory,
      currentPlaceId: currentState.currentPlaceId,
    ));

    // Async server sync
    final success = await repository.toggleRecommend(event.placeId);
    if (!success) {
      // Revert if server call failed
      final revertedState = state;
      if (revertedState is PlacesLoaded) {
        emit(PlacesLoaded(
          allPlaces: currentState.allPlaces,
          filteredPlaces: currentState.filteredPlaces,
          selectedCategory: currentState.selectedCategory,
          currentPlaceId: currentState.currentPlaceId,
        ));
      }
    }
  }

  Future<void> _onToggleFollow(ToggleFollowPlace event, Emitter<PlacesState> emit) async {
    final currentState = state;
    if (currentState is! PlacesLoaded) return;

    final updatedAll = currentState.allPlaces.map((p) {
      if (p.id == event.placeId) {
        return p.copyWith(isFollowedByMe: !p.isFollowedByMe);
      }
      return p;
    }).toList();

    final updatedFiltered = currentState.filteredPlaces.map((p) {
      if (p.id == event.placeId) {
        return p.copyWith(isFollowedByMe: !p.isFollowedByMe);
      }
      return p;
    }).toList();

    emit(PlacesLoaded(
      allPlaces: updatedAll,
      filteredPlaces: updatedFiltered,
      selectedCategory: currentState.selectedCategory,
      currentPlaceId: currentState.currentPlaceId,
    ));

    final success = await repository.toggleFollow(event.placeId);
    if (!success) {
      final revertedState = state;
      if (revertedState is PlacesLoaded) {
        emit(PlacesLoaded(
          allPlaces: currentState.allPlaces,
          filteredPlaces: currentState.filteredPlaces,
          selectedCategory: currentState.selectedCategory,
          currentPlaceId: currentState.currentPlaceId,
        ));
      }
    }
  }
}

