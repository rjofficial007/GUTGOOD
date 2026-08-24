import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/history/presentation/providers/saved_foods_provider.dart';
import 'package:gutgood/features/product_details/presentation/widgets/scan_result_widgets.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class ScanResultScreen extends StatefulWidget {
  const ScanResultScreen({super.key, required this.scanData, this.heroTag});
  final ScanResult scanData;
  final String? heroTag;

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    unawaited(sl<AnalyticsService>().logEvent(name: 'view_scan_result', parameters: {'product_name': widget.scanData.productName, 'score': widget.scanData.score}));
  }

  Future<void> _toggleSave() async {
    final provider = context.read<SavedFoodsProvider>();
    await provider.toggleSave(widget.scanData);
    await sl<AnalyticsService>().logEvent(
      name: provider.isSaved(widget.scanData.productName, barcode: widget.scanData.barcode) ? 'food_saved' : 'food_unsaved',
      parameters: {'product_name': widget.scanData.productName},
    );
    sl<AppStateService>().notifyProfileUpdated();
  }

  @override
  Widget build(BuildContext context) => Consumer<SavedFoodsProvider>(
    builder: (context, savedProvider, _) {
      final isSaved = savedProvider.isSaved(widget.scanData.productName, barcode: widget.scanData.barcode);
      return Scaffold(
        backgroundColor: context.appColorScheme.cardBackground,
        appBar: GutAppBar(
          title: AppStrings.scanResult,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(AppIcons.chevronLeft, color: context.appColorScheme.textPrimary, size: AppSizes.icon20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.history);
              }
            },
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: AppSizes.p16),
              child: SaveButton(
                isSaved: isSaved,
                isLoading: _isLoading,
                onTap: () async {
                  setState(() => _isLoading = true);
                  try {
                    await _toggleSave();
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Section (Header + Metrics)
              ScanHeroSection(scanData: widget.scanData, heroTag: widget.heroTag),

              // 3. What works for you
              _buildWorksForYou(context),

              // 4. What to watch / Additives
              AdditivesSection(scanData: widget.scanData),

              // 5. Meaning Banner
              _buildMeaningBanner(context),

              // 6. Swaps
              if (widget.scanData.swaps.isNotEmpty) BetterSwapsCarousel(swaps: widget.scanData.swaps),

              // 7. Ingredients
              if (widget.scanData.ingredients.isNotEmpty) IngredientsSection(ingredients: widget.scanData.ingredients, scanData: widget.scanData),

              // 8. Nutrition Table
              NutritionFactsSection(scanData: widget.scanData),
              Gap.h40,
            ],
          ),
        ),
      );
    },
  );

  Widget _buildWorksForYou(BuildContext context) {
    final items = <ScanImpactDetailItem>[];
    final scan = widget.scanData;
    final scheme = context.appColorScheme;

    if (scan.productName.toLowerCase().contains('organic')) {
      items.add(ScanImpactDetailItem(title: 'Organic', subtitle: 'No synthetic herbicides or pesticides', icon: AppIcons.leaf, value: 'CLEAN', color: scheme.success, showCheck: true));
    }

    if (scan.nutrients != null) {
      final n = scan.nutrients!;
      if (n.fiber != null && n.fiber! > 2) {
        items.add(ScanImpactDetailItem(title: AppStrings.fiber, subtitle: 'Great for gut motility', icon: AppIcons.salad, value: '${n.fiber}g', color: scheme.success));
      }
      if (n.proteins != null && n.proteins! > 5) {
        items.add(ScanImpactDetailItem(title: AppStrings.protein, subtitle: 'Essential amino acids', icon: AppIcons.zap, value: '${n.proteins}g', color: scheme.success));
      }
    }

    if (scan.nutrientLevels != null) {
      final l = scan.nutrientLevels!;
      if (l.sugars.toLowerCase() == 'low') {
        items.add(ScanImpactDetailItem(title: AppStrings.sugars, subtitle: 'No sugar added', icon: AppIcons.package, value: 'LOW', color: scheme.success));
      }
      if (l.saturatedFat.toLowerCase() == 'low') {
        items.add(ScanImpactDetailItem(title: AppStrings.saturatedFat, subtitle: 'No saturated fat', icon: AppIcons.droplet, value: 'LOW', color: scheme.success));
      }
      if (l.salt.toLowerCase() == 'low') {
        items.add(ScanImpactDetailItem(title: AppStrings.salt, subtitle: 'Low sodium content', icon: AppIcons.wheat, value: 'LOW', color: scheme.success));
      }
    }

    // Add green ingredients
    for (final ing in scan.ingredients.where((i) => i.colorName.toLowerCase() == 'green').take(2)) {
      items.add(ScanImpactDetailItem(title: ing.name, subtitle: ing.impact.isNotEmpty ? ing.impact : 'Clean ingredient', icon: AppIcons.leaf, value: 'CLEAN', color: scheme.success));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return ScanImpactSection(title: 'What works for you', icon: AppIcons.checkCircle, iconColor: scheme.success, servingInfo: scan.servingSize, items: items);
  }

  Widget _buildMeaningBanner(BuildContext context) {
    final profile = context.watch<ProfileNotifier>().profile;
    final cycleEnabled = profile?.cycleSyncEnabled ?? false;
    final cycleInsight = widget.scanData.cycleInsight;
    var insightText = widget.scanData.impact;
    if (cycleEnabled && cycleInsight != null && cycleInsight.description.isNotEmpty) {
      insightText = '${cycleInsight.description}\n\n$insightText';
    }

    if (insightText.isEmpty) return const SizedBox.shrink();

    return PersonalizedInsightCard(insight: insightText);
  }
}
