import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/product_details/presentation/widgets/scan_result_widgets.dart';

/// A prominent hero card that displays the user's current gut score.
///
/// Used at the top of the [InsightsScreen] and [WeeklyRecapScreen].
class GutSnapshotHeroCard extends StatelessWidget {
  const GutSnapshotHeroCard({super.key, required this.score, this.scoreDiff, required this.streak, this.isActive = true, this.onTap, this.borderRadius, this.title});

  final int score;
  final String? scoreDiff;
  final int streak;
  final bool isActive;
  final VoidCallback? onTap;
  final double? borderRadius;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final scoreColor = score >= 70 ? AppPalette.greenPastel : (score >= 40 ? AppPalette.purplePastel : AppPalette.red);

    return BentoCard(
      padding: const EdgeInsets.all(12),
      height: 200.h,
      backgroundColor: scheme.cardBackground,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius ?? 20),
        child: Row(
          children: [
            // Left Panel: Wallet aesthetic
            Container(
              width: 176.h,
              height: 176.h,
              decoration: BoxDecoration(color: scoreColor, borderRadius: BorderRadius.circular(16)),
              child: Stack(
                children: [
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Text(
                      (title ?? AppStrings.gutSnapshot).toUpperCase(),
                      style: context.captionTiny.copyWith(color: AppPalette.black.withAlpha(102)),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: AppPalette.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppPalette.black.withAlpha(26), blurRadius: 4)]),
                    ),
                  ),
                  Positioned(
                    bottom: 5,
                    left: 10,
                    child: Text(
                      '$score',
                      style: context.displayHero.copyWith(color: AppPalette.black, letterSpacing: -5),
                    ),
                  ),
                ],
              ),
            ),
            Gap.w16,
            // Right Panel
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(AppIcons.flame, size: 14, color: scheme.textPrimary),
                      Gap.w6,
                      Text(
                        '$streak ${AppStrings.dayStreakLabel.toUpperCase()}',
                        style: context.captionBold.copyWith(color: scheme.textPrimary),
                      ),
                    ],
                  ),
                  Gap.h8,
                  Text(
                    AppStrings.intelligenceDetail.toUpperCase(),
                    style: context.captionBold.copyWith(color: scheme.textSecondary),
                  ),
                  Gap.h4,
                  Text(
                    AppStrings.keepItUp,
                    style: context.headingSm.copyWith(fontWeight: FontWeight.w900, color: scheme.textPrimary),
                  ),
                  if (scoreDiff != null && scoreDiff!.isNotEmpty) ...[
                    Gap.h8,
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: scheme.borderSubtle, borderRadius: BorderRadius.circular(100)),
                      child: Text(
                        scoreDiff!,
                        style: context.captionBold.copyWith(color: scheme.textPrimary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
