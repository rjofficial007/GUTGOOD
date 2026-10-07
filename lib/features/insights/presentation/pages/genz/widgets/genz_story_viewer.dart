import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../genz_theme.dart';
import 'genz_tile.dart';

class GenzStorySlide {
  const GenzStorySlide({
    required this.label,
    required this.title,
    required this.subtitle,
    required this.artAsset,
    required this.tone,
    required this.ctaText,
    required this.ctaRoute,
    this.isHugeNumber = false,
  });

  final String label;
  final String title;
  final String subtitle;
  final String artAsset;
  final GenzTone tone;
  final String ctaText;
  final String ctaRoute;
  final bool isHugeNumber;
}

class GenzStoryViewer extends StatefulWidget {
  const GenzStoryViewer({
    super.key,
    required this.storyName,
    required this.slides,
  });

  final String storyName;
  final List<GenzStorySlide> slides;

  static void show(BuildContext context, String storyName, List<GenzStorySlide> slides) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Story',
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) => GenzStoryViewer(storyName: storyName, slides: slides),
      transitionBuilder: (context, anim1, anim2, child) => FadeTransition(
        opacity: anim1,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(
            CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  State<GenzStoryViewer> createState() => _GenzStoryViewerState();
}

class _GenzStoryViewerState extends State<GenzStoryViewer> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  int _currentIndex = 0;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextSlide();
      }
    });

    _startProgress();
  }

  void _startProgress() {
    _progressController.forward(from: 0.0);
  }

  void _nextSlide() {
    if (_currentIndex < widget.slides.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
      _startProgress();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _prevSlide() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
      _startProgress();
    } else {
      _startProgress();
    }
  }

  void _pauseProgress() {
    if (!_isPaused) {
      setState(() => _isPaused = true);
      _progressController.stop();
    }
  }

  void _resumeProgress() {
    if (_isPaused) {
      setState(() => _isPaused = false);
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Color _getToneBg(GenzTone tone) {
    switch (tone) {
      case GenzTone.lime: return GenzColors.lime;
      case GenzTone.pink: return GenzColors.pink;
      case GenzTone.blue: return GenzColors.blue;
      case GenzTone.orange: return GenzColors.orange;
      case GenzTone.lilac: return GenzColors.lilac;
      case GenzTone.butter: return GenzColors.butter;
      case GenzTone.ink: return const Color(0xFF1A1A27);
    }
  }

  Color _getToneFg(GenzTone tone) {
    switch (tone) {
      case GenzTone.blue:
      case GenzTone.ink:
        return Colors.white;
      default:
        return GenzColors.ink;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSlide = widget.slides[_currentIndex];
    final bgColor = _getToneBg(currentSlide.tone);
    final fgColor = _getToneFg(currentSlide.tone);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onLongPressStart: (_) => _pauseProgress(),
          onLongPressEnd: (_) => _resumeProgress(),
          onTapUp: (details) {
            final screenWidth = MediaQuery.of(context).size.width;
            if (details.globalPosition.dx < screenWidth * 0.35) {
              _prevSlide();
            } else {
              _nextSlide();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            color: bgColor,
            child: Stack(
              children: [
                // Top Right Background Art Image
                Positioned(
                  right: -40,
                  top: 240,
                  child: Transform.rotate(
                    angle: -0.12,
                    child: Image.asset(
                      'assets/images/${currentSlide.artAsset}',
                      width: 280,
                      height: 280,
                    ),
                  ),
                ),

                // Main Slide Page View
                PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.slides.length,
                  itemBuilder: (context, index) {
                    final slide = widget.slides[index];
                    final slideFg = _getToneFg(slide.tone);

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(24, 90, 24, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slide.label.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'InterTight',
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.4,
                              color: slideFg.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            slide.title,
                            style: TextStyle(
                              fontFamily: 'InterTight',
                              fontSize: slide.isHugeNumber ? 130 : 48,
                              fontWeight: FontWeight.w900,
                              letterSpacing: slide.isHugeNumber ? -8 : -2.5,
                              height: 0.9,
                              color: slideFg,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            slide.subtitle,
                            style: TextStyle(
                              fontFamily: 'InterTight',
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                              color: slideFg.withOpacity(0.85),
                            ),
                          ),
                          const Spacer(),

                          // Bottom Row Actions & CTA
                          Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    height: 38,
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: slideFg == Colors.white ? Colors.white.withOpacity(0.16) : Colors.white.withOpacity(0.55),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(LucideIcons.share, size: 16, color: slideFg),
                                        const SizedBox(width: 6),
                                        Text('share', style: TextStyle(color: slideFg, fontSize: 13, fontWeight: FontWeight.w800, fontFamily: 'InterTight')),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  context.push(slide.ctaRoute);
                                },
                                child: Container(
                                  height: 56,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: slide.tone == GenzTone.ink || slide.tone == GenzTone.blue ? GenzColors.lime : GenzColors.ink,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        slide.ctaText,
                                        style: TextStyle(
                                          color: slide.tone == GenzTone.ink || slide.tone == GenzTone.blue ? GenzColors.ink : Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.3,
                                          fontFamily: 'InterTight',
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        LucideIcons.arrowRight,
                                        color: slide.tone == GenzTone.ink || slide.tone == GenzTone.blue ? GenzColors.ink : Colors.white,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Top Progress Bars & Header Controls
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: [
                      Row(
                        children: List.generate(
                          widget.slides.length,
                          (index) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  height: 4,
                                  color: Colors.white.withOpacity(0.35),
                                  child: index == _currentIndex
                                      ? AnimatedBuilder(
                                          animation: _progressController,
                                          builder: (context, child) => FractionallySizedBox(
                                            alignment: Alignment.centerLeft,
                                            widthFactor: _progressController.value,
                                            child: Container(color: Colors.white),
                                          ),
                                        )
                                      : Container(
                                          color: index < _currentIndex ? Colors.white : Colors.transparent,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            height: 34,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  widget.storyName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'InterTight',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.x, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
