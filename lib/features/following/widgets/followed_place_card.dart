import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_theme.dart';
import '../../places/bloc/places_bloc.dart';
import '../../places/bloc/places_event.dart';
import '../bloc/following_bloc.dart';
import '../bloc/following_event.dart';
import '../models/followed_place_item.dart';

class FollowedPlaceCard extends StatelessWidget {
  final FollowedPlaceItem item;

  const FollowedPlaceCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final place = item.place;

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
        onTap: () {
          if (item.hasUnread) {
            context.read<FollowingBloc>().add(FollowingPlaceMarkViewed(place.id));
          }
          context.push('/places/${place.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Attēls (80x80px)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusImage),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: place.primaryImageUrl != null &&
                          place.primaryImageUrl!.isNotEmpty &&
                          !AppTheme.isTestMode
                      ? CachedNetworkImage(
                          imageUrl: place.primaryImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppColors.backgroundLight,
                            child: const Icon(
                              Icons.place_outlined,
                              color: AppColors.textMuted,
                              size: 32,
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.backgroundLight,
                            child: const Icon(
                              Icons.place_outlined,
                              color: AppColors.textMuted,
                              size: 32,
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.backgroundLight,
                          child: const Icon(
                            Icons.place_outlined,
                            color: AppColors.textMuted,
                            size: 32,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // Informācija
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sarkanā neizlasīto jauno pasākumu birka [ 🔴 +N jauni! ]
                    if (item.hasUnread) ...[
                      Container(
                        key: Key('unread_badge_${place.id}'),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                          border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
                        ),
                        child: Text(
                          '🔴 +${item.unreadEventsCount} jauni!',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],

                    // Nosaukums
                    Text(
                      place.title,
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

                    // Pilsēta
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          place.city,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Darba laika statuss
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: place.isOpen ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                      ),
                      child: Text(
                        place.openingLabel.isNotEmpty
                            ? '${place.isOpen ? '🟢' : '🔴'} ${place.openingLabel}'
                            : (place.isOpen ? '🟢 Atvērts' : '🔴 Slēgts'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: place.isOpen ? const Color(0xFF15803D) : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Sekošanas poga (atvērt vai atcelt sekošanu)
              InkWell(
                key: Key('following_place_toggle_${place.id}'),
                onTap: () {
                  try {
                    context.read<PlacesBloc>().add(ToggleFollowPlace(place.id));
                  } catch (_) {}
                },
                borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    size: 18,
                    color: AppColors.accentBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
