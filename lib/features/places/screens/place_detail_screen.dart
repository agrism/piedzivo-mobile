import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/widgets/auth_bottom_sheet.dart';
import '../../events/models/event_list_item.dart';
import '../models/place_detail.dart';
import '../repositories/places_repository.dart';
import '../widgets/place_gallery_zoom_dialog.dart';

class PlaceDetailScreen extends StatefulWidget {
  final String placeId;
  final PlaceDetail? initialDetail;

  const PlaceDetailScreen({
    super.key,
    required this.placeId,
    this.initialDetail,
  });

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  late Future<PlaceDetail> _placeFuture;
  PlaceDetail? _place;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentGalleryIndex = 0;
  bool _isScheduleExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDetail != null) {
      _place = widget.initialDetail;
    } else {
      _loadPlaceDetail();
    }
  }

  void _loadPlaceDetail() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = context.read<PlacesRepository>();
    _placeFuture = repo.getPlaceDetail(widget.placeId);
    _placeFuture.then((data) {
      if (mounted) {
        setState(() {
          _place = data;
          _isLoading = false;
        });
      }
    }).catchError((err) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Neizdevās ielādēt vietas detaļas: $err';
          _isLoading = false;
        });
      }
    });
  }

  Future<bool> _ensureAuth() async {
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

  Future<void> _toggleRecommend() async {
    final cur = _place;
    if (cur == null) return;

    if (!await _ensureAuth()) return;
    if (!mounted) return;

    final wasRecommended = cur.isRecommendedByMe;
    final newCount = wasRecommended
        ? (cur.recommendationsCount > 0 ? cur.recommendationsCount - 1 : 0)
        : cur.recommendationsCount + 1;

    // Optimistic UI update
    setState(() {
      _place = cur.copyWith(
        isRecommendedByMe: !wasRecommended,
        recommendationsCount: newCount,
      );
    });

    final success = await context.read<PlacesRepository>().toggleRecommend(cur.id);
    if (!success && mounted) {
      setState(() {
        _place = cur;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Neizdevās saglabāt ieteikumu')),
      );
    }
  }

  Future<void> _toggleFollow() async {
    final cur = _place;
    if (cur == null) return;

    if (!await _ensureAuth()) return;
    if (!mounted) return;

    final wasFollowed = cur.isFollowedByMe;

    // Optimistic UI update
    setState(() {
      _place = cur.copyWith(
        isFollowedByMe: !wasFollowed,
      );
    });

    final success = await context.read<PlacesRepository>().toggleFollow(cur.id);
    if (!success && mounted) {
      setState(() {
        _place = cur;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Neizdevās atjaunināt sekošanu')),
      );
    }
  }

  Future<void> _openWaze(double lat, double lng) async {
    final nativeUri = Uri.parse('waze://?ll=$lat,$lng&navigate=yes');
    final webUri = Uri.parse('https://www.waze.com/ul?ll=$lat,$lng&navigate=yes');

    try {
      if (await canLaunchUrl(nativeUri)) {
        await launchUrl(nativeUri);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final nativeUri = Uri.parse('google.navigation:q=$lat,$lng');
    final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    try {
      if (await canLaunchUrl(nativeUri)) {
        await launchUrl(nativeUri);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.cardWhite,
          elevation: 0,
          leading: IconButton(
            key: const Key('place_detail_back_button'),
            icon: const Icon(Icons.arrow_back, color: AppColors.primaryNavy),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryViolet),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.cardWhite,
          elevation: 0,
          leading: IconButton(
            key: const Key('place_detail_back_button'),
            icon: const Icon(Icons.arrow_back, color: AppColors.primaryNavy),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.badgeRed),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: AppColors.primaryNavy),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loadPlaceDetail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryViolet,
                    foregroundColor: AppColors.cardWhite,
                  ),
                  child: const Text('Mēģināt vēlreiz'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final place = _place;
    if (place == null) {
      return const Scaffold(
        body: Center(child: Text('Vieta nav atrasta')),
      );
    }

    final category = place.rootCategoryName ?? place.primaryTaxonomyName;
    final images = place.images.isNotEmpty
        ? place.images
        : (place.primaryImageUrl != null ? [place.primaryImageUrl!] : <String>[]);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Fotogrāfiju Swipe Galerija (1..20 attēli)
            Stack(
              children: [
                SizedBox(
                  height: 270,
                  width: double.infinity,
                  child: images.isNotEmpty
                      ? PageView.builder(
                          itemCount: images.length,
                          onPageChanged: (idx) {
                            setState(() {
                              _currentGalleryIndex = idx;
                            });
                          },
                          itemBuilder: (context, index) {
                            final imgUrl = images[index];
                            return GestureDetector(
                              key: Key('gallery_image_$index'),
                              onTap: () {
                                PlaceGalleryZoomDialog.show(
                                  context,
                                  images: images,
                                  initialIndex: index,
                                  title: place.title,
                                );
                              },
                              child: !AppTheme.isTestMode
                                  ? CachedNetworkImage(
                                      imageUrl: imgUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        color: AppColors.borderSubtle,
                                        child: const Center(
                                          child: Icon(Icons.place_outlined,
                                              size: 48, color: AppColors.textMuted),
                                        ),
                                      ),
                                      errorWidget: (_, __, ___) => Container(
                                        color: AppColors.borderSubtle,
                                        child: const Center(
                                          child: Icon(Icons.broken_image,
                                              size: 48, color: AppColors.textMuted),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: const Color(0xFFE2E8F0),
                                      child: Center(
                                        child: Text(
                                          'Attēls ${index + 1}/${images.length}',
                                          style: const TextStyle(
                                            color: AppColors.primaryNavy,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                            );
                          },
                        )
                      : Container(
                          color: const Color(0xFFE2E8F0),
                          child: const Center(
                            child: Icon(Icons.place_outlined, size: 64, color: AppColors.textMuted),
                          ),
                        ),
                ),

                // Atpakaļ poga
                Positioned(
                  top: 40,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x20000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      key: const Key('place_detail_back_button'),
                      icon: const Icon(Icons.arrow_back, color: AppColors.primaryNavy),
                      onPressed: () => context.pop(),
                    ),
                  ),
                ),

                // Foto skaitītājs [ 📷 1 / 4 ] un palielināšanas poga
                if (images.isNotEmpty)
                  Positioned(
                    bottom: 14,
                    right: 16,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                              const SizedBox(width: 5),
                              Text(
                                '${_currentGalleryIndex + 1} / ${images.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          key: const Key('place_image_zoom_button'),
                          onTap: () {
                            PlaceGalleryZoomDialog.show(
                              context,
                              images: images,
                              initialIndex: _currentGalleryIndex,
                              title: place.title,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.zoom_in, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // 2. Galvenā informācija
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Birkas (Kategorija, Piedzīvo, Jauns)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (category != null && category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            category.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primaryViolet,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      if (place.editorialPriority > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '⭐ Piedzīvo',
                            style: TextStyle(
                              color: Color(0xFFB45309),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      if (place.isNew)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '✨ JAUNS',
                            style: TextStyle(
                              color: Color(0xFF15803D),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Nosaukums
                  Text(
                    place.title,
                    style: const TextStyle(
                      color: AppColors.primaryNavy,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Adrese un pilsēta
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 18, color: AppColors.primaryViolet),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          place.address != null && place.address!.isNotEmpty
                              ? '${place.address}, ${place.city}'
                              : place.city,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. Darba laika izvēršamais grafiks
                  _buildOpeningSchedule(place),

                  const SizedBox(height: 16),

                  // 4. Ārējā navigācija: Waze un Google Maps
                  if (place.latitude != null && place.longitude != null)
                    _buildNavigationSection(place.latitude!, place.longitude!),

                  const SizedBox(height: 16),

                  // 5. Sociālās pogas: "Iesaku" un "Sekoju"
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('place_detail_recommend_button'),
                          onPressed: _toggleRecommend,
                          icon: Icon(
                            place.isRecommendedByMe ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                            size: 18,
                            color: place.isRecommendedByMe
                                ? AppColors.primaryViolet
                                : AppColors.primaryNavy,
                          ),
                          label: Text(
                            'Iesaku (${place.recommendationsCount})',
                            style: TextStyle(
                              color: place.isRecommendedByMe
                                  ? AppColors.primaryViolet
                                  : AppColors.primaryNavy,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: place.isRecommendedByMe
                                ? const Color(0xFFF5F3FF)
                                : AppColors.cardWhite,
                            side: BorderSide(
                              color: place.isRecommendedByMe
                                  ? AppColors.primaryViolet
                                  : AppColors.borderSubtle,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('place_detail_follow_button'),
                          onPressed: _toggleFollow,
                          icon: Icon(
                            place.isFollowedByMe ? Icons.notifications_active : Icons.notifications_none,
                            size: 18,
                            color: place.isFollowedByMe
                                ? AppColors.primaryViolet
                                : AppColors.primaryNavy,
                          ),
                          label: Text(
                            place.isFollowedByMe ? 'Sekoju' : 'Sekot',
                            style: TextStyle(
                              color: place.isFollowedByMe
                                  ? AppColors.primaryViolet
                                  : AppColors.primaryNavy,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: place.isFollowedByMe
                                ? const Color(0xFFF5F3FF)
                                : AppColors.cardWhite,
                            side: BorderSide(
                              color: place.isFollowedByMe
                                  ? AppColors.primaryViolet
                                  : AppColors.borderSubtle,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 6. Apraksts
                  if (place.description != null && place.description!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Par vietu',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      place.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],

                  // 7. Kontakti (Telefons, Mājaslapa, E-pasts)
                  if (_hasContacts(place)) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Kontakti',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        children: [
                          if (place.phone != null && place.phone!.isNotEmpty)
                            _buildContactRow(
                              Icons.phone_outlined,
                              place.phone!,
                              () => _launchExternalUrl('tel:${place.phone}'),
                            ),
                          if (place.email != null && place.email!.isNotEmpty)
                            _buildContactRow(
                              Icons.email_outlined,
                              place.email!,
                              () => _launchExternalUrl('mailto:${place.email}'),
                            ),
                          if (place.websiteUrl != null && place.websiteUrl!.isNotEmpty)
                            _buildContactRow(
                              Icons.language_outlined,
                              place.websiteUrl!,
                              () => _launchExternalUrl(place.websiteUrl!),
                            ),
                        ],
                      ),
                    ),
                  ],

                  // 8. Gaidāmie pasākumi šajā vietā (līdz 7 pasākumiem)
                  if (place.upcomingEvents.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Gaidāmie pasākumi (${place.upcomingEvents.length})',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        if (place.upcomingEventsCount > place.upcomingEvents.length)
                          TextButton(
                            key: const Key('view_all_place_events_button'),
                            onPressed: () {
                              context.push('/events?place_id=${place.id}');
                            },
                            child: Text(
                              'Visi (${place.upcomingEventsCount})',
                              style: const TextStyle(
                                color: AppColors.primaryViolet,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...place.upcomingEvents.take(7).map((event) {
                      return _buildUpcomingEventTile(context, event);
                    }),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasContacts(PlaceDetail place) {
    return (place.phone != null && place.phone!.isNotEmpty) ||
        (place.email != null && place.email!.isNotEmpty) ||
        (place.websiteUrl != null && place.websiteUrl!.isNotEmpty);
  }

  Widget _buildContactRow(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primaryViolet),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.primaryNavy,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildOpeningSchedule(PlaceDetail place) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          // Galvenes rinda ar statusu un izvērsi
          InkWell(
            key: const Key('toggle_opening_schedule_button'),
            onTap: () {
              setState(() {
                _isScheduleExpanded = !_isScheduleExpanded;
              });
            },
            borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: place.isOpen ? AppColors.success : AppColors.badgeRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      place.openingLabel.isNotEmpty
                          ? place.openingLabel
                          : (place.isOpen ? 'Atvērts' : 'Slēgts'),
                      style: TextStyle(
                        color: place.isOpen ? AppColors.success : AppColors.badgeRed,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (place.weeklySchedule.isNotEmpty)
                    Icon(
                      _isScheduleExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),

          // Izvērstais saraksts pa dienām
          if (_isScheduleExpanded && place.weeklySchedule.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.borderSubtle),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              child: Column(
                children: place.weeklySchedule.map((day) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          day.dayName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: day.isToday ? FontWeight.w700 : FontWeight.w500,
                            color: day.isToday ? AppColors.primaryViolet : AppColors.primaryNavy,
                          ),
                        ),
                        Text(
                          day.hours,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: day.isToday ? FontWeight.w700 : FontWeight.w500,
                            color: day.isClosed ? AppColors.badgeRed : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationSection(double lat, double lng) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Navigācija uz norises vietu',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Waze poga
              Expanded(
                child: ElevatedButton.icon(
                  key: const Key('open_waze_button'),
                  onPressed: () => _openWaze(lat, lng),
                  icon: const Icon(Icons.navigation, size: 16),
                  label: const Text('Waze'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF33CCFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Google Maps poga
              Expanded(
                child: ElevatedButton.icon(
                  key: const Key('open_google_maps_button'),
                  onPressed: () => _openGoogleMaps(lat, lng),
                  icon: const Icon(Icons.map, size: 16),
                  label: const Text('Google Maps'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4285F4),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventTile(BuildContext context, EventListItem event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: InkWell(
        key: Key('place_event_tile_${event.id}'),
        onTap: () {
          context.push('/events/${event.id}');
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              // 50x50 Afiša
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: event.imageUrl != null &&
                          event.imageUrl!.isNotEmpty &&
                          !AppTheme.isTestMode
                      ? CachedNetworkImage(
                          imageUrl: event.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: AppColors.borderSubtle),
                          errorWidget: (_, __, ___) => Container(color: AppColors.borderSubtle),
                        )
                      : Container(
                          color: const Color(0xFFE2E8F0),
                          child: const Icon(Icons.event, color: AppColors.primaryViolet, size: 24),
                        ),
                ),
              ),
              const SizedBox(width: 10),

              // Informācija
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${event.startsOn} ${event.startsAt != null ? "• ${event.startsAt}" : ""}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Cenas birka
              if (event.priceLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: event.isFree ? const Color(0xFFDCFCE7) : const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    event.priceLabel,
                    style: TextStyle(
                      color: event.isFree ? const Color(0xFF15803D) : AppColors.primaryViolet,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
