import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_score_gauge.dart';
import 'package:gutgood/core/widgets/modern_insight_card.dart';

import '../constants/app_strings.dart';
import '../theme/app_color_scheme.dart';

/// A prominent hero card that displays the user's current gut score.
///
/// Includes a circular [GutScoreGauge] to visualize the user's overall health.
/// Used at the top of the [InsightsScreen] and [WeeklyRecapScreen].
class GutSnapshotHeroCard extends StatelessWidget {
  /// The numerical gut health score (0-100).
  final int score;

  /// Formatted difference from the previous score (e.g., "+2").
  final String? scoreDiff;

  /// The user's current daily check-in streak.
  final int streak;

  /// Whether the "Live" status indicator should be shown.
  final bool isActive;

  /// Optional tap handler for navigation or details.
  final VoidCallback? onTap;

  /// Optional custom corner radius.
  final double? borderRadius;

  const GutSnapshotHeroCard({super.key, required this.score, this.scoreDiff, required this.streak, this.isActive = true, this.onTap, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return ModernInsightCard(
      title: AppStrings.gutSnapshot,
      icon: AppIcons.activity,
      iconColor: context.appColorScheme.textPrimary,
      backgroundColor: context.appColorScheme.cardBackground,
      titleColor: context.appColorScheme.textPrimary.withValues(alpha: 0.7),
      onTap: onTap,
      borderRadius: borderRadius,
      padding: EdgeInsets.all(Responsive.w(24.0)),
      footerColor: context.appColorScheme.textPrimary,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(AppIcons.flame, size: 14, color: context.appColorScheme.cardBackground),
          Gap.w8,
          Text('$streak${AppStrings.dayStreakActive}'.toUpperCase(), style: context.eyebrow.copyWith(color: context.appColorScheme.cardBackground, letterSpacing: 1.0)),
        ],
      ),
      child: Column(
        children: [
          Center(
            child: GutScoreGauge(score: score, size: Responsive.w(200)),
          ),
          if (scoreDiff != null && scoreDiff!.isNotEmpty) ...[
            Gap.h12,
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.0.w, vertical: 4.0.h),
              decoration: BoxDecoration(color: context.appColorScheme.border.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(100)),
              child: Text(
                scoreDiff!,
                style: context.caption.copyWith(color: context.appColorScheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 10.0.sp),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
