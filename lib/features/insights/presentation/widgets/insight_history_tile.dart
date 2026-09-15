import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/utils/gut_score_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_score_list_tile.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/bento_data.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/insight_bento_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/pattern_style.dart';
import 'package:intl/intl.dart';

class InsightHistoryTile extends StatelessWidget {
  const InsightHistoryTile({super.key, required this.insight, required this.onTap});
  final AIInsight insight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = insight.topInsight?.type ?? 'Insight';
    final icon = _getIconForType(type);
    final band = GutScoreBand.fromScore(insight.gutScore);

    return GutScoreListTile(
      leading: Container(
        width: AppSizes.w52,
        height: AppSizes.w52,
        decoration: BoxDecoration(
          color: context.appColorScheme.cardBackground,
          borderRadius: BorderRadius.circular(AppSizes.r12),
          border: Border.all(color: context.appColorScheme.borderSubtle),
        ),
        child: Icon(icon, color: context.appColorScheme.textPrimary, size: AppSizes.icon24),
      ),
      title: insight.topInsight?.title ?? 'Analysis Complete',
      subtitle: '${type.toUpperCase()} • ${DateFormat('h:mm a').format(insight.updatedAt)}',
      score: insight.gutScore,
      scoreColor: band.color,
      onTap: onTap,
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'pattern':
        return AppIcons.brain;
      case 'ingredient':
        return AppIcons.leaf;
      case 'behavioral':
        return AppIcons.activity;
      case 'goal':
        return AppIcons.target;
      default:
        return AppIcons.salad;
    }
  }
}

/// Pattern-card-language history entry (gallery redesign).
///
/// The score lives inside the 32px accent tile, the trend drives the whole
/// card's identity (mint ↑ / rose ↓ / amber flat), and the sparkline charts
/// the real score window leading up to this insight.
class InsightHistoryCard extends StatelessWidget {
  const InsightHistoryCard({super.key, required this.insight, required this.onTap, this.series = const [], this.delta});

  final AIInsight insight;
  final VoidCallback onTap;

  /// Chronological gut scores up to (and including) this insight.
  final List<double> series;

  /// Signed point change; parsed from `scoreDiff` when not supplied.
  final int? delta;

  @override
  Widget build(BuildContext context) {
    final d = delta ?? BentoData.parseDelta(insight.scoreDiff);
    final up = d != null && d > 0;
    final down = d != null && d < 0;
    final t = context.bentoTheme;
    final dark = PatternSurface.isDark(context);
    final accent = up
        ? const Color(0xFF10B981)
        : down
        ? const Color(0xFFEF4444)
        : const Color(0xFFEFB008);
    final deep = up
        ? t.positive
        : down
        ? t.negative
        : (dark ? t.gold : const Color(0xFFD97706));
    final tone = up
        ? const Color(0xFFECFDF5)
        : down
        ? const Color(0xFFFFF1F2)
        : const Color(0xFFFFFBEB);
    final meta = d == null || d == 0 ? null : BentoData.deltaLabel('${d > 0 ? '+' : '-'}${d.abs()}');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(color: PatternSurface.tone(context, accent, tone), borderRadius: BorderRadius.circular(16.w), boxShadow: PatternSurface.shadow(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(10.w)),
                  child: Center(
                    child: Text(
                      '${insight.gutScore}',
                      style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, letterSpacing: -0.2, color: Colors.white, height: 1),
                    ),
                  ),
                ),
                Gap.w10,
                Expanded(
                  child: Text(
                    _kindLabel(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: PatternSurface.ink(context)),
                  ),
                ),
                if (meta != null) ...[
                  Gap.w6,
                  Text(
                    meta,
                    maxLines: 1,
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w800, color: deep),
                  ),
                ],
              ],
            ),
            Gap.h8,
            Text(
              insight.topInsight?.title ?? AppStrings.historyAnalysisComplete,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w700, height: 1.3, color: PatternSurface.ink(context)),
            ),
            if (series.length >= 2) ...[Gap.h10, SparkArea(values: series, color: accent, height: 30)],
            Gap.h10,
            Row(
              children: [
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                ),
                Gap.w6,
                Text(
                  _formatDateTime(insight.updatedAt),
                  style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w600, color: PatternSurface.foot(context)),
                ),
                const Spacer(),
                Icon(AppIcons.chevronRight, size: 15.w, color: accent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final entryDate = DateTime(date.year, date.month, date.day);
    final timeStr = DateFormat('h:mm a').format(date);

    if (entryDate == today) {
      return '${AppStrings.today}, $timeStr';
    } else if (entryDate == yesterday) {
      return '${AppStrings.yesterday}, $timeStr';
    } else if (date.year == now.year) {
      return '${DateFormat('MMM d').format(date)} • $timeStr';
    } else {
      return '${DateFormat('MMM d, yyyy').format(date)} • $timeStr';
    }
  }

  String _kindLabel() => switch ((insight.topInsight?.type ?? insight.type).toLowerCase()) {
    'pattern' => AppStrings.historyKindPattern,
    'ingredient' || 'scan' => AppStrings.historyKindScan,
    _ => AppStrings.historyKindWeekly,
  };
}
