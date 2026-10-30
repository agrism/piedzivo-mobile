import 'package:equatable/equatable.dart';
import '../models/place_list_item.dart';

abstract class PlacesState extends Equatable {
  const PlacesState();

  @override
  List<Object?> get props => [];
}

class PlacesInitial extends PlacesState {}

class PlacesLoading extends PlacesState {}

class PlacesLoaded extends PlacesState {
  final List<PlaceListItem> allPlaces;
  final List<PlaceListItem> filteredPlaces;
  final String? selectedCategory;
  final String? currentPlaceId;
  final Map<String, List<PlaceListItem>> groupedPlaces;

  PlacesLoaded({
    required this.allPlaces,
    required this.filteredPlaces,
    this.selectedCategory,
    this.currentPlaceId,
    Map<String, List<PlaceListItem>>? groupedPlaces,
  }) : groupedPlaces = groupedPlaces ?? groupPlacesByCategory(filteredPlaces);

  static int comparePlacesByRank(PlaceListItem a, PlaceListItem b) {
    final epComp = b.editorialPriority.compareTo(a.editorialPriority);
    if (epComp != 0) return epComp;

    final rcComp = b.recommendationsCount.compareTo(a.recommendationsCount);
    if (rcComp != 0) return rcComp;

    final uecComp = b.upcomingEventsCount.compareTo(a.upcomingEventsCount);
    if (uecComp != 0) return uecComp;

    return a.title.compareTo(b.title);
  }

  static Map<String, List<PlaceListItem>> groupPlacesByCategory(List<PlaceListItem> places) {
    final sorted = List<PlaceListItem>.from(places)..sort(comparePlacesByRank);
    final Map<String, List<PlaceListItem>> grouped = {};

    for (final place in sorted) {
      final category = place.rootCategoryName ?? place.primaryTaxonomyName ?? 'Citi apskates objekti';
      grouped.putIfAbsent(category, () => []).add(place);
    }

    return grouped;
  }

  PlacesLoaded copyWith({
    List<PlaceListItem>? allPlaces,
    List<PlaceListItem>? filteredPlaces,
    String? selectedCategory,
    bool clearCategory = false,
    String? currentPlaceId,
  }) {
    final newCategory = clearCategory ? null : (selectedCategory ?? this.selectedCategory);
    final newAll = allPlaces ?? this.allPlaces;

    final newFiltered = filteredPlaces ??
        newAll.where((p) {
          if (newCategory != null) {
            final category = p.rootCategoryName ?? p.primaryTaxonomyName;
            if (category != newCategory) return false;
          }
          return true;
        }).toList();

    return PlacesLoaded(
      allPlaces: newAll,
      filteredPlaces: newFiltered,
      selectedCategory: newCategory,
      currentPlaceId: currentPlaceId ?? this.currentPlaceId,
    );
  }

  @override
  List<Object?> get props => [
        allPlaces,
        filteredPlaces,
        selectedCategory,
        currentPlaceId,
        groupedPlaces,
      ];
}

class PlacesError extends PlacesState {
  final String message;

  const PlacesError(this.message);

  @override
  List<Object?> get props => [message];
}

