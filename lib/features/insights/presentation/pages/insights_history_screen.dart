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
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_history_section.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class InsightsHistoryScreen extends StatelessWidget {
  const InsightsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Scaffold(
      backgroundColor: scheme.cardBackground,
      body: CustomScrollView(
        slivers: [
          const GutSliverAppBar(title: AppStrings.insightHistory, showBrandingIcon: false),
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
          SliverToBoxAdapter(child: Gap.h40),
        ],
      ),
    );
  }

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
  Widget build(BuildContext context) => const SliverFillRemaining(
    hasScrollBody: false,
    child: EmptyStateWidget(icon: AppIcons.history, title: AppStrings.yourGutHealthStory, description: AppStrings.gutHealthStoryDesc),
  );
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.groupedHistory, required this.onTileTap});
  final Map<String, List<AIInsight>> groupedHistory;
  final Function(AIInsight) onTileTap;

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: EdgeInsets.symmetric(horizontal: Responsive.w(20.0)),
    sliver: SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final dateKey = groupedHistory.keys.elementAt(index);
        final dayInsights = groupedHistory[dateKey]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Text(
                dateKey.toUpperCase(),
                style: context.bodyBold.copyWith(fontSize: 11.sp, color: AppPalette.gray400, letterSpacing: 1),
              ),
            ),
            ...dayInsights.map((insight) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _HistoryCard(insight: insight, onTap: () => onTileTap(insight)),
            )),
          ],
        );
      }, childCount: groupedHistory.keys.length),
    ),
  );
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.insight, required this.onTap});
  final AIInsight insight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: scheme.elevatedSurface,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: scheme.cardBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(AppIcons.activity, size: 20.w, color: scheme.textPrimary),
            ),
            Gap.w16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "GUT SNAPSHOT",
                    style: context.bodyBold.copyWith(fontSize: 12.sp, color: scheme.textPrimary),
                  ),
                  Text(
                    DateFormat('h:mm a').format(insight.updatedAt),
                    style: context.caption.copyWith(color: scheme.textMuted, fontSize: 10.sp),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${insight.gutScore}",
                  style: context.bodyBold.copyWith(fontSize: 20.sp, fontWeight: FontWeight.w900, color: scheme.textPrimary),
                ),
                if (insight.scoreDiff != null)
                  Text(
                    insight.scoreDiff!,
                    style: context.caption.copyWith(
                      color: insight.scoreDiff!.startsWith('+') ? AppPalette.green : AppPalette.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 10.sp,
                    ),
                  ),
              ],
            ),
            Gap.w12,
            Icon(Icons.chevron_right, color: scheme.textMuted),
          ],
        ),
      ),
    );
  }
}
