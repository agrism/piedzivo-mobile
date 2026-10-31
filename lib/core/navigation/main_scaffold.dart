import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../../features/following/bloc/following_bloc.dart';
import '../../features/following/bloc/following_state.dart';
import 'global_top_bar.dart';
import 'piedzivo_bottom_nav.dart';

class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: const GlobalTopBar(),
      body: navigationShell,
      bottomNavigationBar: BlocBuilder<FollowingBloc, FollowingState>(
        builder: (context, state) {
          return PiedzivoBottomNav(
            navigationShell: navigationShell,
            followingBadgeCount: state.totalUnreadPlacesCount,
          );
        },
      ),
    );
  }
}
