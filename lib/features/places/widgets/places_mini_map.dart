import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class PlacesMiniMap extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final int placesCount;

  const PlacesMiniMap({
    super.key,
    this.latitude,
    this.longitude,
    this.placesCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final lat = latitude ?? 56.9496;
    final lng = longitude ?? 24.1052;

    return Container(
      height: 120,
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        child: Stack(
          children: [
            // 1. Kartes fons vai statisks flīžu skats
            if (AppTheme.isTestMode)
              Container(
                color: const Color(0xFFE2E8F0),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.map_outlined, color: AppColors.primaryViolet, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'Karte ($placesCount vietas)',
                        style: const TextStyle(
                          color: AppColors.primaryNavy,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(lat, lng),
                  initialZoom: 12.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'lv.piedzivo.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(lat, lng),
                        width: 32,
                        height: 32,
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.primaryViolet,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

            // 2. Puscaurspīdīgs virsmas aizsargslānis
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const Key('mini_map_tap_area'),
                  onTap: () => context.push('/places/map'),
                ),
              ),
            ),

            // 3. Poga "Atvērt pilnekrāna karti" labajā apakšējā stūrī
            Positioned(
              bottom: 10,
              right: 10,
              child: ElevatedButton.icon(
                key: const Key('open_fullscreen_map_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cardWhite,
                  foregroundColor: AppColors.primaryNavy,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                    side: const BorderSide(color: AppColors.borderSubtle, width: 0.8),
                  ),
                ),
                onPressed: () => context.push('/places/map'),
                icon: const Icon(Icons.fullscreen_rounded, size: 16, color: AppColors.primaryViolet),
                label: const Text(
                  'Atvērt karti',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

