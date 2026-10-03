import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/di/di_instance.dart';
import 'package:gutgood/core/models/insights/ai_insight.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/theme/insight_theme.dart';
import 'package:gutgood/core/utils/date_formatter.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_states.dart';
import 'package:gutgood/infrastructure/firebase/firestore/insight_firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// simple & clean insight history screen matching notification history style.
class InsightsHistoryScreen extends StatefulWidget {
  const InsightsHistoryScreen({super.key});

  @override
  State<InsightsHistoryScreen> createState() => _InsightsHistoryScreenState();
}

class _InsightsHistoryScreenState extends State<InsightsHistoryScreen> {
  late Future<List<AIInsight>> _future = _fetch();

  Future<List<AIInsight>> _fetch() => sl<InsightFirestoreService>().getInsightsHistory();

  Future<void> _reload() async {
    setState(() => _future = _fetch());
    try {
      await _future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appColorScheme.cardBackground,
    body: FutureBuilder<List<AIInsight>>(
      future: _future,
      builder: (context, snapshot) {
        final history = snapshot.data ?? _getHistoryFromNotifier(context);
        final sortedHistory = [...history]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        return RefreshIndicator(
          onRefresh: _reload,
          color: context.appColorScheme.textPrimary,
          backgroundColor: context.appColorScheme.elevatedSurface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              const GutSliverAppBar(title: 'INSIGHT HISTORY', centerTitle: true, showBrandingIcon: false),

              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (snapshot.hasError) InsightErrorStateCard(onRetry: _reload, hasCachedData: sortedHistory.isNotEmpty),
                    if (sortedHistory.isEmpty && snapshot.connectionState == ConnectionState.waiting)
                      const InsightLoadingState()
                    else if (sortedHistory.isEmpty && !snapshot.hasError)
                      InsightEmptyStateCard(
                        title: 'Your story starts here',
                        message: 'Your saved insights will appear here as you log meals and symptoms.',
                        actionLabel: 'Back to insights',
                        onAction: () => context.pop(),
                      )
                    else ...[
                      for (final insight in sortedHistory) ...[_InsightHistoryTile(insight: insight)],
                    ],
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  static List<AIInsight> _getHistoryFromNotifier(BuildContext context) {
    try {
      return context.read<InsightsNotifier>().insightHistory;
    } on ProviderNotFoundException {
      return const [];
    }
  }
}

class _InsightHistoryTile extends StatelessWidget {
  const _InsightHistoryTile({required this.insight});

  final AIInsight insight;

  @override
  Widget build(BuildContext context) {
    final title = insight.topInsight?.title.isNotEmpty == true ? insight.topInsight!.title : (insight.healingGoal?.isNotEmpty == true ? insight.healingGoal! : 'Gut Score Analysis');

    final dateFormatted = DateFormatter.formatDate(insight.updatedAt);
    final timeFormatted = DateFormat('h:mm a').format(insight.updatedAt);
    final subtitle = '$dateFormatted • $timeFormatted';
    final score = insight.gutScore.clamp(0, 100).toInt();

    final scoreColor = context.insightColor(score >= 70 ? const Color(0xFF15803D) : (score >= 50 ? const Color(0xFFB45309) : const Color(0xFFDC2626)));
    final trackColor = context.insightColor(score >= 70 ? const Color(0xFFDCFCE7) : (score >= 50 ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2)));

    return GestureDetector(
      onTap: () => context.push(AppRoutes.insightDetail, extra: insight),
      child: Container(
        margin: EdgeInsets.only(bottom: AppSizes.p12),
        padding: EdgeInsets.all(AppSizes.p12),
        decoration: BoxDecoration(
          color: context.appColorScheme.elevatedSurface,
          borderRadius: BorderRadius.circular(AppSizes.r20),
          border: Border.all(color: context.appColorScheme.borderSubtle),
        ),
        child: Row(
          children: [
            // 1. Left History Icon Container (52x52)
            Container(
              width: AppSizes.w52,
              height: AppSizes.w52,
              decoration: BoxDecoration(color: context.appColorScheme.border.withAlpha(51), borderRadius: BorderRadius.circular(AppSizes.r12)),
              alignment: Alignment.center,
              child: Icon(AppIcons.history, color: context.appColorScheme.textPrimary, size: AppSizes.icon24),
            ),
            Gap.w16,

            // 2. Info (Title & Date + Time Subtitle)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.labelBold.copyWith(fontSize: AppSizes.s15),
                  ),
                  Gap.h4,
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.caption.copyWith(color: context.appColorScheme.textMuted),
                  ),
                ],
              ),
            ),
            Gap.w12,

            // 3. Score Badge (Circular Progress Ring)
            SizedBox(
              width: AppSizes.w52,
              height: AppSizes.w52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: insight.hasGutScore ? (score / 100.0).clamp(0.0, 1.0) : 0,
                    strokeWidth: 4,
                    strokeCap: StrokeCap.round,
                    backgroundColor: trackColor,
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                  Text(insight.hasGutScore ? '$score' : '—', style: context.labelBold),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
