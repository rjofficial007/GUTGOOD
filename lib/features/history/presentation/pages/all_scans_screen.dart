import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/history/presentation/providers/history_notifier.dart';
import 'package:gutgood/features/history/presentation/widgets/history_section.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AllScansScreen extends StatefulWidget {
  const AllScansScreen({super.key});

  @override
  State<AllScansScreen> createState() => _AllScansScreenState();
}

class _AllScansScreenState extends State<AllScansScreen> {
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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<HistoryNotifier>().loadMoreScans();
    }
  }

  Map<String, List<HistoricalScan>> _groupHistoryByDate(List<ScanResult> scans) {
    final grouped = <String, List<HistoricalScan>>{};
    for (var scan in scans) {
      final item = HistoricalScan(data: scan, createdAt: scan.createdAt, userImageUrl: scan.userImageUrl);
      final date = item.createdAt;
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
    final notifier = context.watch<HistoryNotifier>();

    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      body: RefreshIndicator(
        onRefresh: notifier.refreshAll,
        color: context.appColorScheme.textPrimary,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            const GutSliverAppBar(title: AppStrings.aiScanHistory, showBrandingIcon: false),
            if (notifier.scansLoading) const _Loading() else if (notifier.allScans.isEmpty) const _Empty() else _List(groupedHistory: _groupHistoryByDate(notifier.allScans)),
            if (notifier.scansLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p16),
    sliver: const SliverToBoxAdapter(child: ShimmerGridLoader(itemCount: 10, crossAxisCount: 1, variant: ShimmerVariant.list)),
  );
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => const SliverFillRemaining(
    hasScrollBody: false,
    child: EmptyStateWidget(icon: AppIcons.scan, title: AppStrings.noScansYet, description: AppStrings.startScanningProducts),
  );
}

class _List extends StatelessWidget {
  const _List({required this.groupedHistory});
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
