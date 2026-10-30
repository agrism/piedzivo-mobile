import 'package:equatable/equatable.dart';

abstract class PlacesEvent extends Equatable {
  const PlacesEvent();

  @override
  List<Object?> get props => [];
}

class LoadPlaces extends PlacesEvent {
  final String? placeId;
  final bool forceRefresh;

  const LoadPlaces({this.placeId, this.forceRefresh = false});

  @override
  List<Object?> get props => [placeId, forceRefresh];
}

class FilterPlaces extends PlacesEvent {
  final String? category;

  const FilterPlaces({this.category});

  @override
  List<Object?> get props => [category];
}

class ToggleRecommendPlace extends PlacesEvent {
  final String placeId;

  const ToggleRecommendPlace(this.placeId);

  @override
  List<Object?> get props => [placeId];
}

class ToggleFollowPlace extends PlacesEvent {
  final String placeId;

  const ToggleFollowPlace(this.placeId);

  @override
  List<Object?> get props => [placeId];
}

