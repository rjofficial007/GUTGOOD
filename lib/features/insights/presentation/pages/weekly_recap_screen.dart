import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_strings.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_data.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_kit.dart';
import 'package:provider/provider.dart';

/// Weekly Recap — v2 presentation (mock screen 8).
///
/// The date-ranged digest: score ring + trend line card, best-day/logging
/// stats, the highlights checklist, and "Your Actions" — with the full
/// report one tap away.
class WeeklyRecapScreen extends StatelessWidget {
  const WeeklyRecapScreen({super.key, this.insight});

  final AIInsight? insight;

  @override
  Widget build(BuildContext context) {
    // Local capture so the null guard below promotes the field.
    final insight = this.insight;
    final recap = insight?.weeklyRecap;
    final v2 = context.v2Theme;

    if (insight != null) {
      unawaited(sl<AnalyticsService>().logEvent(name: 'view_weekly_recap', parameters: {'avg_score': recap?.avgScore ?? 0, 'foods_logged': recap?.foodsLogged ?? 0}));
    }

    if (insight == null || recap == null) {
      return const _RecapLoadingView();
    }

    final delta = V2Data.parseDelta(insight.scoreDiff);
    final actions = [...insight.actions, if (insight.healingGoal != null && insight.healingGoal!.trim().isNotEmpty) insight.healingGoal!];
    final series = _historySeries(context, insight);

    return Scaffold(
      backgroundColor: v2.scaffold,
      body: CustomScrollView(
        slivers: [
          GutSliverAppBar(title: 'Weekly Recap', centerTitle: true, showBrandingIcon: false, backgroundColor: v2.scaffold),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w, 32.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Gap.h4,

                // --- Score card ------------------------------------------------
                GutScoreCard(
                  score: recap.avgScore.clamp(0, 100).toInt(),
                  delta: delta,
                  series: series,
                  title: 'Weekly Average',
                  subtitle: recap.scoreSub,
                  onTap: () => unawaited(context.push(AppRoutes.insightDetail, extra: insight)),
                ),
                Gap.h12,

                // --- Best day + foods logged ------------------------------------
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      V2Stat(label: InsightV2Strings.bestDayStat, value: recap.bestDay),
                      Gap.w8,
                      V2Stat(label: InsightV2Strings.foodsLoggedStat, value: '${recap.foodsLogged}', sub: recap.loggedSub),
                    ],
                  ),
                ),
                Gap.h16,

                // --- Highlights --------------------------------------------------
                if (recap.highlights.isNotEmpty) ...[
                  const V2SectionLabel(InsightV2Strings.highlightsLabel),
                  Gap.h8,
                  V2Card(
                    background: v2.cardSubtle,
                    child: V2WhyList(points: [for (final h in recap.highlights) h.text], tone: V2Tone.success),
                  ),
                  Gap.h16,
                ],

                // --- Your actions -------------------------------------------------
                if (actions.isNotEmpty) ...[
                  const V2SectionLabel(InsightV2Strings.yourActionsLabel),
                  Gap.h8,
                  V2Card(
                    background: v2.cardSubtle,
                    padding: EdgeInsets.symmetric(vertical: 4.w),
                    child: Column(
                      children: [
                        for (var i = 0; i < actions.take(4).length; i++) ...[
                          if (i > 0) Divider(height: 1.w, color: v2.borderSubtle),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.w),
                            child: Row(
                              children: [
                                V2IconCircle(icon: i == 0 ? AppIcons.flame : AppIcons.leaf, size: 28, tone: i == 0 ? V2Tone.warning : V2Tone.success),
                                Gap.w10,
                                Expanded(child: Text(actions[i], style: V2Kit.text(context, size: 12, height: 1.4))),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Gap.h16,
                ],

                V2Button(
                  label: InsightV2Strings.viewFullReportCta,
                  onTap: () => unawaited(context.push(AppRoutes.insightDetail, extra: insight)),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// Score window from the notifier's history ending at this insight, so the
  /// recap's mini chart shows real prior scores (falls back to a flat line).
  static List<double> _historySeries(BuildContext context, AIInsight insight) {
    try {
      final history = context.read<InsightsNotifier>().insightHistory;
      final sorted = [...history]..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      final upto = sorted.where((i) => !i.updatedAt.isAfter(insight.updatedAt)).toList();
      if (!upto.any((i) => i.updatedAt == insight.updatedAt)) upto.add(insight);
      final window = upto.length > 7 ? upto.sublist(upto.length - 7) : upto;
      return [for (final i in window) i.gutScore.toDouble()];
    } catch (_) {
      return [insight.gutScore.toDouble()];
    }
  }
}

class _RecapLoadingView extends StatelessWidget {
  const _RecapLoadingView();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.v2Theme.scaffold,
    appBar: const GutAppBar(title: 'Weekly Recap'),
    body: Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.w),
      child: const ShimmerGridLoader(variant: ShimmerVariant.recap),
    ),
  );
}
