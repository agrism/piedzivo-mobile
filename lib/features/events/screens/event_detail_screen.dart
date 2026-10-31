import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/widgets/auth_bottom_sheet.dart';
import '../../feedback/models/feedback_submission.dart';
import '../../feedback/widgets/feedback_bottom_sheet.dart';
import '../models/event_detail.dart';
import '../repositories/events_repository.dart';
import '../utils/event_date_formatter.dart';
import '../widgets/image_zoom_dialog.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  final EventDetail? initialDetail;

  const EventDetailScreen({
    super.key,
    required this.eventId,
    this.initialDetail,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late Future<EventDetail> _eventFuture;
  EventDetail? _event;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialDetail != null) {
      _event = widget.initialDetail;
    } else {
      _loadEventDetail();
    }
  }

  void _loadEventDetail() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = context.read<EventsRepository>();
    _eventFuture = repo.getEventDetail(widget.eventId);
    _eventFuture.then((data) {
      if (mounted) {
        setState(() {
          _event = data;
          _isLoading = false;
        });
      }
    }).catchError((err) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Neizdevās ielādēt pasākuma detaļas: $err';
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
    final cur = _event;
    if (cur == null) return;

    if (!await _ensureAuth()) return;
    if (!mounted) return;

    final wasRecommended = cur.isRecommendedByMe;
    final newCount = wasRecommended
        ? (cur.recommendationsCount > 0 ? cur.recommendationsCount - 1 : 0)
        : cur.recommendationsCount + 1;

    // Optimistic UI update
    setState(() {
      _event = cur.copyWith(
        isRecommendedByMe: !wasRecommended,
        recommendationsCount: newCount,
      );
    });

    final success = await context.read<EventsRepository>().toggleRecommend(cur.id);
    if (!success && mounted) {
      // Revert if failed
      setState(() {
        _event = cur;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Neizdevās saglabāt ieteikumu')),
      );
    }
  }

  Future<void> _toggleFollow() async {
    final cur = _event;
    if (cur == null) return;

    if (!await _ensureAuth()) return;
    if (!mounted) return;

    final wasFollowed = cur.isFollowedByMe;

    // Optimistic UI update
    setState(() {
      _event = cur.copyWith(
        isFollowedByMe: !wasFollowed,
      );
    });

    final success = await context.read<EventsRepository>().toggleFollow(cur.id);
    if (!success && mounted) {
      // Revert if failed
      setState(() {
        _event = cur;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Neizdevās veikt sekošanas darbību')),
      );
    }
  }

  Future<void> _openTicketUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Neizdevās atvērt biļešu saiti')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Neizdevās atvērt biļešu saiti')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryViolet),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadEventDetail,
                child: const Text('Mēģināt vēlreiz'),
              ),
            ],
          ),
        ),
      );
    }

    final event = _event;
    if (event == null) {
      return const Center(child: Text('Pasākums nav atrasts'));
    }

    final dateFormatted = EventDateFormatter.formatFullDate(event.startsOn);
    final timeFormatted = EventDateFormatter.formatTime(event.startsAt);
    final endTimeFormatted = EventDateFormatter.formatTime(event.endsAt);
    final fullTime = [
      if (timeFormatted.isNotEmpty) timeFormatted,
      if (endTimeFormatted.isNotEmpty) '– $endTimeFormatted',
    ].join(' ');

    return CustomScrollView(
      slivers: [
        // 1. Sliver AppBar ar afišu un atpakaļ pogu
        SliverAppBar(
          expandedHeight: event.imageUrl != null && event.imageUrl!.isNotEmpty ? 280 : 0,
          pinned: true,
          elevation: 0,
          backgroundColor: AppColors.primaryNavy,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              child: IconButton(
                key: const Key('event_detail_back_button'),
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                onPressed: () => context.pop(),
              ),
            ),
          ),
          flexibleSpace: event.imageUrl != null && event.imageUrl!.isNotEmpty
              ? FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: event.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.primaryNavy,
                          child: const Icon(Icons.event_outlined, color: Colors.white54, size: 48),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.primaryNavy,
                          child: const Icon(Icons.image_not_supported_outlined, color: Colors.white54, size: 48),
                        ),
                      ),
                      // Gradient overlay apakšā
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 90,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Zoom poga labajā apakšējā stūrī
                      Positioned(
                        bottom: 12,
                        right: 16,
                        child: InkWell(
                          key: const Key('event_detail_zoom_button'),
                          onTap: () => ImageZoomDialog.show(
                            context,
                            imageUrl: event.imageUrl!,
                            title: event.title,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.zoom_in, color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'Apskatīt afišu',
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        ),

        // 2. Galvenais saturs
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Birkas (Kategorija, Bezmaksas / Cena, Prioritāte, Jauns)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (event.primaryTaxonomyName != null && event.primaryTaxonomyName!.isNotEmpty)
                      _buildChip(
                        text: event.primaryTaxonomyName!,
                        backgroundColor: AppColors.primaryViolet.withValues(alpha: 0.1),
                        textColor: AppColors.primaryViolet,
                      ),
                    if (event.isFree)
                      _buildChip(
                        text: '🎟️ Bezmaksas',
                        backgroundColor: const Color(0xFFDCFCE7),
                        textColor: const Color(0xFF15803D),
                      )
                    else if (event.priceLabel.isNotEmpty)
                      _buildChip(
                        text: '🎟️ ${event.priceLabel}',
                        backgroundColor: const Color(0xFFEFF6FF),
                        textColor: AppColors.accentBlue,
                      ),
                    if (event.editorialPriority > 0)
                      _buildChip(
                        text: '⭐ Piedzīvo ieteikums',
                        backgroundColor: const Color(0xFFFEF3C7),
                        textColor: const Color(0xFFB45309),
                      ),
                    if (event.isNew)
                      _buildChip(
                        text: '✨ JAUNS',
                        backgroundColor: const Color(0xFFFEE2E2),
                        textColor: const Color(0xFFB91C1C),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Pasākuma virsraksts
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryNavy,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 16),

                // Datuma un laika informācijas bloks
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryViolet.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.calendar_month_rounded, color: AppColors.primaryViolet, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateFormatted,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                            if (fullTime.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                fullTime,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Norises vietas kartīte ar pāreju uz PlaceDetail
                if (event.placeTitle != null && event.placeTitle!.isNotEmpty) ...[
                  InkWell(
                    key: const Key('event_venue_card'),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                    onTap: event.placeId != null
                        ? () => context.push('/places/${event.placeId}')
                        : null,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.accentBlue.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.location_on_rounded, color: AppColors.accentBlue, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.placeTitle!,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryNavy,
                                  ),
                                ),
                                if (event.placeCity != null || event.placeAddress != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    [event.placeAddress, event.placeCity].whereType<String>().join(', '),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (event.placeId != null)
                            const Icon(Icons.chevron_right, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Sociālās darbības: "Iesaku" un "Sekoju"
                Row(
                  children: [
                    // Iesaku poga
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('event_detail_recommend_button'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: event.isRecommendedByMe ? AppColors.primaryViolet : AppColors.borderSubtle,
                            width: 1.5,
                          ),
                          backgroundColor: event.isRecommendedByMe
                              ? AppColors.primaryViolet.withValues(alpha: 0.08)
                              : AppColors.cardWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppDimensions.buttonBorderRadius,
                          ),
                        ),
                        onPressed: _toggleRecommend,
                        icon: Icon(
                          event.isRecommendedByMe ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                          size: 18,
                          color: event.isRecommendedByMe ? AppColors.primaryViolet : AppColors.textSecondary,
                        ),
                        label: Text(
                          'Iesaku (${event.recommendationsCount})',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: event.isRecommendedByMe ? AppColors.primaryViolet : AppColors.primaryNavy,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Sekoju poga
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('event_detail_follow_button'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: event.isFollowedByMe ? AppColors.accentBlue : AppColors.borderSubtle,
                            width: 1.5,
                          ),
                          backgroundColor: event.isFollowedByMe
                              ? AppColors.accentBlue.withValues(alpha: 0.08)
                              : AppColors.cardWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppDimensions.buttonBorderRadius,
                          ),
                        ),
                        onPressed: _toggleFollow,
                        icon: Icon(
                          event.isFollowedByMe ? Icons.notifications_active : Icons.notifications_none,
                          size: 18,
                          color: event.isFollowedByMe ? AppColors.accentBlue : AppColors.textSecondary,
                        ),
                        label: Text(
                          event.isFollowedByMe ? 'Sekoju' : 'Sekot',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: event.isFollowedByMe ? AppColors.accentBlue : AppColors.primaryNavy,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Biļešu pirkšanas poga (ar url_launcher)
                if (event.ticketUrl != null && event.ticketUrl!.isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      key: const Key('event_detail_ticket_button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryViolet,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppDimensions.buttonBorderRadius,
                        ),
                      ),
                      onPressed: () => _openTicketUrl(event.ticketUrl!),
                      icon: const Icon(Icons.confirmation_number_outlined, size: 20),
                      label: Text(
                        event.isFree ? 'Reģistrēties bez maksas' : 'Pirkt biļetes',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  if (event.priceDetails != null && event.priceDetails!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        event.priceDetails!,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],

                // Apraksta virsraksts un teksts
                if (event.description != null && event.description!.isNotEmpty) ...[
                  const Text(
                    'Par pasākumu',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                Center(
                  child: TextButton.icon(
                    key: const Key('event_feedback_button'),
                    onPressed: () => showFeedbackBottomSheet(
                      context,
                      contextType: FeedbackContextType.event,
                      contextId: event.id,
                      contextTitle: event.title,
                    ),
                    icon: const Icon(Icons.outlined_flag_rounded, size: 18, color: AppColors.textMuted),
                    label: const Text(
                      'Ziņot par kļūdu vai labojumu',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChip({
    required String text,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
