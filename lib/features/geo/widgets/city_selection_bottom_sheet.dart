import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../cubit/geo_cubit.dart';
import '../cubit/geo_state.dart';
import '../models/geo_place.dart';

class CitySelectionBottomSheet extends StatefulWidget {
  const CitySelectionBottomSheet({super.key});

  static Future<GeoPlace?> show(BuildContext context) {
    return showModalBottomSheet<GeoPlace>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<GeoCubit>(),
        child: const CitySelectionBottomSheet(),
      ),
    );
  }

  @override
  State<CitySelectionBottomSheet> createState() => _CitySelectionBottomSheetState();
}

class _CitySelectionBottomSheetState extends State<CitySelectionBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Izvēlies pilsētu vai novadu',
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Meklēt pilsētu...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.backgroundLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: AppDimensions.buttonBorderRadius,
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppDimensions.buttonBorderRadius,
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
              ),
            ),
          ),

          const Divider(height: 1, color: AppColors.borderSubtle),

          // Cities list
          Expanded(
            child: BlocBuilder<GeoCubit, GeoState>(
              builder: (context, state) {
                final filteredPlaces = state.places.where((p) {
                  if (_searchQuery.isEmpty) return true;
                  final nameMatch = p.name.toLowerCase().contains(_searchQuery);
                  final parentMatch = p.parent?.name.toLowerCase().contains(_searchQuery) ?? false;
                  return nameMatch || parentMatch;
                }).toList();

                if (filteredPlaces.isEmpty) {
                  return const Center(
                    child: Text(
                      'Neviena pilsēta netika atrasta',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filteredPlaces.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                    color: AppColors.borderSubtle,
                  ),
                  itemBuilder: (context, index) {
                    final place = filteredPlaces[index];
                    final isSelected = state.activePlace?.id == place.id;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: Icon(
                        place.isStateCity
                            ? Icons.location_city_rounded
                            : Icons.place_outlined,
                        color: isSelected ? AppColors.primaryViolet : AppColors.textMuted,
                      ),
                      title: Text(
                        place.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.primaryViolet : AppColors.primaryNavy,
                        ),
                      ),
                      subtitle: place.parent != null
                          ? Text(
                              place.parent!.name,
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            )
                          : (place.isStateCity
                              ? const Text(
                                  'Valstspilsēta',
                                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                )
                              : null),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryViolet)
                          : null,
                      onTap: () {
                        context.read<GeoCubit>().selectPlace(place);
                        Navigator.of(context).pop(place);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

