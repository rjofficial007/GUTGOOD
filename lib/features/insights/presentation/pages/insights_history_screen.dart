import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import 'package:gutgood/features/insights/presentation/widgets/insight_history_tile.dart';
import 'package:gutgood/features/scanner/domain/models/scanner_mode.dart';

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

    // Group by date/month for clean headers
    final groups = <String, List<AIInsight>>{};
    for (final insight in newestFirst) {
      final key = _getHeaderKey(insight.updatedAt);
      groups.putIfAbsent(key, () => []).add(insight);
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final key = groups.keys.elementAt(index);
        final items = groups[key]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(AppSizes.p16, AppSizes.p24, AppSizes.p16, AppSizes.p12),
              child: Text(key, style: context.captionBold.copyWith(color: context.appColorScheme.textSecondary)),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p16),
              child: Column(
                children: items
                    .map(
                      (i) => InsightHistoryTile(
                        insight: i,
                        onTap: () => unawaited(context.push(AppRoutes.insightDetail, extra: i)),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        );
      }, childCount: groups.length),
    );
  }

  String _getHeaderKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final entryDate = DateTime(date.year, date.month, date.day);

    if (entryDate == today) {
      return '${AppStrings.today.toUpperCase()} • ${_formatMonthDay(date)}';
    } else if (entryDate == yesterday) {
      return '${AppStrings.yesterday.toUpperCase()} • ${_formatMonthDay(date)}';
    } else {
      return _formatMonthDay(date);
    }
  }

  String _formatMonthDay(DateTime date) {
    final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${months[date.month - 1]} ${date.day}';
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
