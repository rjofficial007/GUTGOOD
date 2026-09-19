import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_feed.dart';
import 'package:provider/provider.dart';

/// Weekly Recap — v2 presentation matching design specification.
class WeeklyRecapScreen extends StatelessWidget {
  const WeeklyRecapScreen({super.key, this.insight});

  final AIInsight? insight;

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<InsightsNotifier>();
    final displayInsight = insight ?? notifier.latestInsight;

    final v2 = context.v2Theme;

    if (displayInsight == null) {
      return Scaffold(
        backgroundColor: v2.scaffold,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            GutSliverAppBar(title: 'Weekly Recap', centerTitle: true, showBrandingIcon: false, backgroundColor: v2.scaffold),
            SliverPadding(
              padding: EdgeInsets.all(16.w),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.w),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Center(
                    child: Text(
                      'No weekly recap available yet. Log your meals and symptoms to generate your weekly recap.',
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.5.sp, color: const Color(0xFF64748B)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final recap = displayInsight.weeklyRecap;

    unawaited(
      sl<AnalyticsService>().logEvent(
        name: 'view_weekly_recap',
        parameters: {
          'avg_score': recap?.avgScore ?? displayInsight.gutScore,
          'foods_logged': recap?.foodsLogged ?? displayInsight.foodImpacts.length,
        },
      ),
    );

    final series = _historySeries(context, displayInsight);

    return Scaffold(
      backgroundColor: v2.scaffold,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          GutSliverAppBar(title: 'Weekly Recap', centerTitle: true, showBrandingIcon: false, backgroundColor: v2.scaffold),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 8.w, 16.w, 32.w),
            sliver: SliverToBoxAdapter(
              child: V2WeeklyRecapView(data: displayInsight, series: series, patterns: notifier.prioritizedPatterns),
            ),
          ),
        ],
      ),
    );
  }

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
