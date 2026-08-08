import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_dashboard_sections.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class InsightDetailScreen extends StatelessWidget {
  const InsightDetailScreen({super.key, required this.insight});
  final AIInsight insight;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd, yyyy').format(insight.updatedAt);

    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      body: CustomScrollView(
        slivers: [
          GutSliverAppBar(title: '${AppStrings.reportDate}${dateStr.toUpperCase()}', showBrandingIcon: false),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p10),
            sliver: _InsightContentList(insight: insight),
          ),
        ],
      ),
    );
  }
}

class _InsightContentList extends StatelessWidget {
  const _InsightContentList({required this.insight});
  final AIInsight insight;

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections(context);
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final isLast = index == sections.length - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? AppSizes.p64 : AppSizes.p32),
          child: sections[index],
        );
      }, childCount: sections.length),
    );
  }

  List<Widget> _buildSections(BuildContext context) {
    final notifier = context.watch<InsightsNotifier>();
    final profile = context.watch<ProfileNotifier>();

    final sections = <Widget>[
      GutSnapshotHeroCard(score: insight.gutScore, scoreDiff: insight.scoreDiff, streak: profile.profile?.streak ?? 0, isActive: false),
      TrendCard(insights: notifier.insightHistory, currentInsight: insight, referenceDate: insight.updatedAt),
    ];

    // 3. Analysis Dashboards
    if (insight.healingGoal != null || insight.triggerSymptom != null) {
      sections.add(GoalDashboardSection(insight: insight));
    }

    if (insight.healingFoods.isNotEmpty || insight.foodImpacts.any((i) => i.impactType == 'positive')) {
      sections.add(PowerSourcesDashboardSection(insight: insight));
    }

    if (insight.triggerFoods.isNotEmpty || insight.foodImpacts.any((i) => i.impactType == 'negative')) {
      sections.add(TriggersDashboardSection(insight: insight));
    }

    if (insight.detectedPatterns.isNotEmpty) {
      sections.add(PatternsDashboardSection(insight: insight));
    }

    if (insight.topHealing != null || insight.topTrigger != null) {
      sections.add(HighlightsDashboardSection(insight: insight));
    }

    if (insight.topInsight != null) {
      sections.add(ModernSmartAlert(insight: insight.topInsight!));
    }

    return sections;
  }
}
