import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/events/screens/events_list_screen.dart';
import '../../features/events/screens/event_detail_screen.dart';
import '../../features/places/screens/places_list_screen.dart';
import '../../features/places/screens/place_detail_screen.dart';
import '../../features/places/screens/fullscreen_map_screen.dart';
import '../../features/following/screens/following_screen.dart';
import '../../features/search/screens/search_screen.dart';
import 'main_scaffold.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter({
  GlobalKey<NavigatorState>? navigatorKey,
  String initialLocation = '/events',
}) {
  final navKey = navigatorKey ?? rootNavigatorKey;

  return GoRouter(
    navigatorKey: navKey,
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          // 1. Zars: Pasākumi
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/events',
                builder: (context, state) => const EventsListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => EventDetailScreen(
                      eventId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. Zars: Vietas
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/places',
                builder: (context, state) => const PlacesListScreen(),
                routes: [
                  GoRoute(
                    path: 'map',
                    builder: (context, state) => const FullscreenMapScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => PlaceDetailScreen(
                      placeId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 3. Zars: Sekotie
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/following',
                builder: (context, state) => const FollowingScreen(),
              ),
            ],
          ),
        ],
      ),

      // Globālie modālie maršruti
      GoRoute(
        parentNavigatorKey: navKey,
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
    ],
  );
}

final appRouter = createAppRouter();

