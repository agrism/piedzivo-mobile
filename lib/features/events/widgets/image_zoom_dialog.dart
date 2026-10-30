import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import '../../../core/theme/app_colors.dart';

class ImageZoomDialog extends StatelessWidget {
  final String imageUrl;
  final String title;

  const ImageZoomDialog({
    super.key,
    required this.imageUrl,
    required this.title,
  });

  static Future<void> show(BuildContext context, {required String imageUrl, required String title}) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => ImageZoomDialog(imageUrl: imageUrl, title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Zoomable photo view
          Center(
            child: PhotoView(
              imageProvider: CachedNetworkImageProvider(imageUrl),
              backgroundDecoration: const BoxDecoration(color: Colors.transparent),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2.5,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.broken_image_rounded, color: Colors.white, size: 64),
              ),
              loadingBuilder: (context, event) => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryViolet),
              ),
            ),
          ),

          // Title & close bar
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
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

