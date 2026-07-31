import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/shimmer_grid_loader.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/history/domain/repositories/history_repository.dart';
import 'package:gutgood/features/history/presentation/widgets/scan_history_tile.dart';

class SavedFoodsScreen extends StatefulWidget {
  const SavedFoodsScreen({super.key});

  @override
  State<SavedFoodsScreen> createState() => _SavedFoodsScreenState();
}

class _SavedFoodsScreenState extends State<SavedFoodsScreen> {
  List<ScanResult> _savedFoods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedFoods();
    sl<AppStateService>().savedFoodsUpdated.addListener(_loadSavedFoods);
  }

  @override
  void dispose() {
    sl<AppStateService>().savedFoodsUpdated.removeListener(_loadSavedFoods);
    super.dispose();
  }

  Future<void> _loadSavedFoods() async {
    final foods = await sl<HistoryRepository>().getSavedFoods();
    if (mounted) {
      setState(() {
        _savedFoods = foods;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      body: CustomScrollView(
        slivers: [
          const GutSliverAppBar(title: AppStrings.savedFoods),
          if (_isLoading)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: Responsive.w(20.0), vertical: 16.0.h),
              sliver: const SliverToBoxAdapter(child: ShimmerGridLoader(itemCount: 8, crossAxisCount: 1, variant: ShimmerVariant.list)),
            )
          else if (_savedFoods.isEmpty)
            SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: Responsive.w(20.0), vertical: 16.0.h),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final scanResult = _savedFoods[index];
                  return ScanHistoryTile(
                    scanResult: scanResult,
                    onTap: () => context.push('/scan-result', extra: {'scanData': scanResult.toMap()}),
                  );
                }, childCount: _savedFoods.length),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const EmptyStateWidget(icon: Icons.bookmark_outline, title: AppStrings.noSavedItemsYet, description: AppStrings.tapHeartToSave);
  }
}
