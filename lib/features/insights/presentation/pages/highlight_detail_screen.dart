import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/bento_widgets.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/insight_bento_feed.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/pattern_style.dart';

class HighlightDetailScreen extends StatelessWidget {
  const HighlightDetailScreen({super.key, required this.args});
  final HighlightDetailArgs args;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = Color(args.accentColor);

    final colors = dark ? _darkGradient(accent) : _getGradientColors(accent);
    final textAccent = dark ? accent : _getTextAccent(accent);

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF0B0C0E) : Colors.white,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors, stops: const [0.0, 0.2, 0.4, 1.0]),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            GutSliverAppBar(title: args.tag.toUpperCase(), centerTitle: true, showBrandingIcon: false, backgroundColor: Colors.transparent, foregroundColor: textAccent),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w, 30.w),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Gap.h10,
                  // 1. Hero Mascot Card
                  _HeroMascotCard(args: args, accent: accent, textAccent: textAccent),
                  Gap.h16,
                  // 2. Meta Pills
                  if (args.footLeft != null)
                    Row(
                      children: [_MetaPill(label: args.footLeft!, color: accent, filled: false)],
                    ),
                  Gap.h16,
                  // 3. Discovery Section
                  _SectionCard(
                    title: 'DISCOVERY',
                    color: accent,
                    child: Text(
                      args.body ?? 'No detailed analysis available yet.',
                      style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 13.sp, color: PatternSurface.muted(context), height: 1.55),
                    ),
                  ),
                  Gap.h16,
                  // 4. Activity Trend / Chart Section
                  if (args.chartType != null) ...[
                    _SectionCard(
                      title: 'ACTIVITY TREND',
                      color: accent,
                      child: Container(
                        height: 120.w,
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 8.w),
                        child: CustomPaint(painter: _getPainter(accent), size: Size.infinite),
                      ),
                    ),
                    Gap.h16,
                  ],
                  // 5. Recommendation Section
                  _RecommendationCard(accent: accent),
                  Gap.h24,
                  // 6. CTA
                  BentoCta(label: 'Back to Insights', onTap: () => Navigator.of(context).pop()),
                  Gap.h10,
                  Center(
                    child: Text(
                      'Based on your logs · last 7 days',
                      style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 10.5.sp, color: PatternSurface.faint(context)),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  CustomPainter? _getPainter(Color accent) {
    switch (args.chartType) {
      case 'healing':
        return HealingSparklinePainter(color: accent);
      case 'trigger':
        return TriggerSpikePainter(color: accent);
      case 'working':
        return WorkingBarsPainter(color: accent, values: args.chartValues);
      case 'curiosity':
        return CuriosityPulsePainter(color: accent);
      default:
        return null;
    }
  }

  List<Color> _darkGradient(Color accent) {
    const base = Color(0xFF0B0C0E);
    return [Color.alphaBlend(accent.withValues(alpha: 0.30), base), Color.alphaBlend(accent.withValues(alpha: 0.17), base), Color.alphaBlend(accent.withValues(alpha: 0.07), base), base];
  }

  List<Color> _getGradientColors(Color accent) {
    // Exact color mapping from PatternDetailScreen based on the highlight's accent
    final hex = accent.toARGB32() & 0xFFFFFF;
    switch (hex) {
      case 0x8B5CF6: // Purple (Investigating)
        return const [Color(0xFFBEA4FA), Color(0xFFD8C8FC), Color(0xFFF5F6F8), Colors.white];
      case 0x14A38F: // Teal (Healing)
        return const [Color(0xFF7BCBC0), Color(0xFFAFE0D9), Color(0xFFF5F6F8), Colors.white];
      case 0xF08019: // Orange (Trigger)
        return const [Color(0xFFF7B87E), Color(0xFFFAD4B1), Color(0xFFF5F6F8), Colors.white];
      case 0xEFB008: // Yellow (Working)
        return const [Color(0xFFF6D375), Color(0xFFFAE4AB), Color(0xFFF5F6F8), Colors.white];
      case 0x57B93B: // Green (Energy style)
        return const [Color(0xFFA1D891), Color(0xFFC6E7BC), Color(0xFFF5F6F8), Colors.white];
      default:
        // Generic fallback using the same alpha rhythm
        return [accent.withValues(alpha: 0.35), accent.withValues(alpha: 0.15), const Color(0xFFF5F6F8), Colors.white];
    }
  }

  static Color _getTextAccent(Color accent) {
    final hex = accent.toARGB32() & 0xFFFFFF;
    switch (hex) {
      case 0x14A38F: // Teal
        return const Color(0xFF0C6559);
      case 0xF08019: // Orange
        return const Color(0xFF954F10);
      case 0xEFB008: // Yellow/Gold
        return const Color(0xFF946D05);
      case 0x8B5CF6: // Purple
        return const Color(0xFF563999);
      default:
        return HSLColor.fromColor(accent).withLightness((HSLColor.fromColor(accent).lightness - 0.25).clamp(0.0, 1.0)).toColor();
    }
  }
}

class _HeroMascotCard extends StatelessWidget {
  const _HeroMascotCard({required this.args, required this.accent, required this.textAccent});
  final HighlightDetailArgs args;
  final Color accent;
  final Color textAccent;

  static IconData _getIconData(String name) {
    switch (name.toLowerCase()) {
      case 'brain':
        return AppIcons.brain;
      case 'zap':
        return AppIcons.zap;
      case 'leaf':
        return AppIcons.leaf;
      case 'wind':
        return AppIcons.wind;
      case 'activity':
        return AppIcons.activity;
      case 'sparkles':
        return AppIcons.sparkles;
      case 'plus':
        return AppIcons.plus;
      case 'info':
        return AppIcons.info;
      case 'lightbulb':
        return AppIcons.lightbulb;
      case 'moon':
        return AppIcons.moon;
      case 'utensils':
        return AppIcons.utensils;
      case 'salad':
        return AppIcons.salad;
      case 'history':
        return AppIcons.history;
      default:
        return AppIcons.sparkles;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayImg = args.userImageUrl ?? args.imageUrl;

    return Row(
      children: [
        Container(
          width: 92.w,
          height: 92.w,
          decoration: BoxDecoration(color: PatternSurface.card(context), borderRadius: BorderRadius.circular(24.w), boxShadow: PatternSurface.softShadow(context)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.w),
            child: (displayImg != null && displayImg.isNotEmpty)
                ? CachedNetworkImage(
                    imageUrl: displayImg,
                    width: 92.w,
                    height: 92.w,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Center(
                      child: args.emoji != null
                          ? Text(args.emoji!, style: TextStyle(fontSize: 40.sp, height: 1))
                          : Icon(args.icon != null ? _getIconData(args.icon!) : AppIcons.sparkles, size: 48, color: accent),
                    ),
                  )
                : Center(
                    child: args.emoji != null
                        ? Text(args.emoji!, style: TextStyle(fontSize: 40.sp, height: 1))
                        : Icon(args.icon != null ? _getIconData(args.icon!) : AppIcons.sparkles, size: 48, color: accent),
                  ),
          ),
        ),
        Gap.w14,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                args.tag.toUpperCase(),
                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w800, letterSpacing: 0.7, color: textAccent),
              ),
              Gap.h4,
              Text(
                args.title,
                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 18.sp, fontWeight: FontWeight.w800, color: PatternSurface.ink(context), height: 1.15),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label, required this.color, required this.filled});
  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.w),
    decoration: BoxDecoration(
      color: filled ? color : PatternSurface.chipBackground(context),
      borderRadius: BorderRadius.circular(999),
      border: filled ? null : Border.all(color: color.withValues(alpha: 0.5)),
    ),
    child: Text(
      label,
      style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.5.sp, fontWeight: filled ? FontWeight.w700 : FontWeight.w600, color: filled ? Colors.white : color),
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.color, required this.child});
  final String title;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(16.w),
    decoration: BoxDecoration(color: PatternSurface.card(context), borderRadius: BorderRadius.circular(18.w), boxShadow: PatternSurface.softShadow(context)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4.w,
              height: 15.w,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
            ),
            Gap.w10,
            Text(
              title.toUpperCase(),
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: color),
            ),
          ],
        ),
        Gap.h10,
        child,
      ],
    ),
  );
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(16.w),
    decoration: BoxDecoration(
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [accent, accent.withValues(alpha: 0.8)]),
      borderRadius: BorderRadius.circular(18.w),
      boxShadow: [BoxShadow(color: const Color(0xFF141828).withValues(alpha: 0.07), blurRadius: 26.w, offset: Offset(0, 10.w))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECOMMENDATION',
          style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: Colors.white.withValues(alpha: 0.9)),
        ),
        Gap.h8,
        Text(
          'Continue logging this food to increase analysis confidence and unlock deeper biological insights.',
          style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 13.5.sp, color: Colors.white, height: 1.5),
        ),
      ],
    ),
  );
}
