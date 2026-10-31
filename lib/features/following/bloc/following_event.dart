import 'package:equatable/equatable.dart';

enum FollowingTab {
  events,
  places,
}

abstract class FollowingEvent extends Equatable {
  const FollowingEvent();

  @override
  List<Object?> get props => [];
}

class FollowingLoadRequested extends FollowingEvent {
  const FollowingLoadRequested();
}

class FollowingRefreshRequested extends FollowingEvent {
  const FollowingRefreshRequested();
}

class FollowingTabChanged extends FollowingEvent {
  final FollowingTab tab;

  const FollowingTabChanged(this.tab);

  @override
  List<Object?> get props => [tab];
}

class FollowingPlaceMarkViewed extends FollowingEvent {
  final String placeId;

  const FollowingPlaceMarkViewed(this.placeId);

  @override
  List<Object?> get props => [placeId];
}
