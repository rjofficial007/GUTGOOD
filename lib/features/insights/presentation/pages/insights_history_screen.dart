import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/services/firestore/insight_firestore_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/bento_data.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/insight_bento_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_history_tile.dart';

/// Every past insight, newest first. Simple list view matching Scan History style.
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
      builder: (context, snapshot) => RefreshIndicator(
        onRefresh: _reload,
        color: context.appColorScheme.textPrimary,
        backgroundColor: context.appColorScheme.cardBackground,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            const GutSliverAppBar(title: AppStrings.insightHistory, centerTitle: true),
            _body(context, snapshot),
          ],
        ),
      ),
    ),
  );

  Widget _body(BuildContext context, AsyncSnapshot<List<AIInsight>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) return const _HistoryLoading();
    if (snapshot.hasError) return _HistoryError(onRetry: _reload);

    final history = snapshot.data ?? const <AIInsight>[];
    if (history.isEmpty) return _HistoryEmpty(onScan: () => context.go(AppRoutes.scannerPath(ScannerMode.food.name)));

    // Sort newest first
    final newestFirst = [...history]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    // Ascending view powers each card's "scores up to this insight" sparkline.
    final ascending = [...history]..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 32.w),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index == 0) return _HistoryMetrics(history: history);
          final insight = newestFirst[index - 1];

          return Padding(
            padding: EdgeInsets.only(top: index == 1 ? 16.w : 12.w),
            child: InsightHistoryCard(
              insight: insight,
              series: _seriesUpTo(ascending, insight),
              onTap: () => unawaited(context.push(AppRoutes.insightDetail, extra: insight)),
            ),
          );
        }, childCount: newestFirst.length + 1),
      ),
    );
  }

  /// The ≤7 chronological scores ending at [target] — the card's sparkline.
  static List<double> _seriesUpTo(List<AIInsight> ascending, AIInsight target) {
    final idx = ascending.indexWhere((i) => i.updatedAt == target.updatedAt);
    final upto = idx >= 0 ? ascending.sublist(0, idx + 1) : ascending;
    final window = upto.length > 7 ? upto.sublist(upto.length - 7) : upto;
    return [for (final i in window) i.gutScore.toDouble()];
  }
}

/// The redesign's summary strip: total insights, best score and the average
/// signed change across the whole history — three quiet white metric cards.
class _HistoryMetrics extends StatelessWidget {
  const _HistoryMetrics({required this.history});
  final List<AIInsight> history;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final deltas = [for (final i in history) BentoData.parseDelta(i.scoreDiff)].whereType<int>().toList();
    final best = history.fold<int>(0, (m, i) => i.gutScore > m ? i.gutScore : m);
    final avg = deltas.isEmpty ? null : (deltas.fold<int>(0, (a, b) => a + b) / deltas.length).round();

    const purpleColor = Color(0xFF8B5CF6);
    final greenColor = t.positive;
    final avgColor = avg == null ? t.textTertiary : (avg >= 0 ? t.positive : t.negative);

    final avgIcon = avg == null ? AppIcons.activity : (avg >= 0 ? AppIcons.trendingUp : AppIcons.trendingDown);

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 12.w, 0, 0),
      child: Row(
        children: [
          Expanded(
            child: _metricCard(t: t, isDark: isDark, icon: AppIcons.sparkles, label: AppStrings.historyMetricInsights, value: '${history.length}', color: purpleColor),
          ),
          Gap.w8,
          Expanded(
            child: _metricCard(t: t, isDark: isDark, icon: AppIcons.trophy, label: AppStrings.historyMetricBest, value: '$best', color: greenColor),
          ),
          Gap.w8,
          Expanded(
            child: _metricCard(t: t, isDark: isDark, icon: avgIcon, label: AppStrings.historyMetricAvg, value: avg == null ? '—' : '${avg > 0 ? '+' : ''}$avg', color: avgColor),
          ),
        ],
      ),
    );
  }

  Widget _metricCard({required InsightBentoTheme t, required bool isDark, required IconData icon, required String label, required String value, required Color color}) {
    final bgStart = color.withValues(alpha: isDark ? 0.22 : 0.12);
    final bgEnd = color.withValues(alpha: isDark ? 0.12 : 0.04);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [bgStart, bgEnd]),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.10 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.28 : 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14.sp, color: color),
          ),
          Gap.h6,
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 18.sp, fontWeight: FontWeight.w900, letterSpacing: -0.4, height: 1.1, color: color),
          ),
          Gap.h2,
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: t.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _HistoryLoading extends StatelessWidget {
  const _HistoryLoading();

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: EdgeInsets.symmetric(horizontal: Responsive.w(16.0), vertical: 16.0.h),
    sliver: const SliverToBoxAdapter(child: ShimmerGridLoader(itemCount: 8, crossAxisCount: 1, variant: ShimmerVariant.list)),
  );
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => SliverFillRemaining(
    hasScrollBody: false,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: context.appColorScheme.error),
          Gap.h16,
          Text(AppStrings.errorGeneral, style: context.title),
          Gap.h8,
          TextButton(onPressed: onRetry, child: const Text(AppStrings.tryAgain)),
        ],
      ),
    ),
  );
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty({required this.onScan});
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) => SliverFillRemaining(
    hasScrollBody: false,
    child: Padding(
      padding: EdgeInsets.all(AppSizes.p24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: context.appColorScheme.textMuted),
          Gap.h24,
          Text(AppStrings.noHistoryYet, textAlign: TextAlign.center, style: context.title),
          Gap.h10,
          Text(
            AppStrings.gutHealthStoryDesc,
            textAlign: TextAlign.center,
            style: context.bodySm.copyWith(color: context.appColorScheme.textMuted),
          ),
          Gap.h32,
          ElevatedButton(onPressed: onScan, child: const Text(AppStrings.getStarted)),
        ],
      ),
    ),
  );
}
