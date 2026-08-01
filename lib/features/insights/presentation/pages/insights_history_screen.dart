import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/services/firestore_service.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_history_section.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/widgets/shimmer_grid_loader.dart';

class InsightsHistoryScreen extends StatelessWidget {
  const InsightsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      body: CustomScrollView(
        slivers: [
          const GutSliverAppBar(title: AppStrings.insightHistory),
          FutureBuilder<List<AIInsight>>(
            future: sl<FirestoreService>().getInsightsHistory(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: Responsive.w(20.0), vertical: 16.0.h),
                  sliver: const SliverToBoxAdapter(child: ShimmerGridLoader(itemCount: 10, crossAxisCount: 1, variant: ShimmerVariant.list)),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyStateWidget(
                    icon: AppIcons.history,
                    title: AppStrings.yourGutHealthStory,
                    description: AppStrings.gutHealthStoryDesc,
                  ),
                );
              }

              final history = snapshot.data!;
              final grouped = _groupHistoryByDate(history);

              return SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: Responsive.w(20.0), vertical: 16.0.h),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final dateKey = grouped.keys.elementAt(index);
                    final dayInsights = grouped[dateKey]!;
                    return InsightHistorySection(title: dateKey, insights: dayInsights, onTileTap: (insight) => _showInsightDetail(context, insight));
                  }, childCount: grouped.keys.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Map<String, List<AIInsight>> _groupHistoryByDate(List<AIInsight> history) {
    Map<String, List<AIInsight>> grouped = {};
    for (var insight in history) {
      DateTime date = insight.updatedAt;
      String key;
      if (DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(DateTime.now())) {
        key = AppStrings.today;
      } else if (DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)))) {
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
    context.push(AppRoutes.insightDetail, extra: insight.toMap());
  }
}
