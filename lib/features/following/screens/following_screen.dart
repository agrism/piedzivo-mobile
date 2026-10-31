import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/widgets/auth_bottom_sheet.dart';
import '../../events/widgets/event_card.dart';
import '../bloc/following_bloc.dart';
import '../bloc/following_event.dart';
import '../bloc/following_state.dart';
import '../widgets/followed_place_card.dart';

class FollowingScreen extends StatefulWidget {
  const FollowingScreen({super.key});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState.status == AuthStatus.authenticated) {
      final followingState = context.read<FollowingBloc>().state;
      if (followingState.status == FollowingStatus.initial) {
        context.read<FollowingBloc>().add(const FollowingLoadRequested());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) =>
          prev.status != AuthStatus.authenticated &&
          curr.status == AuthStatus.authenticated,
      listener: (context, authState) {
        context.read<FollowingBloc>().add(const FollowingLoadRequested());
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState.status != AuthStatus.authenticated) {
            return _buildUnauthenticatedView(context);
          }

          return _buildAuthenticatedContent(context);
        },
      ),
    );
  }

  Widget _buildUnauthenticatedView(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryViolet.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 40,
                color: AppColors.primaryViolet,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tavi sekotie notikumi un vietas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Pieslēdzies savam profilam, lai sekotu līdzi sev interesējošo vietu un pasākumu jaunumiem vienuviet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                key: const Key('following_login_button'),
                onPressed: () => showAuthBottomSheet(context),
                icon: const Icon(Icons.login_rounded, size: 20),
                label: const Text(
                  'Ienākt profilā',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryViolet,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticatedContent(BuildContext context) {
    return BlocBuilder<FollowingBloc, FollowingState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          body: Column(
            children: [
              // Apakšcilņu pārslēdzējs (Segmented Tab Selector)
              _buildSubTabBar(context, state),

              // Apakšcilnes saturs
              Expanded(
                child: state.selectedTab == FollowingTab.events
                    ? _buildEventsTab(context, state)
                    : _buildPlacesTab(context, state),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubTabBar(BuildContext context, FollowingState state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.borderSubtle.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
      ),
      child: Row(
        children: [
          // 1. Apakšcilne: Mani Pasākumi
          Expanded(
            child: _buildSubTabButton(
              key: const Key('following_tab_events'),
              label: 'Mani Pasākumi',
              isSelected: state.selectedTab == FollowingTab.events,
              badgeCount: state.events.length,
              onTap: () {
                context.read<FollowingBloc>().add(
                      const FollowingTabChanged(FollowingTab.events),
                    );
              },
            ),
          ),
          const SizedBox(width: 4),

          // 2. Apakšcilne: Manas Vietas
          Expanded(
            child: _buildSubTabButton(
              key: const Key('following_tab_places'),
              label: 'Manas Vietas',
              isSelected: state.selectedTab == FollowingTab.places,
              badgeCount: state.places.length,
              unreadBadgeCount: state.totalUnreadPlacesCount,
              onTap: () {
                context.read<FollowingBloc>().add(
                      const FollowingTabChanged(FollowingTab.places),
                    );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabButton({
    required Key key,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int? badgeCount,
    int? unreadBadgeCount,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(AppDimensions.radiusButton - 2),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.cardWhite : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusButton - 2),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? AppColors.primaryNavy : AppColors.textSecondary,
                ),
              ),
              if (unreadBadgeCount != null && unreadBadgeCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.badgeRed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    unreadBadgeCount > 99 ? '99+' : unreadBadgeCount.toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventsTab(BuildContext context, FollowingState state) {
    if (state.status == FollowingStatus.loading && state.events.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryViolet),
      );
    }

    if (state.status == FollowingStatus.failure && state.events.isEmpty) {
      return _buildErrorView(
        message: state.errorMessage ?? 'Neizdevās ielādēt sekotos pasākumus',
        onRetry: () =>
            context.read<FollowingBloc>().add(const FollowingLoadRequested()),
      );
    }

    if (state.events.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primaryViolet,
        onRefresh: () async {
          context.read<FollowingBloc>().add(const FollowingRefreshRequested());
        },
        child: ListView(
          children: [
            const SizedBox(height: 100),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.event_available_outlined,
                    size: 56,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nav sekotu pasākumu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 36),
                    child: Text(
                      'Spied zvaniņa ikonu pie pasākumiem, lai pievienotu tos savam sekoto notikumu kalendāram.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    key: const Key('following_browse_events_button'),
                    onPressed: () => context.go('/events'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryViolet,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                      ),
                    ),
                    child: const Text('Pārlūkot pasākumus'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final grouped = state.groupedEvents;
    final dayHeaders = grouped.keys.toList();

    return RefreshIndicator(
      color: AppColors.primaryViolet,
      onRefresh: () async {
        context.read<FollowingBloc>().add(const FollowingRefreshRequested());
      },
      child: ListView.builder(
        itemCount: dayHeaders.length,
        padding: const EdgeInsets.only(bottom: 24, top: 4),
        itemBuilder: (context, index) {
          final header = dayHeaders[index];
          final dayEvents = grouped[header] ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  header,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ),
              ...dayEvents.map(
                (event) => EventCard(
                  key: ValueKey(event.id),
                  event: event,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlacesTab(BuildContext context, FollowingState state) {
    if (state.status == FollowingStatus.loading && state.places.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryViolet),
      );
    }

    if (state.status == FollowingStatus.failure && state.places.isEmpty) {
      return _buildErrorView(
        message: state.errorMessage ?? 'Neizdevās ielādēt sekotās vietas',
        onRetry: () =>
            context.read<FollowingBloc>().add(const FollowingLoadRequested()),
      );
    }

    if (state.places.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primaryViolet,
        onRefresh: () async {
          context.read<FollowingBloc>().add(const FollowingRefreshRequested());
        },
        child: ListView(
          children: [
            const SizedBox(height: 100),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 56,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nav sekotu vietu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 36),
                    child: Text(
                      'Spied zvaniņa ikonu pie sev tīkamajām vietām, lai saņemtu paziņojumus par to jaunajiem pasākumiem.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    key: const Key('following_browse_places_button'),
                    onPressed: () => context.go('/places'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryViolet,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                      ),
                    ),
                    child: const Text('Pārlūkot vietas'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryViolet,
      onRefresh: () async {
        context.read<FollowingBloc>().add(const FollowingRefreshRequested());
      },
      child: ListView.builder(
        itemCount: state.places.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final item = state.places[index];
          return FollowedPlaceCard(
            key: ValueKey(item.place.id),
            item: item,
          );
        },
      ),
    );
  }

  Widget _buildErrorView({
    required String message,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Mēģināt vēlreiz'),
            ),
          ],
        ),
      ),
    );
  }
}
