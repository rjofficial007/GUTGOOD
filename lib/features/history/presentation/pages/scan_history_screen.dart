import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/historical_scan.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/history/domain/repositories/history_repository.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/logger_service.dart';
import '../../../../core/widgets/shimmer_grid_loader.dart';
import '../widgets/history_section.dart';

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
  }

  @override
  void dispose() {
    sl<AppStateService>().chatUpdated.removeListener(_loadHistory);
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final scans = await sl<HistoryRepository>().getScanHistory();
    Log.d('ScanHistoryScreen: Fetched ${scans.length} scans from repository');

    final historicalScans = scans.map((s) => HistoricalScan(data: s, time: s.time ?? DateTime.now(), userImageUrl: s.userImageUrl)).toList();

    if (mounted) {
      setState(() {
        _history = historicalScans;
        _isLoading = false;
      });
    }
  }

  Map<String, List<HistoricalScan>> _groupHistoryByDate() {
    Map<String, List<HistoricalScan>> grouped = {};
    for (var item in _history) {
      DateTime date = item.time;
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
  Widget build(BuildContext context) {
    final grouped = _groupHistoryByDate();

    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      body: CustomScrollView(
        slivers: [
          const GutSliverAppBar(title: AppStrings.history, showBrandingIcon: true),
          if (_isLoading)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p16),
              sliver: const SliverToBoxAdapter(child: ShimmerGridLoader(itemCount: 10, crossAxisCount: 1, variant: ShimmerVariant.list)),
            )
          else if (_history.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateWidget(icon: AppIcons.history, title: AppStrings.noScansYet, description: AppStrings.startScanningProducts),
            )
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  String dateKey = grouped.keys.elementAt(index);
                  List<HistoricalScan> items = grouped[dateKey]!;
                  return HistorySection(title: dateKey, items: items);
                }, childCount: grouped.length),
              ),
            ),
        ],
      ),
    );
  }
}
