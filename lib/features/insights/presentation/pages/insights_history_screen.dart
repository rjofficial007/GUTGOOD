import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/services/firestore/insight_firestore_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_history_section.dart';
import 'package:intl/intl.dart';

class InsightsHistoryScreen extends StatelessWidget {
  const InsightsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appColorScheme.cardBackground,
    body: CustomScrollView(
      slivers: [
        const GutSliverAppBar(title: AppStrings.insightHistory),
        FutureBuilder<List<AIInsight>>(
          future: sl<InsightFirestoreService>().getInsightsHistory(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _HistoryLoading();
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const _HistoryEmpty();
            }

            final history = snapshot.data!;
            final grouped = _groupHistoryByDate(history);

            return _HistoryList(groupedHistory: grouped, onTileTap: (insight) => _showInsightDetail(context, insight));
          },
        ),
      ],
    ),
  );

  Map<String, List<AIInsight>> _groupHistoryByDate(List<AIInsight> history) {
    final grouped = <String, List<AIInsight>>{};
    for (var insight in history) {
      final date = insight.updatedAt;
      String key;
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      if (DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(today)) {
        key = AppStrings.today;
      } else if (DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(yesterday)) {
        key = AppStrings.yesterday;
      } else {
        key = DateFormat('MMMM d, yyyy').format(date);
      }
      if (!grouped.containsKey(key)) grouped[key] = [];
      grouped[key]!.add(insight);
    }
    return grouped;
  }

  void _showInsightDetail(BuildContext context, AIInsight insight) {
    unawaited(context.push(AppRoutes.insightDetail, extra: insight));
  }
}

class _HistoryLoading extends StatelessWidget {
  const _HistoryLoading();

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: EdgeInsets.symmetric(horizontal: Responsive.w(20.0), vertical: 16.0.h),
    sliver: const SliverToBoxAdapter(child: ShimmerGridLoader(itemCount: 10, crossAxisCount: 1, variant: ShimmerVariant.list)),
  );
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty();

  @override
  Widget build(BuildContext context) {
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
              child: Icon(AppIcons.history, size: 56, color: context.appColorScheme.textPrimary),
            ),
            Gap.h32,
            Text(AppStrings.yourGutHealthStory, style: context.headingMd.copyWith(height: 1.1, letterSpacing: -0.5), textAlign: TextAlign.center),
            Gap.h16,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p12),
              child: Text(
                AppStrings.gutHealthStoryDesc,
                textAlign: TextAlign.center,
                style: context.body.copyWith(color: context.appColorScheme.textSecondary, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.groupedHistory, required this.onTileTap});
  final Map<String, List<AIInsight>> groupedHistory;
  final Function(AIInsight) onTileTap;

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: EdgeInsets.symmetric(horizontal: Responsive.w(20.0), vertical: 16.0.h),
    sliver: SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final dateKey = groupedHistory.keys.elementAt(index);
        final dayInsights = groupedHistory[dateKey]!;
        return InsightHistorySection(title: dateKey, insights: dayInsights, onTileTap: onTileTap);
      }, childCount: groupedHistory.keys.length),
    ),
  );
}
