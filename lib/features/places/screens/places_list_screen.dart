import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../geo/cubit/geo_cubit.dart';
import '../../geo/cubit/geo_state.dart';
import '../bloc/places_bloc.dart';
import '../bloc/places_event.dart';
import '../bloc/places_state.dart';
import '../widgets/place_card.dart';
import '../widgets/places_mini_map.dart';

class PlacesListScreen extends StatefulWidget {
  const PlacesListScreen({super.key});

  @override
  State<PlacesListScreen> createState() => _PlacesListScreenState();
}

class _PlacesListScreenState extends State<PlacesListScreen>
    with AutomaticKeepAliveClientMixin {
  static const List<String> _categories = [
    'Visi',
    'Ēdināšana',
    'Apskates objekti',
    'Daba un pārgājieni',
    'Kultūra',
    'Naktsmītnes',
    'Izklaide',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final geoState = context.read<GeoCubit>().state;
    context.read<PlacesBloc>().add(LoadPlaces(placeId: geoState.currentFilterPlaceId));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocListener<GeoCubit, GeoState>(
      listenWhen: (prev, curr) => prev.currentFilterPlaceId != curr.currentFilterPlaceId,
      listener: (context, geoState) {
        context.read<PlacesBloc>().add(LoadPlaces(placeId: geoState.currentFilterPlaceId));
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Column(
          children: [
            // 1. Ātro kategoriju josla
            _buildCategoryBar(context),

            // 2. Vietu saraksts ar mini-karti
            Expanded(
              child: BlocBuilder<PlacesBloc, PlacesState>(
                builder: (context, state) {
                  if (state is PlacesLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryViolet),
                    );
                  }

                  if (state is PlacesError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.error),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                final placeId = context.read<GeoCubit>().state.currentFilterPlaceId;
                                context.read<PlacesBloc>().add(LoadPlaces(placeId: placeId, forceRefresh: true));
                              },
                              child: const Text('Mēģināt vēlreiz'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is PlacesLoaded) {
                    final grouped = state.groupedPlaces;
                    final categoryHeaders = grouped.keys.toList();

                    return RefreshIndicator(
                      color: AppColors.primaryViolet,
                      onRefresh: () async {
                        final placeId = context.read<GeoCubit>().state.currentFilterPlaceId;
                        context.read<PlacesBloc>().add(LoadPlaces(placeId: placeId, forceRefresh: true));
                      },
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 24, top: 4),
                        children: [
                          // 120px Mini-kartes priekšskatījums saraksta augšgalā
                          PlacesMiniMap(
                            placesCount: state.filteredPlaces.length,
                            latitude: state.filteredPlaces.isNotEmpty
                                ? state.filteredPlaces.first.latitude
                                : null,
                            longitude: state.filteredPlaces.isNotEmpty
                                ? state.filteredPlaces.first.longitude
                                : null,
                          ),

                          if (state.filteredPlaces.isEmpty) ...[
                            const SizedBox(height: 60),
                            const Center(
                              child: Column(
                                children: [
                                  Icon(Icons.location_off_rounded, size: 48, color: AppColors.textMuted),
                                  SizedBox(height: 12),
                                  Text(
                                    'Šajos filtros vietas netika atrastas',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // Kategoriju sekcijas un vietu kartītes
                            for (final header in categoryHeaders) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                                child: Text(
                                  '${header.toUpperCase()} (${grouped[header]?.length ?? 0})',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: AppColors.primaryNavy,
                                  ),
                                ),
                              ),
                              for (final place in grouped[header] ?? [])
                                PlaceCard(key: ValueKey(place.id), place: place),
                            ],
                          ],
                        ],
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBar(BuildContext context) {
    return BlocBuilder<PlacesBloc, PlacesState>(
      builder: (context, state) {
        final selectedCat = state is PlacesLoaded ? state.selectedCategory : null;

        return Container(
          height: 48,
          margin: const EdgeInsets.only(top: 6, bottom: 4),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              ..._categories.map((cat) {
                final isSelected = cat == 'Visi' ? selectedCat == null : selectedCat == cat;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    key: Key('places_category_chip_$cat'),
                    label: Text(cat),
                    selected: isSelected,
                    showCheckmark: false,
                    selectedColor: AppColors.primaryViolet,
                    backgroundColor: AppColors.cardWhite,
                    side: BorderSide(
                      color: isSelected ? AppColors.primaryViolet : AppColors.borderSubtle,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.primaryNavy,
                    ),
                    onSelected: (selected) {
                      final targetCategory = cat == 'Visi' ? null : (selected ? cat : null);
                      context.read<PlacesBloc>().add(FilterPlaces(
                            category: targetCategory,
                          ));
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
