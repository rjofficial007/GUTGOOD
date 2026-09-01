import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_dashboard_view.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;

    return Scaffold(
      backgroundColor: colorScheme.cardBackground,
      body: Consumer<InsightsNotifier>(
        builder: (context, notifier, _) {
          final latestInsight = notifier.latestInsight;
          final prioritizedPatterns = notifier.prioritizedPatterns;
          final isLoading = notifier.isLoading;
          final profile = context.watch<ProfileNotifier>();

          debugPrint('--- InsightsScreen: Rendering ---');
          debugPrint('Is Loading: $isLoading');
          debugPrint('Latest Insight Firestore ID: ${latestInsight?.firestoreId}');
          debugPrint('Prioritized Patterns Count: ${prioritizedPatterns.length}');
          if (prioritizedPatterns.isNotEmpty) {
            for (var i = 0; i < prioritizedPatterns.length; i++) {
              final p = prioritizedPatterns[i];
              debugPrint('Prioritized Pattern [$i]: ${p.trigger}');
            }
          }
          debugPrint('---------------------------------');

          return CustomScrollView(
            slivers: [
              GutSliverAppBar(
                title: AppStrings.insights,
                actions: [
                  IconButton(
                    icon: Icon(AppIcons.history, color: colorScheme.textPrimary),
                    onPressed: () => unawaited(context.push(AppRoutes.insightHistory)),
                  ),
                  Gap.w10,
                ],
              ),
              if (isLoading)
                const _InsightsLoadingState()
              else if (latestInsight == null)
                const _NoInsightsState()
              else
                InsightDashboardSliver(data: latestInsight, streak: profile.streak, notifier: notifier, patterns: prioritizedPatterns),
            ],
          );
        },
      ),
    );
  }
}

class _NoInsightsState extends StatelessWidget {
  const _NoInsightsState();

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<InsightsNotifier>();
    final meals = notifier.totalMeals;
    final symptoms = notifier.totalSymptoms;
    final scans = notifier.totalScans;

    String title;
    String description;
    var icon = AppIcons.barChart;

    if (scans == 0 && meals == 0) {
      title = AppStrings.keepLoggingForPatterns;
      description = AppStrings.understandBodyImpact;
    } else if (scans < 3 && meals < 3) {
      title = AppStrings.loggingMoreMeals;
      description = AppStrings.keepLoggingForHighlights;
    } else if (symptoms == 0) {
      title = AppStrings.greatConsistency;
      description = AppStrings.understandBodyImpact;
      icon = AppIcons.activity;
    } else {
      title = AppStrings.noInsightsYet;
      description = AppStrings.keepLoggingForPatterns;
    }

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: EdgeInsets.all(AppSizes.p40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(AppSizes.p24),
              decoration: BoxDecoration(color: context.appColorScheme.aiResponseBackground, shape: BoxShape.circle),
              child: Icon(icon, size: 48, color: context.appColorScheme.textPrimary),
            ),
            Gap.h24,
            Text(
              title,
              style: AppTextStyles.title.copyWith(color: context.appColorScheme.textPrimary),
              textAlign: TextAlign.center,
            ),
            Gap.h12,
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm.copyWith(color: context.appColorScheme.textSecondary),
            ),
            Gap.h32,
            _ProgressIndicator(meals: meals, symptoms: symptoms, scans: scans),
          ],
        ),
      ),
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({required this.meals, required this.symptoms, required this.scans});
  final int meals;
  final int symptoms;
  final int scans;

  @override
  Widget build(BuildContext context) {
    final mealProgress = (meals / 3).clamp(0.0, 1.0);
    final symptomProgress = (symptoms / 1).clamp(0.0, 1.0);
    final scanProgress = (scans / 3).clamp(0.0, 1.0);

    return Column(
      children: [
        _ProgressRow(label: AppStrings.logs, progress: mealProgress, count: meals, total: 3),
        Gap.h12,
        _ProgressRow(label: AppStrings.symptoms, progress: symptomProgress, count: symptoms, total: 1),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            AppStrings.orContinueWith,
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: context.appColorScheme.textSecondary),
          ),
        ),
        _ProgressRow(label: AppStrings.aiScanHistory, progress: scanProgress, count: scans, total: 3),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.label, required this.progress, required this.count, required this.total});
  final String label;
  final double progress;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label.toUpperCase(), style: AppTextStyles.eyebrow.copyWith(color: context.appColorScheme.textMuted)),
          Text(
            '$count/$total',
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: context.appColorScheme.textSecondary),
          ),
        ],
      ),
      Gap.h6,
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 6,
          backgroundColor: context.appColorScheme.borderSubtle,
          valueColor: AlwaysStoppedAnimation<Color>(context.appColorScheme.textPrimary),
        ),
      ),
    ],
  );
}

class _InsightsLoadingState extends StatelessWidget {
  const _InsightsLoadingState();

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: EdgeInsets.fromLTRB(AppSizes.p20, 0, AppSizes.p20, AppSizes.p10),
    sliver: const SliverToBoxAdapter(child: ShimmerGridLoader(itemCount: 4, variant: ShimmerVariant.scanResult)),
  );
}
