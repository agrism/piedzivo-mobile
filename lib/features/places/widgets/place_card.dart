import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/widgets/auth_bottom_sheet.dart';
import '../bloc/places_bloc.dart';
import '../bloc/places_event.dart';
import '../models/place_list_item.dart';

class PlaceCard extends StatelessWidget {
  final PlaceListItem place;

  const PlaceCard({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
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
        onTap: () => context.push('/places/${place.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 80x80px Galvenais foto ar fotogrāfiju skaita birku [📷 N]
              Stack(
                children: [
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
                              placeholder: (context, url) => Container(
                                color: AppColors.backgroundLight,
                                child: const Icon(
                                  Icons.place_outlined,
                                  color: AppColors.textMuted,
                                  size: 32,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
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

                  // Fotogrāfiju skaita birka
                  if (place.imagesCount > 1)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_camera, size: 10, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(
                              '${place.imagesCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // 2. Aprakstošā informācija
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Darba laika statuss + Birkas (Piedzīvo ieteikums, JAUNS)
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        // Reāllaika darba laiks: 🟢 Atvērts / 🔴 Slēgts
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: place.isOpen ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                            border: Border.all(
                              color: place.isOpen ? const Color(0xFF86EFAC) : AppColors.borderSubtle,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            place.openingLabel.isNotEmpty
                                ? '${place.isOpen ? '🟢' : '🔴'} ${place.openingLabel}'
                                : (place.isOpen ? '🟢 Atvērts' : '🔴 Slēgts'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: place.isOpen ? const Color(0xFF15803D) : AppColors.textSecondary,
                            ),
                          ),
                        ),

                        if (place.editorialPriority > 0)
                          _buildMiniBadge(
                            text: '⭐ Piedzīvo',
                            bg: const Color(0xFFFEF3C7),
                            fg: const Color(0xFFB45309),
                          ),

                        if (place.isNew)
                          _buildMiniBadge(
                            text: '✨ JAUNS',
                            bg: const Color(0xFFFEE2E2),
                            fg: const Color(0xFFB91C1C),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Vietas nosaukums
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
                    const SizedBox(height: 3),

                    // Pilsēta un kategorija
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            [
                              if (place.city.isNotEmpty) place.city,
                              if (place.primaryTaxonomyName != null && place.primaryTaxonomyName!.isNotEmpty)
                                place.primaryTaxonomyName!,
                            ].join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Gaidāmie pasākumi
                    if (place.upcomingEventsCount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '🎟️ ${place.upcomingEventsCount} gaidāmi pasākumi',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryViolet,
                        ),
                      ),
                    ],

                    const SizedBox(height: 6),

                    // Pogas: Iesaku un Sekoju
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Iesaku poga
                        InkWell(
                          key: Key('place_recommend_${place.id}'),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                          onTap: () async {
                            if (!await _ensureAuth(context)) return;
                            if (!context.mounted) return;
                            context.read<PlacesBloc>().add(ToggleRecommendPlace(place.id));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: place.isRecommendedByMe
                                  ? AppColors.primaryViolet.withValues(alpha: 0.1)
                                  : AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                              border: Border.all(
                                color: place.isRecommendedByMe ? AppColors.primaryViolet : AppColors.borderSubtle,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  place.isRecommendedByMe ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                                  size: 13,
                                  color: place.isRecommendedByMe ? AppColors.primaryViolet : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${place.recommendationsCount}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: place.isRecommendedByMe ? AppColors.primaryViolet : AppColors.primaryNavy,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Sekoju poga
                        InkWell(
                          key: Key('place_follow_${place.id}'),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                          onTap: () async {
                            if (!await _ensureAuth(context)) return;
                            if (!context.mounted) return;
                            context.read<PlacesBloc>().add(ToggleFollowPlace(place.id));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: place.isFollowedByMe
                                  ? AppColors.accentBlue.withValues(alpha: 0.1)
                                  : AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                              border: Border.all(
                                color: place.isFollowedByMe ? AppColors.accentBlue : AppColors.borderSubtle,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  place.isFollowedByMe ? Icons.notifications_active : Icons.notifications_none,
                                  size: 13,
                                  color: place.isFollowedByMe ? AppColors.accentBlue : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  place.isFollowedByMe ? 'Sekoju' : 'Sekot',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: place.isFollowedByMe ? AppColors.accentBlue : AppColors.primaryNavy,
                                  ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBadge({
    required String text,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: fg,
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

