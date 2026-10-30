import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
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
      bottomNavigationBar: PiedzivoBottomNav(
        navigationShell: navigationShell,
      ),
    );
  }
}
