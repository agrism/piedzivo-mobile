import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/geo/cubit/geo_cubit.dart';
import '../../features/geo/cubit/geo_state.dart';
import '../../features/geo/widgets/city_selection_bottom_sheet.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class GlobalTopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onProfileTap;

  const GlobalTopBar({
    super.key,
    this.onSearchTap,
    this.onProfileTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderSubtle,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          child: BlocBuilder<GeoCubit, GeoState>(
            builder: (context, state) {
              return Row(
                children: [
                  // 1. Pilsētas izvēles poga
                  InkWell(
                    key: const Key('global_top_bar_city_button'),
                    onTap: () => CitySelectionBottomSheet.show(context),
                    borderRadius: AppDimensions.buttonBorderRadius,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 20,
                            color: AppColors.primaryViolet,
                          ),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 110),
                            child: Text(
                              state.activePlaceName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // 2. Teritorijas slēdzis (Variants A: Tikai pilsētā <-> Visā novadā)
                  if (state.canToggleMunicipality)
                    InkWell(
                      key: const Key('global_top_bar_municipality_toggle'),
                      onTap: () => context.read<GeoCubit>().toggleMunicipalityWide(),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: state.isMunicipalityWide
                              ? AppColors.primaryViolet
                              : AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                          border: Border.all(
                            color: state.isMunicipalityWide
                                ? AppColors.primaryViolet
                                : AppColors.borderSubtle,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.isMunicipalityWide ? 'Visā novadā' : 'Tikai pilsētā',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: state.isMunicipalityWide
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                            if (state.isMunicipalityWide) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                  const Spacer(),

                  // 3. Meklēšanas poga
                  IconButton(
                    key: const Key('global_top_bar_search_button'),
                    icon: const Icon(Icons.search_rounded, color: AppColors.primaryNavy),
                    tooltip: 'Meklēt',
                    onPressed: onSearchTap ?? () => context.push('/search'),
                  ),

                  // 4. Profila poga
                  IconButton(
                    key: const Key('global_top_bar_profile_button'),
                    icon: const Icon(Icons.person_outline_rounded, color: AppColors.primaryNavy),
                    tooltip: 'Profils',
                    onPressed: onProfileTap ?? () {},
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

