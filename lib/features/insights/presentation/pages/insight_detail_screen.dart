import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/utils/quota_guard.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/analysis_card.dart';
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
          _MainDashboardSliver(data: insight),
        ],
      ),
    );
  }
}

class _MainDashboardSliver extends StatelessWidget {
  const _MainDashboardSliver({required this.data});
  final AIInsight data;

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<InsightsNotifier>();
    final profile = context.watch<ProfileNotifier>();
    final patterns = notifier.bodyPatterns;

    final sections = _buildSections(context: context, streak: profile.profile?.streak ?? 0, patterns: patterns);

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p10),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final isLast = index == sections.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? AppSizes.p20 : AppSizes.p20),
            child: sections[index],
          );
        }, childCount: sections.length),
      ),
    );
  }

  List<Widget> _buildSections({required BuildContext context, required int streak, required List<BodyPattern> patterns}) {
    final sections = <Widget>[GutSnapshotHeroCard(score: data.gutScore, scoreDiff: data.scoreDiff, streak: streak, isActive: false)];

    // 1. STRATEGIC FOCUS
    if (data.healingGoal != null || data.triggerSymptom != null) {
      sections.add(
        DashboardEntrance(
          delay: 50,
          child: AnalysisCard(
            metric: 'FOCUS',
            label: 'STRATEGY AT THE TIME',
            icon: AppIcons.target,
            glowColor: AppPalette.blue,
            items: [
              if (data.healingGoal != null) AnalysisItem(title: 'GOAL: ${data.healingGoal!.toUpperCase()}', subtitle: 'Primary healing objective', icon: AppIcons.leaf, isDone: true),
              if (data.triggerSymptom != null) AnalysisItem(title: 'WATCHING: ${data.triggerSymptom!.toUpperCase()}', subtitle: 'Tracking for patterns', icon: AppIcons.activity),
            ],
          ),
        ),
      );
    }

    // 2. BETTER ENERGY (healingFoods)
    if (data.healingFoods.isNotEmpty || data.foodImpacts.any((i) => i.impactType == 'positive')) {
      final healingCount = data.healingFoods.length + data.foodImpacts.where((i) => i.impactType == 'positive').length;
      final label = data.healingTrend != null ? 'BETTER ENERGY • ${data.healingTrend}' : 'BETTER ENERGY';

      sections.add(
        DashboardEntrance(
          delay: 100,
          child: AnalysisCard(
            metric: '$healingCount',
            label: label,
            icon: AppIcons.zap,
            glowColor: AppPalette.green,
            items: [
              ...data.healingFoods.map((f) => AnalysisItem(title: f.name, subtitle: f.effect, icon: AppIcons.check)),
              ...data.foodImpacts.where((i) => i.impactType == 'positive').map((i) => AnalysisItem(title: i.food, subtitle: '${i.timeframeLabel}: ${i.effect}', icon: AppIcons.check)),
            ],
          ),
        ),
      );
    }

    // 3. BLOATING (triggerFoods)
    if (data.triggerFoods.isNotEmpty || data.foodImpacts.any((i) => i.impactType == 'negative')) {
      final triggerCount = data.triggerFoods.length + data.foodImpacts.where((i) => i.impactType == 'negative').length;
      final label = data.triggerTrend != null ? 'BLOATING TRIGGERS • ${data.triggerTrend}' : 'BLOATING TRIGGERS';

      sections.add(
        DashboardEntrance(
          delay: 200,
          child: AnalysisCard(
            metric: '$triggerCount',
            label: label,
            icon: AppIcons.alertTriangle,
            glowColor: AppPalette.red,
            items: [
              ...data.triggerFoods.map((f) => AnalysisItem(title: f.name, subtitle: f.effect, icon: AppIcons.alertCircle)),
              ...data.foodImpacts.where((i) => i.impactType == 'negative').map((i) => AnalysisItem(title: i.food, subtitle: '${i.timeframeLabel}: ${i.effect}', icon: AppIcons.alertCircle)),
            ],
          ),
        ),
      );
    }

    // 4. SYSTEM DISCOVERIES (PatternEngine Data)
    if (patterns.isNotEmpty) {
      sections.add(
        DashboardEntrance(
          delay: 300,
          child: AnalysisCard(
            metric: '${patterns.length}',
            label: 'SYSTEM DISCOVERIES',
            icon: AppIcons.brain,
            glowColor: AppPalette.purple,
            items: patterns.map((p) => AnalysisItem(title: p.trigger.toUpperCase(), subtitle: p.description, icon: AppIcons.lightbulb)).toList(),
          ),
        ),
      );
    }

    // 5. RECENT PATTERNS (foodImpacts)
    if (data.foodImpacts.isNotEmpty) {
      sections.add(
        DashboardEntrance(
          delay: 400,
          child: AnalysisCard(
            metric: '${data.foodImpacts.length}',
            label: 'RECENT LOGS',
            icon: AppIcons.history,
            glowColor: AppPalette.blue,
            items: data.foodImpacts
                .map((i) => AnalysisItem(title: i.food, subtitle: '${i.timeframeLabel}: ${i.effect}', icon: i.impactType == 'positive' ? AppIcons.check : AppIcons.alertCircle))
                .toList(),
          ),
        ),
      );
    }

    // 6. STATISTICAL MVP (topHealing/topTrigger)
    if (data.topHealing != null || data.topTrigger != null) {
      sections.add(
        DashboardEntrance(
          delay: 500,
          child: AnalysisCard(
            metric: data.topHealing?.frequency ?? 'MVP',
            label: 'TOP PERFORMANCE',
            icon: AppIcons.trophy,
            glowColor: AppPalette.green,
            items: [
              if (data.topHealing != null) AnalysisItem(title: 'BEST: ${data.topHealing!.food}', subtitle: data.topHealing!.effects, icon: AppIcons.star),
              if (data.topTrigger != null) AnalysisItem(title: 'MOST REACTIVE: ${data.topTrigger!.food}', subtitle: data.topTrigger!.effects, icon: AppIcons.alertTriangle),
            ],
          ),
        ),
      );
    }

    // 7. AI SMART ALERT
    if (data.topInsight != null) {
      sections.add(ModernSmartAlert(insight: data.topInsight!));
    }

    sections.add(
      GutActionBanner(
        title: AppStrings.weeklyGutRecap,
        subtitle: AppStrings.last7DaysReady,
        icon: AppIcons.salad,
        onTap: () async {
          if (await QuotaGuard.check(context, type: QuotaType.premium)) {
            if (context.mounted) {
              unawaited(context.push(AppRoutes.weeklyRecap, extra: data));
            }
          }
        },
      ),
    );

    return sections;
  }
}
