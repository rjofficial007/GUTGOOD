import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/historical_scan.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/widgets/shimmer_grid_loader.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/history/domain/repositories/history_repository.dart';
import 'package:gutgood/features/history/presentation/widgets/history_section.dart';
import 'package:intl/intl.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  List<HistoricalScan> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    sl<AppStateService>().chatUpdated.addListener(_loadHistory);
    unawaited(sl<AnalyticsService>().logEvent(name: 'view_scan_history'));
  }

  @override
  void dispose() {
    sl<AppStateService>().chatUpdated.removeListener(_loadHistory);
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final scans = await sl<HistoryRepository>().getScanHistory();
    AppLogger.debug('ScanHistoryScreen: Fetched ${scans.length} scans from repository');

    final historicalScans = scans.map((s) => HistoricalScan(data: s, time: s.time ?? DateTime.now(), userImageUrl: s.userImageUrl)).toList();

    if (mounted) {
      setState(() {
        _history = historicalScans;
        _isLoading = false;
      });
    }
  }

  Map<String, List<HistoricalScan>> _groupHistoryByDate() {
    final grouped = <String, List<HistoricalScan>>{};
    for (var item in _history) {
      final date = item.time;
      String key;
      if (DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(DateTime.now())) {
        key = AppStrings.today;
      } else if (DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)))) {
        key = AppStrings.yesterday;
      } else {
        key = DateFormat('MMMM d, yyyy').format(date);
      }
      if (!grouped.containsKey(key)) grouped[key] = [];
      grouped[key]!.add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appColorScheme.cardBackground,
    body: CustomScrollView(
      slivers: [
        const GutSliverAppBar(title: AppStrings.history),
        _buildBody(),
      ],
    ),
  );

  Widget _buildBody() => _isLoading ? const _ScanHistoryLoading() : (_history.isEmpty ? const _ScanHistoryEmpty() : _ScanHistoryList(groupedHistory: _groupHistoryByDate()));
}

class _ScanHistoryLoading extends StatelessWidget {
  const _ScanHistoryLoading();

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p16),
    sliver: const SliverToBoxAdapter(child: ShimmerGridLoader(itemCount: 10, crossAxisCount: 1, variant: ShimmerVariant.list)),
  );
}

class _ScanHistoryEmpty extends StatelessWidget {
  const _ScanHistoryEmpty();

  @override
  Widget build(BuildContext context) => const SliverFillRemaining(
    hasScrollBody: false,
    child: EmptyStateWidget(icon: AppIcons.history, title: AppStrings.noScansYet, description: AppStrings.startScanningProducts),
  );
}

class _ScanHistoryList extends StatelessWidget {
  const _ScanHistoryList({required this.groupedHistory});
  final Map<String, List<HistoricalScan>> groupedHistory;

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p16),
    sliver: SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final dateKey = groupedHistory.keys.elementAt(index);
        final items = groupedHistory[dateKey]!;
        return HistorySection(title: dateKey, items: items);
      }, childCount: groupedHistory.length),
    ),
  );
}
