import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/gut_insight_list.dart';

class InsightDetailSheet extends StatelessWidget {
  final AIInsight insight;

  const InsightDetailSheet({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd, yyyy').format(insight.updatedAt);

    return GutSheetWrapper(
      padding: EdgeInsets.zero,
      children: [
        GutSheetHeader(title: '${AppStrings.reportDate}${dateStr.toUpperCase()}'),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Responsive.w(20.0)),
          child: Column(
            children: [
              Gap.h12,
              // 2. Hero Module
              _buildHero(context),
              Gap.h32,

              // 3. Detected Patterns
              if (insight.detectedPatterns.isNotEmpty) ...[_buildSectionHeader(context, 'DETECTED PATTERNS'), _buildPatternsGrid(context), Gap.h24],

              // 4. Highlights (Healing & Triggers)
              if (insight.topHealing != null || insight.topTrigger != null) ...[_buildSectionHeader(context, 'HIGHLIGHTS'), _buildHighlightsGrid(context), Gap.h24],

              // 5. Body Reactions
              if (insight.foodImpacts.isNotEmpty) ...[_buildSectionHeader(context, 'BODY REACTIONS'), _buildReactionsGrid(context), Gap.h32],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHero(BuildContext context) {
    final bool isPositiveDiff = insight.scoreDiff?.startsWith('+') ?? false;

    return Column(
      children: [
        GutScoreGauge(score: insight.gutScore, size: Responsive.w(250)),
        if (insight.simpleTrend.isNotEmpty) ...[Gap.h20, GutTrendSparkline(data: insight.simpleTrend, width: 200, height: 60)],
        if (insight.scoreDiff != null && insight.scoreDiff!.isNotEmpty) ...[
          Gap.h12,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.0.w, vertical: 4.0.h),
            decoration: BoxDecoration(color: (isPositiveDiff ? context.appColorScheme.success : context.appColorScheme.error).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100)),
            child: Text(
              insight.scoreDiff!,
              style: context.caption.copyWith(color: isPositiveDiff ? context.appColorScheme.success : context.appColorScheme.error, fontWeight: FontWeight.w900, fontSize: 10.0.sp),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4.0.w, bottom: 12.0.h),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: context.eyebrow),
      ),
    );
  }

  Widget _buildPatternsGrid(BuildContext context) {
    final List<Widget> items = insight.detectedPatterns.map((p) {
      final accentColor = InsightUiUtils.getPatternColor(p.icon);
      return GutInsightTile(title: 'PATTERN', value: p.title, subtitle: p.description, icon: InsightUiUtils.getReactionIcon(p.icon), statusColor: accentColor);
    }).toList();

    return GutInsightList(items: items);
  }

  Widget _buildHighlightsGrid(BuildContext context) {
    final List<Widget> items = [];
    if (insight.topHealing != null) {
      items.add(
        GutInsightTile(
          title: 'POWER SOURCE',
          value: insight.topHealing!.food,
          subtitle: insight.topHealing!.effects,
          statusColor: AppPalette.softBlue,
          icon: InsightUiUtils.getReactionIcon(insight.topHealing!.emoji),
        ),
      );
    }
    if (insight.topTrigger != null) {
      items.add(
        GutInsightTile(
          title: 'CRITICAL ALERT',
          value: insight.topTrigger!.food,
          subtitle: insight.topTrigger!.effects,
          statusColor: AppPalette.lime,
          icon: InsightUiUtils.getReactionIcon(insight.topTrigger!.emoji),
        ),
      );
    }

    return GutInsightList(items: items);
  }

  Widget _buildReactionsGrid(BuildContext context) {
    final items = insight.foodImpacts.take(4).map((impact) {
      final bool isNegative = impact.impactType == 'negative';
      return GutInsightTile(
        title: impact.timeframeLabel.isEmpty ? 'Reaction' : impact.timeframeLabel,
        value: impact.food,
        subtitle: impact.effect,
        statusColor: isNegative ? context.appColorScheme.error : context.appColorScheme.success,
        icon: InsightUiUtils.getReactionIcon(impact.emoji),
      );
    }).toList();

    return GutInsightList(items: items);
  }
}
