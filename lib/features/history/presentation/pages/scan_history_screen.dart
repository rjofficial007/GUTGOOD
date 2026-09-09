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

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll * 0.9) {
      final notifier = context.read<HistoryNotifier>();
      if (notifier.currentFilter == HistoryFilter.all || notifier.currentFilter == HistoryFilter.scans) {
        notifier.loadMoreScans();
      } else if (notifier.currentFilter == HistoryFilter.body) {
        notifier.loadMoreSymptoms();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<HistoryNotifier>();

    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      body: RefreshIndicator(
        onRefresh: notifier.refreshAll,
        color: context.appColorScheme.textPrimary,
        child: CustomScrollView(
          controller: _scrollController,
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

            if (notifier.scansLoadingMore || notifier.mealsLoadingMore || notifier.symptomsLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              ),

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
          Text(AppStrings.noEntriesFound, style: context.title.copyWith(color: context.appColorScheme.textSecondary)),
          Gap.h8,
          Text(AppStrings.emptyHistoryDesc, style: context.bodySm.copyWith(color: context.appColorScheme.textMuted)),
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
        headerKey = '${AppStrings.today.toUpperCase()} • ${_formatMonthDay(entry.createdAt)}';
      } else if (entryDate == yesterday) {
        headerKey = '${AppStrings.yesterday.toUpperCase()} • ${_formatMonthDay(entry.createdAt)}';
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
              child: Text(key, style: context.captionBold.copyWith(color: context.appColorScheme.textSecondary)),
            ),
            ...groupEntries.asMap().entries.map((e) {
              final entryIndex = e.key;
              final entry = e.value;
              // Meal entries have no detail destination; scans and symptoms navigate.
              final hasDetail = entry.type != JournalEntryType.meal;
              return JournalTimelineEntry(
                entry: entry,
                isFirst: entryIndex == 0,
                isLast: entryIndex == groupEntries.length - 1,
                onTap: hasDetail ? () => _handleEntryTap(context, entry) : null,
              );
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
      // All scan types render in the unified scan result screen.
      context.push(
        AppRoutes.scanResult,
        extra: ScanResultArgs(scanData: entry.scan!, heroTag: entry.id),
      );
    } else if (entry.type == JournalEntryType.symptom && entry.symptom != null) {
      context.push(AppRoutes.symptomDetail, extra: entry.symptom);
    }
  }
}
