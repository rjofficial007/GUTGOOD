import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/journal_entry.dart';
import 'package:gutgood/core/models/route_arguments.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/history/presentation/providers/history_notifier.dart';
import 'package:gutgood/features/history/presentation/widgets/journal_timeline_widgets.dart';
import 'package:provider/provider.dart';

class ScanHistoryScreen extends StatelessWidget {
  const ScanHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<HistoryNotifier>();

    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      body: RefreshIndicator(
        onRefresh: notifier.refreshAll,
        color: context.appColorScheme.textPrimary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const GutSliverAppBar(title: AppStrings.history),

            // Filter Bar
            SliverToBoxAdapter(
              child: JournalFilterBar(selectedFilter: notifier.currentFilter, onFilterChanged: notifier.setFilter),
            ),

            if (notifier.isLoading && notifier.filteredEntries.isEmpty)
              const _HistoryHubLoading()
            else if (notifier.filteredEntries.isEmpty)
              const _HistoryEmptyState()
            else
              _TimelineBody(entries: notifier.filteredEntries),

            SliverToBoxAdapter(child: Gap.h40),
          ],
        ),
      ),
    );
  }
}

class _HistoryHubLoading extends StatelessWidget {
  const _HistoryHubLoading();

  @override
  Widget build(BuildContext context) => SliverFillRemaining(
    hasScrollBody: false,
    child: Center(child: CircularProgressIndicator(color: context.appColorScheme.textPrimary)),
  );
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState();

  @override
  Widget build(BuildContext context) => SliverFillRemaining(
    hasScrollBody: false,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('No entries found', style: context.title.copyWith(color: context.appColorScheme.textSecondary)),
          Gap.h8,
          Text('Log meals or scan products to see them here.', style: context.bodySm.copyWith(color: context.appColorScheme.textMuted)),
        ],
      ),
    ),
  );
}

class _TimelineBody extends StatelessWidget {
  const _TimelineBody({required this.entries});
  final List<JournalEntry> entries;

  @override
  Widget build(BuildContext context) {
    // Group entries by date
    final groups = <String, List<JournalEntry>>{};
    for (final entry in entries) {
      String headerKey;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final entryDate = DateTime(entry.createdAt.year, entry.createdAt.month, entry.createdAt.day);

      if (entryDate == today) {
        headerKey = 'TODAY • ${_formatMonthDay(entry.createdAt)}';
      } else if (entryDate == yesterday) {
        headerKey = 'YESTERDAY • ${_formatMonthDay(entry.createdAt)}';
      } else {
        headerKey = _formatMonthDay(entry.createdAt);
      }

      groups.putIfAbsent(headerKey, () => []).add(entry);
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final key = groups.keys.elementAt(index);
        final groupEntries = groups[key]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: AppSizes.p16, top: AppSizes.p24, bottom: AppSizes.p16),
              child: Text(
                key,
                style: context.caption.copyWith(color: context.appColorScheme.textSecondary, fontWeight: FontWeight.w800, letterSpacing: 1.2),
              ),
            ),
            ...groupEntries.asMap().entries.map((e) {
              final entryIndex = e.key;
              final entry = e.value;
              return JournalTimelineEntry(entry: entry, isFirst: entryIndex == 0, isLast: entryIndex == groupEntries.length - 1, onTap: () => _handleEntryTap(context, entry));
            }),
          ],
        );
      }, childCount: groups.length),
    );
  }

  String _formatMonthDay(DateTime date) {
    final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${months[date.month - 1]} ${date.day}';
  }

  void _handleEntryTap(BuildContext context, JournalEntry entry) {
    if (entry.type == JournalEntryType.scan && entry.scan != null) {
      context.push(
        AppRoutes.scanResult,
        extra: ScanResultArgs(scanData: entry.scan!, heroTag: entry.id),
      );
    } else if (entry.type == JournalEntryType.meal && entry.meal != null) {
      context.push(AppRoutes.mealDetail, extra: entry.meal);
    } else if (entry.type == JournalEntryType.symptom && entry.symptom != null) {
      context.push(AppRoutes.symptomDetail, extra: entry.symptom);
    }
  }
}
