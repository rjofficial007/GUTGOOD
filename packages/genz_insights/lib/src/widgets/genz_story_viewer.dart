import 'package:flutter/material.dart';
import 'package:genz_insights/src/genz_theme.dart';
import 'package:genz_insights/src/widgets/genz_share.dart';
import 'package:genz_insights/src/widgets/genz_tile.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class GenzStorySlide {
  const GenzStorySlide({
    required this.label,
    required this.title,
    required this.subtitle,
    required this.artAsset,
    required this.tone,
    required this.ctaText,
    required this.ctaRoute,
    this.detailId,
    this.toastText,
    this.isHugeNumber = false,
    this.boldSubtitle,
  });

  final String label;
  final String title;
  final String subtitle;
  final String artAsset;
  final GenzTone tone;
  final String ctaText;
  final String ctaRoute;
  final String? detailId;
  final String? toastText;
  final bool isHugeNumber;
  final String? boldSubtitle;
}

class GenzStoryViewer extends StatefulWidget {
  const GenzStoryViewer({super.key, required this.storyName, required this.slides, this.onNavigate, this.onOpenRoute});

  final String storyName;
  final List<GenzStorySlide> slides;
  final ValueChanged<String>? onNavigate;
  final ValueChanged<String>? onOpenRoute;

  static void show(BuildContext context, String storyName, List<GenzStorySlide> slides, {ValueChanged<String>? onNavigate, ValueChanged<String>? onOpenRoute}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Story',
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) => GenzStoryViewer(storyName: storyName, slides: slides, onNavigate: onNavigate, onOpenRoute: onOpenRoute),
      transitionBuilder: (context, anim1, anim2, child) => FadeTransition(
        opacity: anim1,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
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
    _progressController = AnimationController(vsync: this, duration: const Duration(seconds: 5));

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
      _pageController.animateToPage(_currentIndex, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
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
      _pageController.animateToPage(_currentIndex, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
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
      case GenzTone.lime:
        return GenzColors.lime;
      case GenzTone.pink:
        return GenzColors.pink;
      case GenzTone.blue:
        return GenzColors.blue;
      case GenzTone.orange:
        return GenzColors.orange;
      case GenzTone.lilac:
        return GenzColors.lilac;
      case GenzTone.butter:
        return GenzColors.butter;
      case GenzTone.ink:
        return const Color(0xFF1A1A27);
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

  Color _getToneFg2(GenzTone tone) => switch (tone) {
    GenzTone.blue || GenzTone.ink => Colors.white.withValues(alpha: 0.78),
    _ => GenzColors.ink.withValues(alpha: 0.62),
  };

  String get _storyIconAsset => switch (widget.storyName) {
    'today' => 'a-gauge.webp',
    'patterns' => 'a-digestion.webp',
    'foods' => 'a-bowl.webp',
    'week' => 'a-calendar.webp',
    'streak' => 'a-flame.webp',
    _ => 'a-bulb.webp',
  };

  List<InlineSpan> _storySubtitleSpans(GenzStorySlide slide) {
    final bold = slide.boldSubtitle;
    if (bold == null || !slide.subtitle.contains(bold)) return [TextSpan(text: slide.subtitle)];
    final start = slide.subtitle.indexOf(bold);
    final end = start + bold.length;
    return [
      if (start > 0) TextSpan(text: slide.subtitle.substring(0, start)),
      TextSpan(
        text: bold,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      if (end < slide.subtitle.length) TextSpan(text: slide.subtitle.substring(end)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final currentSlide = widget.slides[_currentIndex];
    final bgColor = _getToneBg(currentSlide.tone);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
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
          decoration: BoxDecoration(color: bgColor),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.2,
                stops: const [0, 0.58],
                colors: [Colors.white.withValues(alpha: 0.34), Colors.transparent],
                transform: const GenzCssRadialTransform(verticalRadius: 0.7),
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    right: -30,
                    top: currentSlide.isHugeNumber ? 300 : 330,
                    child: Transform.rotate(angle: -0.122, child: GenzArt(asset: 'assets/images/${currentSlide.artAsset}', width: 270, height: 270)),
                  ),

                  // Main Slide Page View
                  PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.slides.length,
                    itemBuilder: (context, index) {
                      final slide = widget.slides[index];
                      final slideFg = _getToneFg(slide.tone);

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxHeight < 520 || MediaQuery.textScalerOf(context).scale(16) > 18;
                          final body = Padding(
                            padding: const EdgeInsets.fromLTRB(22, 70, 22, 30),
                            child: Column(
                              mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 14),
                                Text(
                                  slide.label.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: GenzFonts.primary,
                                    fontFamilyFallback: GenzFonts.fallback,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.4,
                                    color: slideFg,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  slide.title,
                                  style: TextStyle(
                                    fontFamily: GenzFonts.primary,
                                    fontFamilyFallback: GenzFonts.fallback,
                                    fontSize: slide.isHugeNumber ? 150 : 58,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: slide.isHugeNumber ? -9 : -3,
                                    height: slide.isHugeNumber ? 0.8 : 0.92,
                                    color: slideFg,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 280),
                                  child: Text.rich(
                                    TextSpan(
                                      style: TextStyle(
                                        fontFamily: GenzFonts.primary,
                                        fontFamilyFallback: GenzFonts.fallback,
                                        fontSize: 19,
                                        fontWeight: FontWeight.w700,
                                        height: 1.3,
                                        color: _getToneFg2(slide.tone),
                                      ),
                                      children: _storySubtitleSpans(slide),
                                    ),
                                  ),
                                ),
                                if (compact) const SizedBox(height: 20) else const Spacer(),

                                // Bottom Row Actions & CTA
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () => copyGenzShare(context, text: '${slide.title}\n${slide.subtitle}'),
                                          child: Container(
                                            height: 36,
                                            padding: const EdgeInsets.symmetric(horizontal: 13),
                                            decoration: BoxDecoration(
                                              color: slideFg == Colors.white ? Colors.white.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.55),
                                              borderRadius: BorderRadius.circular(100),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(LucideIcons.upload, size: 16, color: slideFg),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'share',
                                                  style: TextStyle(color: slideFg, fontSize: 13, fontWeight: FontWeight.w800, fontFamily: GenzFonts.primary, fontFamilyFallback: GenzFonts.fallback),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    GestureDetector(
                                      onTap: () {
                                        final destination = slide.detailId;
                                        final onNavigate = widget.onNavigate;
                                        if (destination != null && onNavigate != null) {
                                          Navigator.of(context).pop();
                                          onNavigate(destination);
                                        } else if (slide.toastText != null) {
                                          showGenzToast(context, slide.toastText!);
                                        } else {
                                          final openRoute = widget.onOpenRoute;
                                          if (openRoute == null) {
                                            showGenzToast(context, 'connect onOpenRoute to handle ${slide.ctaRoute}');
                                            return;
                                          }
                                          Navigator.of(context).pop();
                                          openRoute(slide.ctaRoute);
                                        }
                                      },
                                      child: Container(
                                        height: 54,
                                        width: double.infinity,
                                        decoration: BoxDecoration(color: GenzColors.tx(context), borderRadius: BorderRadius.circular(100)),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              slide.ctaText,
                                              style: TextStyle(
                                                color: GenzColors.scaffoldBg(context),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: -0.3,
                                                fontFamily: GenzFonts.primary,
                                                fontFamilyFallback: GenzFonts.fallback,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(LucideIcons.arrowRight, color: GenzColors.scaffoldBg(context), size: 18),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                          if (compact) {
                            return SingleChildScrollView(physics: const ClampingScrollPhysics(), child: body);
                          }
                          return body;
                        },
                      );
                    },
                  ),

                  // Top Progress Bars & Header Controls
                  Positioned(
                    top: 14,
                    left: 20,
                    right: 20,
                    child: Column(
                      children: [
                        Row(
                          children: List.generate(
                            widget.slides.length,
                            (index) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    height: 4,
                                    color: Colors.white.withValues(alpha: 0.35),
                                    child: index == _currentIndex
                                        ? AnimatedBuilder(
                                            animation: _progressController,
                                            builder: (context, child) => FractionallySizedBox(
                                              alignment: Alignment.centerLeft,
                                              widthFactor: _progressController.value,
                                              child: Container(color: Colors.white),
                                            ),
                                          )
                                        : Container(color: index < _currentIndex ? Colors.white : Colors.transparent),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              height: 34,
                              padding: const EdgeInsets.only(left: 5, right: 12),
                              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(100)),
                              child: Row(
                                children: [
                                  GenzArt(asset: 'assets/images/$_storyIconAsset', width: 24, height: 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.storyName,
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, fontFamily: GenzFonts.primary, fontFamilyFallback: GenzFonts.fallback),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), shape: BoxShape.circle),
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
      ),
    );
  }
}
