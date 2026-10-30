import 'package:equatable/equatable.dart';
import 'search_state.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

class SearchQueryChanged extends SearchEvent {
  final String query;
  final String? placeId;
  final bool? isLatviaWide;

  const SearchQueryChanged(
    this.query, {
    this.placeId,
    this.isLatviaWide,
  });

  @override
  List<Object?> get props => [query, placeId, isLatviaWide];
}

class SearchScopeChanged extends SearchEvent {
  final bool isLatviaWide;
  final String? placeId;

  const SearchScopeChanged({
    required this.isLatviaWide,
    this.placeId,
  });

  @override
  List<Object?> get props => [isLatviaWide, placeId];
}

class SearchTabChanged extends SearchEvent {
  final SearchTab tab;

  const SearchTabChanged(this.tab);

  @override
  List<Object?> get props => [tab];
}

class SearchClear extends SearchEvent {
  const SearchClear();
}
