import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
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
      backgroundColor: context.appColorScheme.cardBackground,
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
              padding: EdgeInsets.all(AppSizes.p32),
              decoration: BoxDecoration(
                color: context.appColorScheme.aiResponseBackground,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: context.appColorScheme.textPrimary.withAlpha(10), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Icon(icon, size: 56, color: context.appColorScheme.textPrimary),
            ),
            Gap.h32,
            Text(title, style: context.headingMd.copyWith(height: 1.1, letterSpacing: -0.5), textAlign: TextAlign.center),
            Gap.h16,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p12),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: context.body.copyWith(color: context.appColorScheme.textSecondary, height: 1.5),
              ),
            ),
            Gap.h48,
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
        Gap.h20,
        _ProgressRow(label: AppStrings.symptoms, progress: symptomProgress, count: symptoms, total: 1),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            children: [
              Expanded(child: Divider(color: context.appColorScheme.borderSubtle.withAlpha(100))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(AppStrings.orContinueWith.toUpperCase(), style: context.captionBold.copyWith(letterSpacing: 1.2, color: context.appColorScheme.textMuted)),
              ),
              Expanded(child: Divider(color: context.appColorScheme.borderSubtle.withAlpha(100))),
            ],
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
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label.toUpperCase(),
            style: context.eyebrow.copyWith(fontSize: 9.sp, color: context.appColorScheme.textSecondary, fontWeight: FontWeight.w800),
          ),
          RichText(
            text: TextSpan(
              style: context.label.copyWith(color: context.appColorScheme.textSecondary),
              children: [
                TextSpan(
                  text: '$count',
                  style: context.labelBold.copyWith(color: context.appColorScheme.textPrimary),
                ),
                TextSpan(text: '/$total'),
              ],
            ),
          ),
        ],
      ),
      Gap.h8,
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          backgroundColor: context.appColorScheme.borderSubtle.withAlpha(80),
          valueColor: AlwaysStoppedAnimation<Color>(progress >= 1.0 ? context.appColorScheme.success : context.appColorScheme.textPrimary),
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
