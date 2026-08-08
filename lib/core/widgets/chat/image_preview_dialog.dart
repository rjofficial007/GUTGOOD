import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ImagePreviewDialog extends StatefulWidget {
  const ImagePreviewDialog({
    super.key,
    this.imageUrls = const [],
    this.localImages,
    required this.initialIndex,
    required this.heroTag,
  });

  final List<String> imageUrls;
  final List<Uint8List>? localImages;
  final int initialIndex;
  final String heroTag;

  @override
  State<ImagePreviewDialog> createState() => _ImagePreviewDialogState();
}

class _ImagePreviewDialogState extends State<ImagePreviewDialog> {
  late PageController _pageController;
  late int _currentIndex;
  double _dragOffset = 0;
  bool _isDragging = false;

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
    final hasLocal =
        widget.localImages != null && widget.localImages!.isNotEmpty;
    final count = hasLocal ? widget.localImages!.length : widget.imageUrls.length;
    final opacity = (1 - (_dragOffset.abs() / 300)).clamp(0.0, 1.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // iOS Style Blurred Background
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 10 * opacity,
                    sigmaY: 10 * opacity,
                  ),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.4 * opacity),
                  ),
                ),
              ),
            ),
            // Centered Image Dialog
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 80,
                ),
                child: GestureDetector(
                  onVerticalDragStart: (_) => setState(() => _isDragging = true),
                  onVerticalDragUpdate: (details) {
                    setState(() => _dragOffset += details.delta.dy);
                  },
                  onVerticalDragEnd: (details) {
                    if (_dragOffset.abs() > 80 ||
                        details.primaryVelocity!.abs() > 400) {
                      Navigator.of(context).pop();
                    } else {
                      setState(() {
                        _dragOffset = 0;
                        _isDragging = false;
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: _isDragging ? Duration.zero : const Duration(milliseconds: 200),
                    transform: Matrix4.translationValues(0, _dragOffset, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              color: Colors.black,
                              child: AspectRatio(
                                aspectRatio: 1, // iOS Style Square-ish Preview
                                child: PageView.builder(
                                  itemCount: count,
                                  controller: _pageController,
                                  onPageChanged: (index) =>
                                      setState(() => _currentIndex = index),
                                  physics: _isDragging
                                      ? const NeverScrollableScrollPhysics()
                                      : const BouncingScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    final image = hasLocal
                                        ? Image.memory(
                                            widget.localImages![index],
                                            fit: BoxFit.cover,
                                          )
                                        : CachedNetworkImage(
                                            imageUrl: widget.imageUrls[index],
                                            fit: BoxFit.cover,
                                            placeholder: (_, _) => const Center(
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            errorWidget: (_, _, _) => const Icon(
                                                  Icons.error,
                                                  color: Colors.white,
                                                ),
                                          );

                                    return InteractiveViewer(
                                      minScale: 1.0,
                                      maxScale: 3.0,
                                      child: Center(
                                        child: index == widget.initialIndex
                                            ? Hero(
                                                tag: widget.heroTag,
                                                child: image,
                                              )
                                            : image,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (count > 1) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              count,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: _currentIndex == index ? 16 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _currentIndex == index
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Close Button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Opacity(
                    opacity: opacity,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
