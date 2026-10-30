import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class PiedzivoBottomNav extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final int eventsBadgeCount;
  final int placesBadgeCount;
  final int followingBadgeCount;

  const PiedzivoBottomNav({
    super.key,
    required this.navigationShell,
    this.eventsBadgeCount = 0,
    this.placesBadgeCount = 0,
    this.followingBadgeCount = 0,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  Widget _buildIconWithBadge({
    required IconData icon,
    required IconData activeIcon,
    required bool isSelected,
    required int badgeCount,
  }) {
    final iconWidget = Icon(
      isSelected ? activeIcon : icon,
      size: 24,
      color: isSelected ? AppColors.primaryViolet : AppColors.textMuted,
    );

    if (badgeCount <= 0) {
      return iconWidget;
    }

    final String badgeText = badgeCount > 99 ? '99+' : badgeCount.toString();

    return Badge(
      backgroundColor: AppColors.badgeRed,
      textColor: Colors.white,
      textStyle: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      label: Text(badgeText),
      child: iconWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(
          top: BorderSide(
            color: AppColors.borderSubtle,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                label: 'Pasākumi',
                icon: Icons.calendar_today_outlined,
                activeIcon: Icons.calendar_month_rounded,
                isSelected: currentIndex == 0,
                badgeCount: eventsBadgeCount,
              ),
              _buildNavItem(
                index: 1,
                label: 'Vietas',
                icon: Icons.place_outlined,
                activeIcon: Icons.place_rounded,
                isSelected: currentIndex == 1,
                badgeCount: placesBadgeCount,
              ),
              _buildNavItem(
                index: 2,
                label: 'Sekotie',
                icon: Icons.favorite_outline_rounded,
                activeIcon: Icons.favorite_rounded,
                isSelected: currentIndex == 2,
                badgeCount: followingBadgeCount,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required bool isSelected,
    required int badgeCount,
  }) {
    return Expanded(
      child: InkWell(
        key: Key('bottom_nav_item_$index'),
        onTap: () => _onTap(index),
        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIconWithBadge(
              icon: icon,
              activeIcon: activeIcon,
              isSelected: isSelected,
              badgeCount: badgeCount,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primaryViolet : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
