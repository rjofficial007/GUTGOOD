import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_score_gauge.dart';
import 'package:gutgood/core/widgets/modern_insight_card.dart';

/// A prominent hero card that displays the user's current gut score.
///
/// Includes a circular [GutScoreGauge] to visualize the user's overall health.
/// Used at the top of the [InsightsScreen] and [WeeklyRecapScreen].
class GutSnapshotHeroCard extends StatelessWidget {
  const GutSnapshotHeroCard({super.key, required this.score, this.scoreDiff, required this.streak, this.isActive = true, this.onTap, this.borderRadius});

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

  @override
  Widget build(BuildContext context) => ModernInsightCard(
    title: AppStrings.gutSnapshot,
    icon: AppIcons.activity,
    iconColor: context.appColorScheme.textPrimary,
    backgroundColor: context.appColorScheme.cardBackground,
    titleColor: context.appColorScheme.textPrimary.withAlpha(178),
    onTap: onTap,
    borderRadius: borderRadius,
    padding: EdgeInsets.all(Responsive.w(24.0)),
    footerColor: context.appColorScheme.textPrimary,
    footer: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(AppIcons.flame, size: 12, color: context.appColorScheme.cardBackground),
        Gap.w8,
        RichText(
          text: TextSpan(
            style: context.captionBold.copyWith(color: context.appColorScheme.cardBackground.withAlpha(178)),
            children: [
              TextSpan(
                text: streak.toString(),
                style: const TextStyle(fontWeight: FontWeight.w900, color: AppPalette.white),
              ),
              const TextSpan(text: ' '),
              TextSpan(text: AppStrings.dayStreakLabel.toUpperCase()),
            ],
          ),
        ),
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
            decoration: BoxDecoration(color: context.appColorScheme.borderSubtle, borderRadius: BorderRadius.circular(100)),
            child: Text(
              scoreDiff!,
              style: context.captionBold.copyWith(color: context.appColorScheme.textPrimary),
            ),
          ),
        ],
      ],
    ),
  );
}
