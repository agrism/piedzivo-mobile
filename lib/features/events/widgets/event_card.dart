import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/widgets/auth_bottom_sheet.dart';
import '../bloc/events_bloc.dart';
import '../bloc/events_event.dart';
import '../models/event_list_item.dart';
import '../utils/event_date_formatter.dart';
import 'image_zoom_dialog.dart';

class EventCard extends StatelessWidget {
  final EventListItem event;

  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final formattedTime = EventDateFormatter.formatTime(event.startsAt);
    final timeCategory = [
      if (formattedTime.isNotEmpty) formattedTime,
      if (event.primaryTaxonomyName != null && event.primaryTaxonomyName!.isNotEmpty)
        event.primaryTaxonomyName!,
    ].join(' • ');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: AppDimensions.cardBorderRadius,
        side: const BorderSide(color: AppColors.borderSubtle, width: 1),
      ),
      color: AppColors.cardWhite,
      child: InkWell(
        borderRadius: AppDimensions.cardBorderRadius,
        onTap: () => context.push('/events/${event.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 64x64 Afiša ar palielināmā stikla zoom pogu
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusImage),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: event.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.backgroundLight,
                                child: const Icon(
                                  Icons.event_outlined,
                                  color: AppColors.textMuted,
                                  size: 28,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.backgroundLight,
                                child: const Icon(
                                  Icons.event_outlined,
                                  color: AppColors.textMuted,
                                  size: 28,
                                ),
                              ),
                            )
                          : Container(
                              color: AppColors.backgroundLight,
                              child: const Icon(
                                Icons.event_outlined,
                                color: AppColors.textMuted,
                                size: 28,
                              ),
                            ),
                    ),
                  ),

                  // Zoom poga
                  if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: InkWell(
                        key: Key('zoom_button_${event.id}'),
                        onTap: () => ImageZoomDialog.show(
                          context,
                          imageUrl: event.imageUrl!,
                          title: event.title,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.zoom_in_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 12),

              // 2. Galvenā informācija
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Laiks un kategorija
                    if (timeCategory.isNotEmpty)
                      Text(
                        timeCategory,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryViolet,
                        ),
                      ),

                    const SizedBox(height: 2),

                    // Nosaukums
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Vieta un pilsēta
                    if (event.placeTitle != null || event.placeCity != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              [
                                if (event.placeTitle != null) event.placeTitle!,
                                if (event.placeCity != null) event.placeCity!,
                              ].join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 8),

                    // Birkas (Cena, Jauns, Piedzīvo ieteikums)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        // Cenas birka
                        if (event.priceLabel.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: event.isFree
                                  ? const Color(0xFFDCFCE7)
                                  : AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                              border: Border.all(
                                color: event.isFree
                                    ? const Color(0xFF86EFAC)
                                    : AppColors.borderSubtle,
                              ),
                            ),
                            child: Text(
                              '🎟️ ${event.priceLabel}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: event.isFree
                                    ? const Color(0xFF15803D)
                                    : AppColors.primaryNavy,
                              ),
                            ),
                          ),

                        // Piedzīvo prioritāte
                        if (event.editorialPriority > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F3FF),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                              border: Border.all(color: const Color(0xFFDDD6FE)),
                            ),
                            child: const Text(
                              '⭐ Piedzīvo',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryViolet,
                              ),
                            ),
                          ),

                        // Jaunums
                        if (event.isNew)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: const Text(
                              '✨ JAUNS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // 3. Labās puses mijiedarbības pogas (Iesaku un Sekot)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ieteikt poga
                  InkWell(
                    key: Key('recommend_button_${event.id}'),
                    onTap: () async {
                      if (!await _ensureAuth(context)) return;
                      if (!context.mounted) return;
                      context.read<EventsBloc>().add(ToggleRecommendEvent(event.id));
                    },
                    borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Column(
                        children: [
                          Icon(
                            event.isRecommendedByMe
                                ? Icons.thumb_up_rounded
                                : Icons.thumb_up_alt_outlined,
                            size: 18,
                            color: event.isRecommendedByMe
                                ? AppColors.accentBlue
                                : AppColors.textMuted,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            event.recommendationsCount.toString(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: event.isRecommendedByMe
                                  ? AppColors.accentBlue
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Sekot poga
                  InkWell(
                    key: Key('follow_button_${event.id}'),
                    onTap: () async {
                      if (!await _ensureAuth(context)) return;
                      if (!context.mounted) return;
                      context.read<EventsBloc>().add(ToggleFollowEvent(event.id));
                    },
                    borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: event.isFollowedByMe
                            ? const Color(0xFFFEE2E2)
                            : AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                        border: Border.all(
                          color: event.isFollowedByMe
                              ? const Color(0xFFFCA5A5)
                              : AppColors.borderSubtle,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            event.isFollowedByMe
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 14,
                            color: event.isFollowedByMe
                                ? AppColors.error
                                : AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _ensureAuth(BuildContext context) async {
    try {
      final authBloc = context.read<AuthBloc>();
      if (!authBloc.state.isAuthenticated) {
        final res = await showAuthBottomSheet(context);
        return res == true;
      }
      return true;
    } catch (_) {
      return true;
    }
  }
}
