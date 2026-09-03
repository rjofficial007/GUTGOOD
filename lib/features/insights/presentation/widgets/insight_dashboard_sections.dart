import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/product_details/presentation/widgets/scan_result_widgets.dart';

class ModernSmartAlert extends StatelessWidget {
  const ModernSmartAlert({super.key, required this.insight});
  final InsightSummary insight;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppPalette.purple.withAlpha(26) : scheme.cardBackground;
    final contentColor = isDark ? scheme.textPrimary : AppPalette.black;

    return DashboardEntrance(
      delay: 450,
      child: InkWell(
        onTap: () => context.push(AppRoutes.smartInsightDetail, extra: insight),
        borderRadius: BorderRadius.circular(AppSizes.r24),
        child: BentoCard(
          padding: const EdgeInsets.all(12),
          height: 160.h,
          backgroundColor: bgColor,
          borderColor: isDark ? AppPalette.purple.withAlpha(50) : AppPalette.purple.withAlpha(20),
          child: Row(
            children: [
              // Left block: AI Identity
              Container(
                width: 136.h,
                height: 136.h,
                decoration: BoxDecoration(color: scheme.cardBackground.withAlpha(isDark ? 102 : 204), borderRadius: BorderRadius.circular(16)),
                child: Stack(
                  children: [
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Text(
                        'AI PULSE',
                        style: context.captionMicro.copyWith(color: AppPalette.purple, fontWeight: FontWeight.w900, fontSize: 8.sp),
                      ),
                    ),
                    Center(
                      child: Icon(AppIcons.brain, size: 44.sp, color: AppPalette.purple),
                    ),
                  ],
                ),
              ),
              Gap.w16,
              // Right info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      insight.title.toUpperCase(),
                      style: context.captionBold.copyWith(color: contentColor.withAlpha(153)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap.h8,
                    Text(
                      insight.description,
                      style: context.caption.copyWith(color: contentColor, height: 1.3),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap.h8,
                    Text(
                      '${insight.type.toUpperCase()}${AppStrings.insightLabelSuffix.toUpperCase()} ➜',
                      style: context.captionMicro.copyWith(color: AppPalette.purple, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InsightMetricGrid extends StatelessWidget {
  const InsightMetricGrid({super.key, required this.data, this.notifier, required this.streak});
  final AIInsight data;
  final InsightsNotifier? notifier;
  final int streak;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: SmallInsightMetricCard(label: 'Streak', value: '$streak', unit: 'DAYS', icon: AppIcons.flame, accentColor: AppPalette.orange),
      ),
      Gap.w12,
      Expanded(
        child: SmallInsightMetricCard(label: 'Patterns', value: '${data.detectedPatterns.length}', unit: 'ACTIVE', icon: AppIcons.brain, accentColor: AppPalette.purple),
      ),
      Gap.w12,
      Expanded(
        child: SmallInsightMetricCard(label: 'Feelings', value: '${notifier?.totalSymptoms ?? 0}', unit: 'LOGGED', icon: AppIcons.activity, accentColor: AppPalette.pink),
      ),
    ],
  );
}

class SmallInsightMetricCard extends StatelessWidget {
  const SmallInsightMetricCard({super.key, required this.label, required this.value, required this.unit, required this.icon, required this.accentColor});
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Adaptive Theme Colors (Mirroring PhysicalGoalCard)
    final cardBg = isDark ? AppPalette.darkCard : scheme.cardBackground;
    final cardBorder = isDark ? AppPalette.white.withAlpha(20) : scheme.borderSubtle;
    final unitColor = isDark ? AppPalette.white.withAlpha(153) : scheme.textSecondary;
    final labelColor = isDark ? AppPalette.white.withAlpha(102) : scheme.textMuted;

    return BentoCard(
      padding: EdgeInsets.zero,
      height: 120.h,
      backgroundColor: cardBg,
      borderColor: cardBorder,
      borderRadius: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 🌊 Large Icon with Liquid Fill effect
            Positioned(
              right: -10,
              bottom: -15,
              child: Opacity(
                opacity: isDark ? 0.6 : 0.3,
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (rect) => LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [accentColor, accentColor, accentColor.withAlpha(isDark ? 40 : 80), accentColor.withAlpha(isDark ? 40 : 80)],
                    stops: const [0.0, 0.65, 0.65, 1.0],
                  ).createShader(rect),
                  child: Icon(icon, size: 80.h),
                ),
              ),
            ),

            // 📝 Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: context.displayHero.copyWith(color: accentColor, fontSize: 24.sp, letterSpacing: -1, fontWeight: FontWeight.w900, height: 1),
                  ),
                  Text(
                    unit.toUpperCase(),
                    style: context.captionBold.copyWith(color: unitColor, fontSize: 8.sp, letterSpacing: 0.5),
                  ),
                  const Spacer(),
                  Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.captionMicro.copyWith(color: labelColor, fontWeight: FontWeight.w900, fontSize: 7.sp, letterSpacing: 0.5),
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
