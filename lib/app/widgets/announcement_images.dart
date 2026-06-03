import 'package:flutter/material.dart';

/// Shared announcement image gallery.
///
/// Shows one image at a time at its **natural aspect ratio** using
/// [BoxFit.contain] so the full image is always visible without cropping.
/// The image fills the card width (width constraint comes from the parent
/// card layout) and the height follows the image's intrinsic dimensions.
///
/// Multiple images can be navigated by swiping (horizontal drag) or tapping
/// the dot indicators.
///
/// Used in three places (parent dashboard, coach dashboard, announcements
/// page) to keep the image presentation consistent.
class AnnouncementImages extends StatefulWidget {
  const AnnouncementImages({
    super.key,
    required this.imageUrls,
    this.onImageTap,
  });

  final List<String> imageUrls;

  /// Optional tap handler. When provided the image is wrapped in a
  /// [GestureDetector] so the detail view can open a full-screen viewer.
  final void Function(int index)? onImageTap;

  @override
  State<AnnouncementImages> createState() => _AnnouncementImagesState();
}

class _AnnouncementImagesState extends State<AnnouncementImages> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) return const SizedBox.shrink();

    // Guard against _currentPage going out of bounds if imageUrls changes.
    if (_currentPage >= widget.imageUrls.length) {
      _currentPage = widget.imageUrls.length - 1;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCurrentImage(),
        if (widget.imageUrls.length > 1) _buildDots(context),
      ],
    );
  }

  Widget _buildCurrentImage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GestureDetector(
          onTap: widget.onImageTap != null
              ? () => widget.onImageTap!(_currentPage)
              : null,
          onHorizontalDragEnd: (details) {
            // Swipe to navigate between multiple images.
            if (widget.imageUrls.length <= 1) return;
            final velocity = details.primaryVelocity ?? 0;
            if (velocity < -200 &&
                _currentPage < widget.imageUrls.length - 1) {
              setState(() => _currentPage++);
            } else if (velocity > 200 && _currentPage > 0) {
              setState(() => _currentPage--);
            }
          },
          child: Image.network(
            widget.imageUrls[_currentPage],
            // Contain always shows the full image without cropping.
            fit: BoxFit.contain,
            // Fill the card width; height follows intrinsic aspect ratio.
            width: double.infinity,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey[100],
              height: 200,
              child: const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Colors.grey,
                  size: 48,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDots(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          widget.imageUrls.length,
          (i) => GestureDetector(
            onTap: () => setState(() => _currentPage = i),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: _currentPage == i ? 8 : 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == i
                    ? Theme.of(context).primaryColor
                    : Colors.grey[400],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
