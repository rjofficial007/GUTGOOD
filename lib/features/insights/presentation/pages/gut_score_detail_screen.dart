import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_strings.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_data.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_kit.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Gut Score detail — the score hero's dedicated destination.
///
/// Explains the number: big ring with delta, the confidence/band explainer,
/// the 7-day trend, the full score history, and where to go deeper (weekly
/// recap, full history). Reached by tapping the score hero on the v2 feed.
class GutScoreDetailScreen extends StatelessWidget {
  const GutScoreDetailScreen({super.key, required this.insight});

  final AIInsight insight;

  @override
  Widget build(BuildContext context) {
    final v2 = context.v2Theme;
    final history = _historyOf(context);
    final (series, labels) = _window(history, insight);
    final delta = V2Data.parseDelta(insight.scoreDiff);

    return Scaffold(
      backgroundColor: v2.scaffold,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          GutSliverAppBar(title: InsightV2Strings.gutScoreEyebrow, centerTitle: true, showBrandingIcon: false, backgroundColor: v2.scaffold),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w, 32.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // --- Hero -----------------------------------------------------
                GutScoreCard(score: insight.gutScore.clamp(0, 100).toInt(), delta: delta, series: series, labels: labels, title: InsightV2Strings.gutScoreEyebrow, showChevron: false),
                Gap.h14,

                // --- What the score reads --------------------------------------
                V2Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const V2SectionLabel('What moves this number'),
                      Gap.h10,
                      const V2WhyList(
                        points: ['Symptom frequency and severity after meals', 'The quality of the foods you log and scan', 'Consistency — steady weeks beat perfect days'],
                        tone: V2Tone.success,
                      ),
                    ],
                  ),
                ),
                Gap.h14,

                // --- History ---------------------------------------------------
                ..._historySection(context, history),

                Gap.h12,
                V2Button(
                  label: InsightV2Strings.viewFullReportCta,
                  onTap: () => context.push(AppRoutes.insights),
                ),
                Gap.h8,
                Center(
                  child: Text(
                    InsightV2Strings.basedOnLogsFooter,
                    textAlign: TextAlign.center,
                    style: V2Kit.text(context, size: 10.5, color: v2.textTertiary),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// Live run reads the notifier; the widget also renders standalone (tests)
  /// when no provider is above it.
  List<AIInsight> _historyOf(BuildContext context) {
    try {
      return context.read<InsightsNotifier>().insightHistory;
    } on ProviderNotFoundException {
      return const [];
    }
  }

  List<Widget> _historySection(BuildContext context, List<AIInsight> history) {
    final v2 = context.v2Theme;
    final sorted = [...history]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final rows = sorted.take(5).toList();
    if (rows.isEmpty) return const [];
    return [
      const V2SectionLabel('Score history'),
      Gap.h8,
      V2Timeline(
        rows: [
          for (var i = 0; i < rows.length; i++)
            V2TimelineRow(
              title: '${DateFormat('MMM d').format(rows[i].updatedAt)} • ${rows[i].gutScore} pts',
              subtitle: rows[i].topInsight?.title ?? AppStrings.historyAnalysisComplete,
              trailing: V2Data.parseDelta(rows[i].scoreDiff) == null ? null : '${rows[i].scoreDiff}',
              dotColor: v2.textPrimary,
              dotMuted: i != 0,
            ),
        ],
      ),
      Gap.h14,
    ];
  }

  // ignore: unused_element — reserved for score band overlay
  static String _bandLabel(int score) {
    if (score >= 75) return 'Thriving range';
    if (score >= 55) return 'Steady range';
    if (score >= 35) return 'Finding rhythm';
    return 'Building up';
  }

  static (List<double>, List<String>) _window(List<AIInsight> history, AIInsight insight) {
    final sorted = [...history]..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    if (!sorted.any((i) => i.updatedAt == insight.updatedAt)) {
      sorted.add(insight);
    }
    final window = sorted.length > 7 ? sorted.sublist(sorted.length - 7) : sorted;
    const initials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return ([for (final i in window) i.gutScore.toDouble()], [for (final i in window) initials[i.updatedAt.weekday - 1]]);
  }
}
