import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../geo/cubit/geo_cubit.dart';
import '../bloc/places_bloc.dart';
import '../bloc/places_event.dart';
import '../bloc/places_state.dart';
import '../models/place_list_item.dart';

class FullscreenMapScreen extends StatefulWidget {
  const FullscreenMapScreen({super.key});

  @override
  State<FullscreenMapScreen> createState() => _FullscreenMapScreenState();
}

class _FullscreenMapScreenState extends State<FullscreenMapScreen> {
  final MapController _mapController = MapController();
  PlaceListItem? _selectedPlace;

  @override
  Widget build(BuildContext context) {
    final geoState = context.watch<GeoCubit>().state;
    final activePlaceName = geoState.activePlace?.name ?? 'Latvija';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: BlocBuilder<PlacesBloc, PlacesState>(
        builder: (context, state) {
          if (state is PlacesLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryViolet),
            );
          }

          if (state is PlacesError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.statusRed),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    style: const TextStyle(fontSize: 16, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<PlacesBloc>().add(
                            LoadPlaces(
                              placeId: geoState.activePlace?.id,
                              isMunicipalityWide: geoState.isMunicipalityWide,
                            ),
                          );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryViolet,
                      foregroundColor: AppColors.surfaceWhite,
                    ),
                    child: const Text('Mēģināt vēlreiz'),
                  ),
                ],
              ),
            );
          }

          final places = state is PlacesLoaded ? state.filteredPlaces : <PlaceListItem>[];
          final allPlaces = state is PlacesLoaded ? state.allPlaces : <PlaceListItem>[];
          final selectedCategory = state is PlacesLoaded ? state.selectedCategory : null;

          final placesWithCoords = places
              .where((p) => p.latitude != null && p.longitude != null)
              .toList();

          // Aprēķinām kartes sākotnējo centru
          final center = _calculateCenter(placesWithCoords);

          // Unikālās kategorijas filtru joslai
          final categories = <String>{};
          for (final p in allPlaces) {
            final cat = p.rootCategoryName ?? p.primaryTaxonomyName;
            if (cat != null && cat.isNotEmpty) {
              categories.add(cat);
            }
          }

          return Stack(
            children: [
              // 1. Pilnekrāna karte (flutter_map)
              GestureDetector(
                onTap: () {
                  if (_selectedPlace != null) {
                    setState(() {
                      _selectedPlace = null;
                    });
                  }
                },
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 13.0,
                    onTap: (_, __) {
                      if (_selectedPlace != null) {
                        setState(() {
                          _selectedPlace = null;
                        });
                      }
                    },
                  ),
                  children: [
                    if (!AppTheme.isTestMode)
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'lv.piedzivo.app',
                      )
                    else
                      Container(color: const Color(0xFFE2E8F0)),
                    MarkerLayer(
                      markers: placesWithCoords.map((place) {
                        final isSelected = _selectedPlace?.id == place.id;
                        return Marker(
                          point: LatLng(place.latitude!, place.longitude!),
                          width: isSelected ? 48 : 38,
                          height: isSelected ? 48 : 38,
                          child: GestureDetector(
                            key: Key('map_marker_${place.id}'),
                            onTap: () {
                              setState(() {
                                _selectedPlace = place;
                              });
                              _mapController.move(
                                LatLng(place.latitude!, place.longitude!),
                                _mapController.camera.zoom,
                              );
                            },
                            child: _buildPin(place, isSelected),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // 2. Augšējā josla ar atpakaļ pogu, pilsētas nosaukumu un vietu skaitu
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite.withValues(alpha: 0.92),
                    border: const Border(
                      bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Row(
                            children: [
                              IconButton(
                                key: const Key('map_back_button'),
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: AppColors.primaryNavy,
                                ),
                                onPressed: () => context.pop(),
                              ),
                              Expanded(
                                child: Text(
                                  'Karte: $activePlaceName',
                                  style: const TextStyle(
                                    color: AppColors.primaryNavy,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.borderSubtle),
                                ),
                                child: Text(
                                  '${placesWithCoords.length} vietas',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),

                        // Horizontāla kategoriju filtru josla
                        if (categories.isNotEmpty)
                          SizedBox(
                            height: 38,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 6),
                              children: [
                                _buildCategoryFilterChip(
                                  label: 'Visas',
                                  isSelected: selectedCategory == null,
                                  onTap: () {
                                    context.read<PlacesBloc>().add(
                                          const FilterPlaces(category: null),
                                        );
                                  },
                                ),
                                ...categories.map((cat) {
                                  return _buildCategoryFilterChip(
                                    label: cat,
                                    isSelected: selectedCategory == cat,
                                    onTap: () {
                                      context.read<PlacesBloc>().add(
                                            FilterPlaces(
                                              category: selectedCategory == cat ? null : cat,
                                            ),
                                          );
                                    },
                                  );
                                }),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Poga kartes centra atiestatīšanai
              Positioned(
                right: 16,
                bottom: _selectedPlace != null ? 220 : 32,
                child: FloatingActionButton.small(
                  key: const Key('map_recenter_button'),
                  backgroundColor: AppColors.surfaceWhite,
                  foregroundColor: AppColors.primaryNavy,
                  elevation: 3,
                  onPressed: () {
                    _mapController.move(center, 13.0);
                  },
                  child: const Icon(Icons.my_location, size: 20),
                ),
              ),

              // 4. Izslīdošā vietas kartīte apakšā
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: 16,
                right: 16,
                bottom: _selectedPlace != null ? (MediaQuery.of(context).padding.bottom + 16) : -300,
                child: _selectedPlace != null
                    ? _buildSelectedPlaceCard(context, _selectedPlace!)
                    : const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
    );
  }

  LatLng _calculateCenter(List<PlaceListItem> places) {
    if (places.isEmpty) {
      return const LatLng(57.3119, 25.2731); // Cēsu noklusējums
    }
    double sumLat = 0;
    double sumLng = 0;
    for (final p in places) {
      sumLat += p.latitude!;
      sumLng += p.longitude!;
    }
    return LatLng(sumLat / places.length, sumLng / places.length);
  }

  Widget _buildPin(PlaceListItem place, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.brandGold : AppColors.primaryViolet,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.surfaceWhite,
          width: isSelected ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: isSelected ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.place,
          color: isSelected ? AppColors.primaryNavy : AppColors.surfaceWhite,
          size: isSelected ? 26 : 20,
        ),
      ),
    );
  }

  Widget _buildCategoryFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        key: Key('map_filter_chip_$label'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryViolet : AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
            border: Border.all(
              color: isSelected ? AppColors.primaryViolet : AppColors.borderSubtle,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.surfaceWhite : AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedPlaceCard(BuildContext context, PlaceListItem place) {
    final category = place.rootCategoryName ?? place.primaryTaxonomyName;

    return Container(
      key: const Key('map_selected_place_card'),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vieta attēls (70x70)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusImage),
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: place.primaryImageUrl != null &&
                            place.primaryImageUrl!.isNotEmpty &&
                            !AppTheme.isTestMode
                        ? CachedNetworkImage(
                            imageUrl: webSafeImageUrl(place.primaryImageUrl)!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: AppColors.backgroundLight,
                              child: const Icon(
                                Icons.place_outlined,
                                color: AppColors.textMuted,
                                size: 28,
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.backgroundLight,
                              child: const Icon(
                                Icons.place_outlined,
                                color: AppColors.textMuted,
                                size: 28,
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.backgroundLight,
                            child: const Icon(
                              Icons.place_outlined,
                              color: AppColors.textMuted,
                              size: 28,
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
                      Row(
                        children: [
                          if (category != null && category.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(bottom: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDE9FE),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                category.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.primaryViolet,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          const Spacer(),
                          // Aizvēršanas poga [✕]
                          GestureDetector(
                            key: const Key('close_map_place_card'),
                            onTap: () {
                              setState(() {
                                _selectedPlace = null;
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(2.0),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        place.title,
                        style: const TextStyle(
                          color: AppColors.primaryNavy,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Darba laika indikators
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: place.isOpen ? AppColors.statusGreen : AppColors.statusRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              place.openingLabel.isNotEmpty
                                  ? place.openingLabel
                                  : (place.isOpen ? 'Atvērts' : 'Slēgts'),
                              style: TextStyle(
                                color: place.isOpen ? AppColors.statusGreen : AppColors.statusRed,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Poga: Atvērt vietu
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton(
                key: const Key('map_card_open_place_button'),
                onPressed: () {
                  context.push('/places/${place.id}');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryViolet,
                  foregroundColor: AppColors.surfaceWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Atvērt vietu',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
