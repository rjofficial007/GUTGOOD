import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/core/widgets/super_card.dart';

class PatternDetailScreen extends StatelessWidget {
  const PatternDetailScreen({super.key, required this.pattern});
  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final accentColor = InsightUiUtils.getPatternColor(pattern.type);

    return Scaffold(
      backgroundColor: scheme.cardBackground,
      body: CustomScrollView(
        slivers: [
          GutSliverAppBar(title: InsightUiUtils.getPatternName(pattern.type).toUpperCase(), centerTitle: true, showBrandingIcon: false),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(AppSizes.p16, AppSizes.p16, AppSizes.p16, AppSizes.p32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Super Pattern Hero (High Fidelity)
                  DashboardEntrance(
                    delay: 50,
                    child: SuperPatternHero(pattern: pattern, accentColor: accentColor),
                  ),
                  Gap.h16,

                  // 2. Moments We Noticed (Now using SuperFoodGaugeCard for premium feel)
                  if (pattern.occurrences.isNotEmpty) ...[
                    DashboardEntrance(
                      delay: 150,
                      child: SuperFoodGaugeCard(
                        title: 'MOMENTS NOTICED',
                        label: 'TRIGGER EVENTS',
                        score: (pattern.confidence.toLowerCase() == 'high') ? 90 : 65,
                        statusColor: accentColor,
                        foods: pattern.occurrences.map((o) => SuperCyclerItemData(name: o.mealName, effect: '${o.date} • ${o.reaction}', imageUrl: o.imageUrl)).toList(),
                      ),
                    ),
                    Gap.h16,
                  ],

                  // 3. Worth Watching / Discovery Insights
                  DashboardEntrance(
                    delay: 250,
                    child: _WorthWatchingSection(pattern: pattern, accentColor: accentColor),
                  ),
                  Gap.h16,

                  // 4. Next Steps (Interactive Actions)
                  DashboardEntrance(
                    delay: 350,
                    child: _NextStepsSection(pattern: pattern, accentColor: accentColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SuperPatternHero extends StatefulWidget {
  const SuperPatternHero({super.key, required this.pattern, required this.accentColor});
  final BodyPattern pattern;
  final Color accentColor;

  @override
  State<SuperPatternHero> createState() => _SuperPatternHeroState();
}

class _SuperPatternHeroState extends State<SuperPatternHero> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = context.appColorScheme;
    final cardBg = isDark ? const Color(0xFF02050D) : scheme.textPrimary;
    const contentColor = AppPalette.white;
    final icon = InsightUiUtils.getPatternTypeIcon(widget.pattern.type.toLowerCase());

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 240),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: contentColor.withAlpha(isDark ? 20 : 15)),
        boxShadow: [BoxShadow(color: widget.accentColor.withAlpha(isDark ? 30 : 20), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 🌈 RADIAL PULSE BACKGROUND
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.8, -0.4 + (_controller.value * 0.1)),
                      radius: 1.2 + (_controller.value * 0.2),
                      colors: [widget.accentColor.withAlpha(isDark ? 140 : 120), widget.accentColor.withAlpha(60), Colors.transparent],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),

          // ❄️ Large Background Icon (Animated)
          Positioned(
            right: -30,
            bottom: -30,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_controller.value * 0.05),
                  child: Opacity(opacity: 0.1, child: Icon(icon, size: 220, color: widget.accentColor)),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Identity Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: contentColor.withAlpha(20), borderRadius: BorderRadius.circular(100)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(AppIcons.brain, size: 12, color: widget.accentColor),
                      Gap.w6,
                      Text(
                        'SMART DISCOVERY',
                        style: context.captionBold.copyWith(color: contentColor, fontSize: 9.sp, letterSpacing: 1.8, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                Gap.h24,
                // Main Pattern Title
                Text(
                  widget.pattern.trigger.toUpperCase(),
                  style: context.displayHero.copyWith(fontSize: 28.sp, height: 1.0, color: contentColor, fontWeight: FontWeight.w900, letterSpacing: -1.2),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_forward_rounded, color: widget.accentColor, size: 24.sp),
                    Gap.w8,
                    Expanded(
                      child: Text(
                        widget.pattern.reaction.toUpperCase(),
                        style: context.displayHero.copyWith(fontSize: 28.sp, height: 1.1, color: widget.accentColor, fontWeight: FontWeight.w900, letterSpacing: -1.2),
                      ),
                    ),
                  ],
                ),
                Gap.h16,
                // Descriptive Narrative
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                  child: Text(
                    widget.pattern.description,
                    style: context.body.copyWith(color: contentColor.withAlpha(180), height: 1.4, fontSize: 14.sp),
                  ),
                ),
                Gap.h32,
                // Stats Footer
                Row(
                  children: [
                    _StatBadge(label: 'STRENGTH', value: widget.pattern.confidence.toUpperCase(), color: widget.accentColor),
                    Gap.w12,
                    _StatBadge(label: 'FREQUENCY', value: '${widget.pattern.frequency} TIMES', color: contentColor.withAlpha(150)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: context.captionBold.copyWith(color: AppPalette.white.withAlpha(80), fontSize: 8.sp, letterSpacing: 0.8),
      ),
      Gap.h2,
      Text(
        value,
        style: context.labelBold.copyWith(color: color, fontSize: 13.sp, fontWeight: FontWeight.w900),
      ),
    ],
  );
}

class _WorthWatchingSection extends StatelessWidget {
  const _WorthWatchingSection({required this.pattern, required this.accentColor});
  final BodyPattern pattern;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final isHigh = pattern.confidence == BodyPattern.confidenceHigh;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1E1F24), Color(0xFF121214)]),
        border: Border.all(color: Colors.white.withAlpha(8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(AppIcons.target, size: 14, color: accentColor),
                    Gap.w8,
                    Text(
                      isHigh ? 'VERIFIED PATTERN' : 'WORTH WATCHING',
                      style: context.captionBold.copyWith(color: accentColor.withAlpha(200), letterSpacing: 1.2, fontSize: 10.sp, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                Gap.h8,
                Text(
                  isHigh
                      ? 'This association is statistically significant. Reducing ${pattern.trigger.toLowerCase()} may improve your symptoms.'
                      : '${pattern.frequency} times is enough to notice, but not enough to know for sure.',
                  style: TextStyle(color: Colors.white.withAlpha(160), height: 1.4, fontSize: 13.sp, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          Gap.w20,
          // Mini Bar Chart (Super Style)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar(16.h, accentColor.withAlpha(60)),
              Gap.w2,
              _buildBar(28.h, accentColor.withAlpha(120)),
              Gap.w2,
              _buildBar(40.h, accentColor),
              Gap.w2,
              _buildBar(52.h, accentColor.withAlpha(40), isDashed: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double height, Color color, {bool isDashed = false}) => Container(
    width: 14.w,
    height: height,
    decoration: BoxDecoration(
      color: isDashed ? Colors.transparent : color,
      borderRadius: BorderRadius.circular(5),
      border: isDashed ? Border.all(color: color, width: 1.5, style: BorderStyle.solid) : null,
    ),
    child: isDashed
        ? Center(
            child: Container(width: 1, height: height * 0.6, color: color.withAlpha(100)),
          )
        : null,
  );
}

class _NextStepsSection extends StatelessWidget {
  const _NextStepsSection({required this.pattern, required this.accentColor});
  final BodyPattern pattern;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SuperPhysicalGoalCard(
          title: 'ADAPTIVE STRATEGY',
          subtitle: 'WHAT YOU CAN DO',
          label: pattern.recommendation ?? 'Keep monitoring your intake.',
          icon: Icons.check_circle_outline_rounded,
          color: const Color(0xFF27F15B),
          onTap: () {},
        ),
        Gap.h16,
        SuperPhysicalGoalCard(
          title: 'ASK GUTGOOD AI',
          subtitle: 'AI ASSISTANCE',
          label: 'Ask about "${pattern.trigger} and ${pattern.reaction}"',
          icon: Icons.chat_bubble_outline_rounded,
          color: const Color(0xFF0759E8),
          onTap: () {},
        ),
      ],
    );
  }
}
