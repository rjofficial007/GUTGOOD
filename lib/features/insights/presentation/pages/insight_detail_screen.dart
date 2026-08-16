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

    // helper to map patterns to core 6
    final corePatterns = {
      'Bloating': patterns.where((p) => p.trigger.toLowerCase().contains('bloat') || p.description.toLowerCase().contains('bloat')).toList(),
      'Energy': patterns.where((p) => p.trigger.toLowerCase().contains('energy') || p.description.toLowerCase().contains('energy') || p.description.toLowerCase().contains('fatigue')).toList(),
      'Headache': patterns.where((p) => p.trigger.toLowerCase().contains('headache') || p.description.toLowerCase().contains('headache') || p.description.toLowerCase().contains('migraine')).toList(),
      'Digestion': patterns.where((p) => p.trigger.toLowerCase().contains('digest') || p.description.toLowerCase().contains('gas') || p.description.toLowerCase().contains('stomach')).toList(),
      'Fullness': patterns.where((p) => p.trigger.toLowerCase().contains('full') || p.description.toLowerCase().contains('satisfied') || p.description.toLowerCase().contains('hungry')).toList(),
      'Sleep': patterns.where((p) => p.trigger.toLowerCase().contains('sleep') || p.description.toLowerCase().contains('night')).toList(),
    };

    final icons = {
      'Bloating': AppIcons.alertTriangle,
      'Energy': AppIcons.zap,
      'Headache': AppIcons.activity,
      'Digestion': AppIcons.leaf,
      'Fullness': AppIcons.utensils,
      'Sleep': AppIcons.moon,
    };

    // 1. Core 6 Patterns (Only show if data exists)
    int delay = 100;
    for (final entry in corePatterns.entries) {
      if (entry.value.isNotEmpty) {
        sections.add(
          DashboardEntrance(
            delay: delay,
            child: AnalysisCard(
              metric: '${entry.value.length}',
              label: '${entry.key.toUpperCase()} PATTERN',
              icon: icons[entry.key] ?? AppIcons.activity,
              glowColor: AppPalette.gray400, // Premium/Monochrome instead of green
              items: entry.value.map((p) => AnalysisItem(title: p.trigger.toUpperCase(), subtitle: p.description, icon: AppIcons.lightbulb)).toList(),
            ),
          ),
        );
        delay += 50;
      }
    }

    // 2. AI SMART ALERT (Top Insight)
    if (data.topInsight != null) {
      sections.add(DashboardEntrance(delay: delay, child: ModernSmartAlert(insight: data.topInsight!)));
      delay += 50;
    }

    // 3. RECENT LOGS (if any)
    if (data.foodImpacts.isNotEmpty) {
      sections.add(
        DashboardEntrance(
          delay: delay,
          child: AnalysisCard(
            metric: '${data.foodImpacts.length}',
            label: 'RECENT LOGS',
            icon: AppIcons.history,
            glowColor: AppPalette.gray400,
            items: data.foodImpacts
                .map((i) => AnalysisItem(title: i.food, subtitle: '${i.timeframeLabel}: ${i.effect}', icon: i.impactType == 'positive' ? AppIcons.check : AppIcons.alertCircle))
                .toList(),
          ),
        ),
      );
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
