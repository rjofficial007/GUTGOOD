import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_score_gauge.dart';
import 'package:gutgood/core/widgets/gut_status_badge.dart';
import 'package:gutgood/core/widgets/modern_insight_card.dart';

import '../constants/app_strings.dart';
import '../theme/app_color_scheme.dart';
import 'gut_trend_sparkline.dart';

/// A prominent hero card that displays the user's current gut score and streak.
///
/// Includes a circular [GutScoreGauge] and a sparkline trend indicator for
/// the last 7 days. Used at the top of the [InsightsScreen] and
/// [WeeklyRecapScreen].
class GutSnapshotHeroCard extends StatelessWidget {
  /// The numerical gut health score (0-100).
  final int score;

  /// Formatted difference from the previous score (e.g., "+2").
  final String? scoreDiff;

  /// The user's current daily check-in streak.
  final int streak;

  /// A list of historical scores used to render the sparkline trend.
  final List<int> simpleTrend;

  /// Whether the "Live" status indicator should be shown.
  final bool isActive;

  /// Optional tap handler for navigation or details.
  final VoidCallback? onTap;

  /// Optional custom corner radius.
  final double? borderRadius;

  const GutSnapshotHeroCard({super.key, required this.score, this.scoreDiff, required this.streak, required this.simpleTrend, this.isActive = true, this.onTap, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final bool isPositiveDiff = scoreDiff?.startsWith('+') ?? false;

    return ModernInsightCard(
      title: AppStrings.gutSnapshot,
      icon: AppIcons.activity,
      iconColor: context.appColorScheme.textPrimary,
      backgroundColor: context.appColorScheme.cardBackground,
      titleColor: context.appColorScheme.textPrimary.withValues(alpha: 0.7),
      onTap: onTap,
      borderRadius: borderRadius,
      padding: EdgeInsets.all(Responsive.w(24.0)),
      action: GutStatusBadge(isActive: isActive),
      footerColor: AppPalette.lime,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(AppIcons.flame, size: 14, color: AppPalette.black),
          Gap.w8,
          Text('$streak${AppStrings.dayStreakActive}'.toUpperCase(), style: context.eyebrow.copyWith(color: AppPalette.black, letterSpacing: 1.0)),
        ],
      ),
      child: Column(
        children: [
          Center(
            child: GutScoreGauge(score: score, size: Responsive.w(200)),
          ),
          if (simpleTrend.isNotEmpty) ...[Gap.h12, GutTrendSparkline(data: simpleTrend, width: 120, height: 36)],
          if (scoreDiff != null && scoreDiff!.isNotEmpty) ...[
            Gap.h12,
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.0.w, vertical: 4.0.h),
              decoration: BoxDecoration(color: (isPositiveDiff ? context.appColorScheme.success : context.appColorScheme.error).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100)),
              child: Text(
                scoreDiff!,
                style: context.caption.copyWith(color: isPositiveDiff ? context.appColorScheme.success : context.appColorScheme.error, fontWeight: FontWeight.w900, fontSize: 10.0.sp),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
