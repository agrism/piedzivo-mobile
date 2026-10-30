import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class PlaceGalleryZoomDialog extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String title;

  const PlaceGalleryZoomDialog({
    super.key,
    required this.images,
    this.initialIndex = 0,
    required this.title,
  });

  static Future<void> show(
    BuildContext context, {
    required List<String> images,
    int initialIndex = 0,
    required String title,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (_) => PlaceGalleryZoomDialog(
        images: images,
        initialIndex: initialIndex,
        title: title,
      ),
    );
  }

  @override
  State<PlaceGalleryZoomDialog> createState() => _PlaceGalleryZoomDialogState();
}

class _PlaceGalleryZoomDialogState extends State<PlaceGalleryZoomDialog> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // 1. Zoomable Gallery
          if (AppTheme.isTestMode)
            Center(
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Gallery Photo ${_currentIndex + 1}/${widget.images.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            )
          else
            PhotoViewGallery.builder(
              pageController: _pageController,
              itemCount: widget.images.length,
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: CachedNetworkImageProvider(widget.images[index]),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2.5,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image_rounded, color: Colors.white, size: 64),
                  ),
                );
              },
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              loadingBuilder: (context, event) => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryViolet),
              ),
              backgroundDecoration: const BoxDecoration(color: Colors.transparent),
            ),

          // 2. Top Bar (Title & Counter & Close button)
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (widget.images.length > 1)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                IconButton(
                  key: const Key('close_gallery_zoom_dialog'),
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

