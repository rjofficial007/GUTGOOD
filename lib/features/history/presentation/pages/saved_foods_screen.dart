import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
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
    unawaited(sl<AnalyticsService>().logEvent(name: 'view_saved_foods'));
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
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appColorScheme.cardBackground,
    body: CustomScrollView(
      slivers: [
        const GutSliverAppBar(title: AppStrings.savedFoods),
        _buildBody(),
      ],
    ),
  );

  Widget _buildBody() => _isLoading
      ? const _SavedFoodsLoading()
      : (_savedFoods.isEmpty
            ? const _SavedFoodsEmpty()
            : _SavedFoodsList(savedFoods: _savedFoods));
}

class _SavedFoodsLoading extends StatelessWidget {
  const _SavedFoodsLoading();

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: EdgeInsets.symmetric(
      horizontal: AppSizes.p20,
      vertical: AppSizes.p16,
    ),
    sliver: const SliverToBoxAdapter(
      child: ShimmerGridLoader(
        itemCount: 8,
        crossAxisCount: 1,
        variant: ShimmerVariant.list,
      ),
    ),
  );
}

class _SavedFoodsEmpty extends StatelessWidget {
  const _SavedFoodsEmpty();

  @override
  Widget build(BuildContext context) => const SliverFillRemaining(
    hasScrollBody: false,
    child: EmptyStateWidget(
      icon: Icons.bookmark_outline,
      title: AppStrings.noSavedItemsYet,
      description: AppStrings.tapHeartToSave,
    ),
  );
}

class _SavedFoodsList extends StatelessWidget {
  const _SavedFoodsList({required this.savedFoods});
  final List<ScanResult> savedFoods;

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: EdgeInsets.symmetric(
      horizontal: AppSizes.p20,
      vertical: AppSizes.p16,
    ),
    sliver: SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final scanResult = savedFoods[index];
        return ScanHistoryTile(
          scanResult: scanResult,
          onTap: () => unawaited(
            context.push(
              AppRoutes.scanResult,
              extra: {'scanData': scanResult.toMap()},
            ),
          ),
        );
      }, childCount: savedFoods.length),
    ),
  );
}
