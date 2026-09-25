import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/models/insights/body_pattern.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/utils/gut_score_utils.dart';
import 'package:gutgood/core/utils/image_utils.dart';
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class SuperGutScoreCard extends StatelessWidget {
  const SuperGutScoreCard({super.key, required this.score, this.streak = 0, this.qualityScore, this.loggedCount = 0, this.onTap});

  final int score;
  final int streak;
  final int? qualityScore;
  final int loggedCount;
  final VoidCallback? onTap;

  static const Color white = Color(0xFFF4F4F4);
  static const Color green = Color(0xFF27F15B);

  @override
  Widget build(BuildContext context) {
    final band = GutScoreBand.fromScore(score);
    final statusLabel = band.label;
    final statusColor = band.color;

    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF202126), Color(0xFF141414)]),
          border: Border.all(color: Colors.white.withAlpha(7)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 28, 18, 20),
          child: Column(
            children: [
              SizedBox(
                height: 160,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: GutTickGaugePainter(progress: (score / 100).clamp(0.0, 1.0))),
                    ),
                    Positioned.fill(
                      child: Align(
                        alignment: const Alignment(0.0, 0.8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$score',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: white, fontSize: 60, height: 0.95, fontWeight: FontWeight.w300, letterSpacing: -2),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  statusLabel,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white.withAlpha(184), fontSize: 12, fontWeight: FontWeight.w400),
                                ),
                                const SizedBox(width: 5),
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'G U T G O O D   S C O R E',
                style: TextStyle(color: Colors.white.withAlpha(210), fontSize: 11, letterSpacing: 1.8, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              Text('Today', style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 12)),
              const SizedBox(height: 17),
              Container(height: 1, color: Colors.white.withAlpha(14)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: SuperMetric(title: 'Quality', value: '${qualityScore ?? score}%', showDot: true),
                  ),
                  Expanded(
                    child: SuperMetric(title: 'Consistency', value: '${streak}d streak', showDot: true),
                  ),
                  Expanded(
                    child: SuperMetric(title: 'Logged', value: '$loggedCount items', showDot: true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SuperMetric extends StatelessWidget {
  const SuperMetric({super.key, required this.title, required this.value, this.showDot = false, this.dotColor = const Color(0xFF27F15B), this.maxLines = 1});

  final String title;
  final String value;
  final bool showDot;
  final Color dotColor;
  final int maxLines;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(title, style: TextStyle(color: Colors.white.withAlpha(192), fontSize: 13)),
      const SizedBox(height: 7),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w400),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showDot) ...[
            const SizedBox(width: 5),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
          ],
        ],
      ),
    ],
  );
}

/// ---------------------------------------------------------------------------
/// SUPER FOOD GAUGE CARD
/// ---------------------------------------------------------------------------
class SuperFoodGaugeCard extends StatefulWidget {
  const SuperFoodGaugeCard({super.key, required this.title, required this.label, required this.score, required this.statusColor, this.foods = const [], this.onTap});

  final String title;
  final String label;
  final int score;
  final Color statusColor;
  final List<SuperCyclerItemData> foods;
  final VoidCallback? onTap;

  static const Color white = Color(0xFFF4F4F4);

  @override
  State<SuperFoodGaugeCard> createState() => _SuperFoodGaugeCardState();
}

class _SuperFoodGaugeCardState extends State<SuperFoodGaugeCard> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = widget.foods.length;
    final hasFoods = totalPages > 0;

    final currentFood = hasFoods ? widget.foods[_currentIndex] : null;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 350,

        // IMPORTANT:
        // The image is clipped directly to these rounded corners.
        clipBehavior: Clip.antiAlias,

        decoration: BoxDecoration(borderRadius: BorderRadius.circular(22)),

        child: Stack(
          fit: StackFit.expand,
          children: [
            // ============================================================
            // 1. FULL-BLEED FOOD IMAGE
            // ============================================================
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),

                child: Stack(
                  key: ValueKey('food_bg_full_${_currentIndex}_${currentFood?.name}'),

                  fit: StackFit.expand,

                  children: [
                    // ----------------------------------------------------
                    // FOOD IMAGE
                    // ----------------------------------------------------
                    if (currentFood != null)
                      CachedNetworkImage(
                        imageUrl: (currentFood.imageUrl != null && currentFood.imageUrl!.isNotEmpty) ? currentFood.imageUrl! : getDynamicImageUrl(currentFood.name),

                        // THIS MAKES THE IMAGE COVER THE ENTIRE CARD
                        fit: BoxFit.cover,

                        width: double.infinity,
                        height: double.infinity,

                        fadeInDuration: const Duration(milliseconds: 300),

                        placeholder: (context, url) => Container(color: Colors.black),

                        errorWidget: (context, url, error) => Container(
                          color: widget.statusColor.withAlpha(40),
                          child: Icon(widget.title.toUpperCase().contains('HEALING') ? Icons.auto_awesome : Icons.warning_amber_rounded, color: widget.statusColor.withAlpha(120), size: 48),
                        ),
                      )
                    // ----------------------------------------------------
                    // NO FOOD IMAGE
                    // ----------------------------------------------------
                    else
                      Container(color: widget.statusColor.withAlpha(20)),

                    // ====================================================
                    // 2. IMAGE DARK OVERLAY
                    // ====================================================
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black.withAlpha(45), Colors.black.withAlpha(90), Colors.black.withAlpha(235)],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ============================================================
            // 3. STATIC HEADER
            // ============================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Column(
                children: [
                  // ------------------------------------------------------
                  // GAUGE
                  // ------------------------------------------------------
                  SizedBox(
                    height: 150,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(painter: GutTickGaugePainter(progress: (widget.score / 100).clamp(0.0, 1.0))),
                        ),

                        Positioned.fill(
                          child: Align(
                            alignment: const Alignment(0.0, 0.8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // SCORE
                                Text(
                                  '${widget.score}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: SuperFoodGaugeCard.white, fontSize: 56, height: 0.95, fontWeight: FontWeight.w300, letterSpacing: -2),
                                ),

                                const SizedBox(height: 4),

                                // LABEL + STATUS
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      widget.label.toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 11, fontWeight: FontWeight.w500),
                                    ),

                                    const SizedBox(width: 5),

                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(color: widget.statusColor, shape: BoxShape.circle),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  // ------------------------------------------------------
                  // TITLE
                  // ------------------------------------------------------
                  Text(
                    widget.title.toUpperCase().split('').join(' '),
                    style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 8),

                  // ------------------------------------------------------
                  // ITEMS COUNT
                  // ------------------------------------------------------
                  Text(hasFoods ? '${widget.foods.length} items detected' : 'No items', style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 12)),

                  const SizedBox(height: 10),

                  // ------------------------------------------------------
                  // DIVIDER
                  // ------------------------------------------------------
                  Container(height: 1, width: 40, color: Colors.white.withAlpha(20)),
                ],
              ),
            ),

            // ============================================================
            // 4. PAGE VIEW
            // ============================================================
            Positioned.fill(
              child: PageView.builder(
                controller: _pageController,
                itemCount: totalPages > 0 ? totalPages : 1,

                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },

                itemBuilder: (context, index) {
                  final food = hasFoods ? widget.foods[index] : null;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Spacer(flex: 5),

                        // =================================================
                        // FOOD INFORMATION
                        // =================================================
                        if (food != null) ...[
                          // FOOD NAME
                          Text(
                            food.name.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.8),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 6),

                          // FOOD EFFECT
                          Text(
                            food.effect,
                            style: TextStyle(color: Colors.white.withAlpha(210), fontSize: 15, height: 1.3, fontWeight: FontWeight.w400),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ]
                        // =================================================
                        // NO DATA
                        // =================================================
                        else ...[
                          Text(
                            'NOT ENOUGH DATA',
                            style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                        ],

                        const SizedBox(height: 60),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ============================================================
            // 5. PAGE INDICATOR
            // ============================================================
            if (totalPages > 1)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: SmoothPageIndicator(
                    controller: _pageController,
                    count: totalPages,
                    effect: ScrollingDotsEffect(activeDotColor: widget.statusColor, dotColor: Colors.white.withAlpha(40), dotHeight: 5, dotWidth: 5, spacing: 8),
                  ),
                ),
              ),

            // ============================================================
            // 6. SWIPE HINT
            // ============================================================
            if (totalPages > 1 && _currentIndex == 0)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(child: Icon(Icons.chevron_right, color: Colors.white.withAlpha(30), size: 24)),
              ),
          ],
        ),
      ),
    );
  }
}

class SuperAutopilotCard extends StatelessWidget {
  const SuperAutopilotCard({super.key, this.title = 'GUTGOOD RECAP', this.description, this.healingCount = 0, this.triggerCount = 0, this.onTap});

  final String title;
  final String? description;
  final int healingCount;
  final int triggerCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const defaultDesc = 'While you logged, GutGood Autopilot analyzed your meals and signals to find active body patterns.';

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        // Extra bottom space for the cards underneath.
        padding: const EdgeInsets.only(bottom: 8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ============================================================
            // MIDDLE CARD — LAYER 2
            // ============================================================
            const Positioned(
              left: 7,
              right: 7,
              bottom: -8,
              child: _StackCard(
                borderRadius: 21,
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF4A5580), Color(0xFF3A4266)]),
              ),
            ),

            // ============================================================
            // MAIN CARD — LAYER 1
            // ============================================================
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF242A47), Color(0xFF1E233B)]),
                border: Border.all(color: Colors.white.withAlpha(8), width: 1),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(45), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ======================================================
                  // TITLE
                  // ======================================================
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(color: const Color(0xFF9CB7F7).withAlpha(230), fontSize: 11, letterSpacing: 1.25, fontWeight: FontWeight.w500),
                  ),

                  const SizedBox(height: 12),

                  // ======================================================
                  // DESCRIPTION
                  // ======================================================
                  Text(
                    description ?? defaultDesc,
                    style: TextStyle(color: Colors.white.withAlpha(222), fontSize: 15, height: 1.45, fontWeight: FontWeight.w400),
                  ),

                  const SizedBox(height: 14),

                  // ======================================================
                  // METRICS
                  // ======================================================
                  Row(
                    children: [
                      _RecapMetric(title: 'Healing foods', value: '↑ $healingCount', dotColor: const Color(0xFF27F15B)),

                      const SizedBox(width: 34),

                      _RecapMetric(title: 'Triggers', value: '↓ $triggerCount', dotColor: const Color(0xFFE9579A)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================================================
// STACK BACKGROUND CARD
// ========================================================================

class _StackCard extends StatelessWidget {
  const _StackCard({required this.gradient, required this.borderRadius});

  final Gradient gradient;
  final double borderRadius;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      height: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: gradient,
        border: Border.all(color: Colors.white.withAlpha(5), width: 1),
      ),
    ),
  );
}

class _RecapMetric extends StatelessWidget {
  const _RecapMetric({required this.title, required this.value, required this.dotColor});

  final String title;
  final String value;
  final Color dotColor;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(title, style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 14)),
      const SizedBox(width: 6),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
      const SizedBox(width: 5),
      Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
      ),
    ],
  );
}

/// ---------------------------------------------------------------------------
/// SUPER PHYSICAL GOAL CARD
/// ---------------------------------------------------------------------------
class SuperPhysicalGoalCard extends StatelessWidget {
  const SuperPhysicalGoalCard({super.key, required this.title, required this.subtitle, required this.label, required this.icon, required this.color, this.progress = 0.50, this.onTap});

  final String title;
  final String subtitle;
  final String label;
  final IconData icon;
  final Color color;
  final double progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 140,
      width: double.maxFinite,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color.lerp(const Color(0xFF1A1C21), color, 0.15)!, Color.lerp(const Color(0xFF0F1012), color, 0.05)!]),
        border: Border.all(color: const Color(0xFFF4F4F4).withAlpha(15)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Opacity(opacity: 0.15, child: Icon(icon, size: 110, color: color)),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: TextStyle(color: color.withAlpha(230), fontSize: 11, letterSpacing: 1.8, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFF4F4F4), fontSize: 26, fontWeight: FontWeight.w300, letterSpacing: -1.2),
                ),
                const Spacer(),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: const Color(0xFFF4F4F4).withAlpha(180), fontSize: 13, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// ---------------------------------------------------------------------------
/// SUPER PATTERN CARD
/// ---------------------------------------------------------------------------
class SuperPatternCard extends StatefulWidget {
  const SuperPatternCard({super.key, required this.pattern, this.onTap});

  final BodyPattern pattern;
  final VoidCallback? onTap;

  @override
  State<SuperPatternCard> createState() => _SuperPatternCardState();
}

class _SuperPatternCardState extends State<SuperPatternCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _getAnimationDuration())..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Duration _getAnimationDuration() {
    final type = widget.pattern.type.toLowerCase();
    return switch (type) {
      BodyPattern.typeEnergy => const Duration(milliseconds: 600),
      BodyPattern.typeBloating => const Duration(milliseconds: 2000),
      BodyPattern.typeSleep => const Duration(milliseconds: 3000),
      _ => const Duration(milliseconds: 2500),
    };
  }

  @override
  Widget build(BuildContext context) {
    final rawAccentColor = InsightUiUtils.getPatternColor(widget.pattern.type.toLowerCase());
    final accentColor = rawAccentColor == Colors.black ? const Color(0xFF0759E8) : rawAccentColor;
    final icon = InsightUiUtils.getPatternTypeIcon(widget.pattern.type.toLowerCase());
    final name = InsightUiUtils.getPatternName(widget.pattern.type.toLowerCase());

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(const Color(0xFF1A1C21), accentColor, 0.15)!, Color.lerp(const Color(0xFF0F1012), accentColor, 0.05)!],
          ),
          border: Border.all(color: const Color(0xFFF4F4F4).withAlpha(15)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Animated Background Icon
            Positioned(
              right: -20,
              bottom: -20,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => Transform(
                  alignment: Alignment.center,
                  transform: _getAnimationTransform(),
                  child: Opacity(
                    opacity: _getAnimationOpacity(),
                    child: Icon(icon, size: 110, color: accentColor),
                  ),
                ),
              ),
            ),

            // Main Content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${name.toUpperCase()} • ${widget.pattern.confidence.toUpperCase()}',
                    style: TextStyle(color: accentColor.withAlpha(230), fontSize: 11, letterSpacing: 1.8, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.pattern.trigger,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFF4F4F4), fontSize: 26, fontWeight: FontWeight.w300, letterSpacing: -1.2),
                  ),
                  const Spacer(),
                  Text(
                    widget.pattern.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: const Color(0xFFF4F4F4).withAlpha(180), fontSize: 13, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Matrix4 _getAnimationTransform() {
    final value = _controller.value;
    final type = widget.pattern.type.toLowerCase();
    return switch (type) {
      BodyPattern.typeEnergy => Matrix4.diagonal3Values(1.0 + (value * 0.05), 1.0 + (value * 0.05), 1.0),
      BodyPattern.typeBloating => Matrix4.diagonal3Values(1.0 + (value * 0.12), 1.0 + (value * 0.12), 1.0),
      BodyPattern.typeHeadache || BodyPattern.typeDigestion => Matrix4.rotationZ(value * 0.15 - 0.075),
      _ => Matrix4.translationValues(0, value * -10, 0),
    };
  }

  double _getAnimationOpacity() {
    final type = widget.pattern.type.toLowerCase();
    if (type == BodyPattern.typeSleep) {
      return 0.05 + (_controller.value * 0.15);
    }
    return 0.15;
  }
}

/// ---------------------------------------------------------------------------
/// SUPER FOOD CYCLER CARD
/// ---------------------------------------------------------------------------
class SuperFoodCyclerCard extends StatefulWidget {
  const SuperFoodCyclerCard({super.key, required this.items, required this.title, this.trend, required this.isPositive, required this.icon, this.onPageChanged});

  final List<SuperCyclerItemData> items;
  final String title;
  final String? trend;
  final bool isPositive;
  final IconData icon;
  final ValueChanged<int>? onPageChanged;

  @override
  State<SuperFoodCyclerCard> createState() => _SuperFoodCyclerCardState();
}

class _SuperFoodCyclerCardState extends State<SuperFoodCyclerCard> with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  late AnimationController _iconController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var accentColor = widget.isPositive ? const Color(0xFF27F15B) : const Color(0xFFE9579A);
    if (widget.title.toUpperCase() == 'RECENT LOGS') {
      accentColor = const Color(0xFF0759E8); // Premium Blue for History
    }

    final displayItems = widget.items.isEmpty ? [SuperCyclerItemData(name: 'STABLE HABITS', effect: 'Your gut is tracking well.')] : widget.items;

    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(const Color(0xFF1A1C21), accentColor, 0.12)!, Color.lerp(const Color(0xFF0F1012), accentColor, 0.04)!],
        ),
        border: Border.all(color: const Color(0xFFF4F4F4).withAlpha(15)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Animated Background Icon
          Positioned(
            right: -25,
            bottom: -25,
            child: AnimatedBuilder(
              animation: _iconController,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, _iconController.value * -12),
                child: Opacity(opacity: 0.12, child: Icon(widget.icon, size: 130, color: accentColor)),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Left Panel: Food Image with Glow
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: accentColor.withAlpha(60), blurRadius: 20, spreadRadius: 2)],
                    border: Border.all(color: Colors.white.withAlpha(20), width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: CachedNetworkImage(
                        key: ValueKey('${widget.title}_$_currentIndex'),
                        imageUrl: displayItems[_currentIndex].imageUrl ?? getDynamicImageUrl(displayItems[_currentIndex].name),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: AppPalette.shimmerBase(context),
                          highlightColor: AppPalette.shimmerHighlight(context),
                          child: Container(color: Colors.white),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: accentColor.withAlpha(30),
                          child: Icon(widget.icon, color: accentColor.withAlpha(150), size: 32),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                // Right Panel: Info Cycler
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title.toUpperCase(),
                        style: TextStyle(color: accentColor.withAlpha(230), fontSize: 11, letterSpacing: 1.8, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          scrollDirection: Axis.vertical,
                          itemCount: displayItems.length,
                          onPageChanged: (index) {
                            setState(() => _currentIndex = index);
                            widget.onPageChanged?.call(index);
                          },
                          itemBuilder: (context, index) {
                            final item = displayItems[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.name.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Color(0xFFF4F4F4), fontSize: 26, fontWeight: FontWeight.w300, letterSpacing: -1.2),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.effect,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: const Color(0xFFF4F4F4).withAlpha(160), fontSize: 12, fontWeight: FontWeight.w400),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      if (displayItems.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: SmoothPageIndicator(
                            controller: _pageController,
                            count: displayItems.length,
                            effect: ScrollingDotsEffect(activeDotColor: accentColor, dotColor: Colors.white.withAlpha(40), dotHeight: 4, dotWidth: 4, spacing: 4),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SuperCyclerItemData {
  SuperCyclerItemData({required this.name, required this.effect, this.imageUrl});
  final String name;
  final String effect;
  final String? imageUrl;
}

class GutTickGaugePainter extends CustomPainter {
  GutTickGaugePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * .92);
    final radius = math.min(size.width * .38, size.height * .88);

    const startAngle = math.pi;
    const totalAngle = math.pi;

    final tickPaint = Paint()
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    const tickCount = 92;

    for (var i = 0; i <= tickCount; i++) {
      final fraction = i / tickCount;
      final angle = startAngle + totalAngle * fraction;

      final innerRadius = radius - 10;
      final outerRadius = radius;

      final start = Offset(center.dx + math.cos(angle) * innerRadius, center.dy + math.sin(angle) * innerRadius);

      final end = Offset(center.dx + math.cos(angle) * outerRadius, center.dy + math.sin(angle) * outerRadius);

      if (fraction <= progress) {
        tickPaint.color = Colors.white.withAlpha(220);
      } else {
        tickPaint.color = Colors.white.withAlpha(35);
      }

      canvas.drawLine(start, end, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GutTickGaugePainter oldDelegate) => oldDelegate.progress != progress;
}
