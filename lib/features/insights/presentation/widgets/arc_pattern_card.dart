import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/insight_bento_theme.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/pattern_style.dart';
import 'package:gutgood/features/insights/presentation/widgets/pattern_grid.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

/// Extension to compute the percentage of a [BodyPattern].
extension BodyPatternPercentage on BodyPattern {
  /// Returns a percentage only when measured evidence exists.
  int? get percentage {
    final ratio = evidenceRatio;
    if (ratio.isFinite && ratio > 0) return (ratio.clamp(0.0, 1.0) * 100).round();
    final total = positiveCount + negativeCount;
    if (total <= 0) return null;
    return ((positiveCount / total) * 100).clamp(0, 100).round();
  }
}

/// A sleek, glowing arc gauge card displaying an observed pattern.
///
/// Features:
/// - Top header with pattern icon, title, and action diagonal arrow (`↗`).
/// - Large semi-circular glowing arc gauge with a floating indicator dot.
/// - Big center percentage display and translucent glass status pill.
/// - Ambient top-right radial glow matching the pattern's theme color.
class ArcPatternCard extends StatelessWidget {
  const ArcPatternCard({super.key, required this.pattern, this.onTap});

  final BodyPattern pattern;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accentColor = patternAccent(pattern.type);
    final toneColor = patternTone(pattern.type);
    final percent = pattern.percentage;
    final progress = percent == null ? 0.0 : (percent / 100.0).clamp(0.0, 1.0);
    final radius = 18.w;

    return Semantics(
      button: true,
      child: Container(
        height: 215.w,
        width: double.infinity,
        decoration: BoxDecoration(color: PatternSurface.tone(context, accentColor, toneColor), borderRadius: BorderRadius.circular(radius), boxShadow: PatternSurface.shadow(context)),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap ?? () => context.push(AppRoutes.patternDetail, extra: pattern),
            borderRadius: BorderRadius.circular(radius),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Stack(
                children: [
                  // 1. Background Arc Gauge Custom Painter
                  Positioned.fill(
                    top: -500,
                    child: CustomPaint(
                      painter: _PatternArcGaugePainter(progress: progress, accentColor: accentColor, isDark: PatternSurface.isDark(context)),
                    ),
                  ),

                  // 2. Card Content Layout
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Header Row
                        Row(
                          children: [
                            Container(
                              width: 32.w,
                              height: 32.w,
                              decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(10.w)),
                              child: Center(
                                child: Icon(patternIcon(pattern.type), color: Colors.white, size: 17.w),
                              ),
                            ),
                            Gap.w10,
                            Expanded(
                              child: Text(
                                pattern.trigger.isNotEmpty ? pattern.trigger : patternName(pattern.type),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 16.sp, fontWeight: FontWeight.w800, color: PatternSurface.ink(context), letterSpacing: -0.2),
                              ),
                            ),
                            Container(
                              width: 30.w,
                              height: 30.w,
                              decoration: BoxDecoration(color: PatternSurface.chipBackground(context), shape: BoxShape.circle),
                              child: Center(
                                child: Icon(Icons.north_east_rounded, color: accentColor, size: 16.w),
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Center Content inside Arc
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Confidence level',
                              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w600, color: PatternSurface.muted(context)),
                            ),
                            Gap.h4,
                            Text(
                              percent == null ? 'Not enough evidence' : pattern.evidenceRatio > 0 ? '$percent% match' : '$percent% of observations',
                              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 36.sp, fontWeight: FontWeight.w800, height: 1.0, letterSpacing: -1.0, color: accentColor),
                            ),
                            Gap.h8,
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.w),
                              decoration: BoxDecoration(
                                color: PatternSurface.chipBackground(context),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                pattern.confidence.isEmpty ? 'Confidence unavailable' : pattern.confidence,
                                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: accentColor),
                              ),
                            ),
                          ],
                        ),

                        Gap.h10,
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

/// Custom painter for rendering the glowing curved arch and floating dot indicator.
class _PatternArcGaugePainter extends CustomPainter {
  const _PatternArcGaugePainter({required this.progress, required this.accentColor, required this.isDark});

  final double progress;
  final Color accentColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width / 2, size.height * 1.05);
    final radius = size.width * 0.52;

    const startAngle = math.pi * 1.18;
    const sweepAngle = math.pi * 0.64;

    // 1. Background Arc Track
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..color = accentColor.withValues(alpha: isDark ? 0.22 : 0.25);

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, trackPaint);

    // 2. Active Progress Arc
    final activeSweep = sweepAngle * progress.clamp(0.01, 1.0);
    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..color = accentColor;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, activeSweep, false, activePaint);

    // 3. Floating Dot Indicator at current progress
    final dotAngle = startAngle + activeSweep;
    final dotX = center.dx + radius * math.cos(dotAngle);
    final dotY = center.dy + radius * math.sin(dotAngle);
    final dotPos = Offset(dotX, dotY);

    // Outer Glow Halo, Main Dot & Inner Center Dot
    canvas
      ..drawCircle(dotPos, 7.0, Paint()..color = accentColor.withValues(alpha: 0.35))
      ..drawCircle(dotPos, 4.5, Paint()..color = accentColor)
      ..drawCircle(dotPos, 2.0, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_PatternArcGaugePainter old) => old.progress != progress || old.accentColor != accentColor || old.isDark != isDark;
}

/// A carousel widget displaying multiple pattern arc cards with a smooth dot indicator.
class PatternCarouselWidget extends StatefulWidget {
  const PatternCarouselWidget({super.key, required this.patterns, this.onPatternTap});

  final List<BodyPattern> patterns;
  final void Function(BodyPattern pattern)? onPatternTap;

  @override
  State<PatternCarouselWidget> createState() => _PatternCarouselWidgetState();
}

class _PatternCarouselWidgetState extends State<PatternCarouselWidget> {
  late final PageController _pageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.patterns.isEmpty) {
      return const SizedBox.shrink();
    }

    final activePattern = widget.patterns[_currentPageIndex.clamp(0, widget.patterns.length - 1)];
    final activeColor = patternAccent(activePattern.type);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 222.w,
          child: PageView.builder(
            clipBehavior: Clip.none,
            controller: _pageController,
            itemCount: widget.patterns.length,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final pattern = widget.patterns[index];
              return ArcPatternCard(
                pattern: pattern,
                onTap: () {
                  if (widget.onPatternTap != null) {
                    widget.onPatternTap!(pattern);
                  } else {
                    context.push(AppRoutes.patternDetail, extra: pattern);
                  }
                },
              );
            },
          ),
        ),
        if (widget.patterns.length > 1) ...[
          Gap.h12,
          SmoothPageIndicator(
            controller: _pageController,
            count: widget.patterns.length,
            effect: ExpandingDotsEffect(dotWidth: 8.w, dotHeight: 8.w, expansionFactor: 3, activeDotColor: activeColor, dotColor: activeColor.withValues(alpha: 0.25)),
          ),
        ],
      ],
    );
  }
}
