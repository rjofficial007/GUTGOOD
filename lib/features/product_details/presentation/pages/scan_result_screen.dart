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
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/history/presentation/providers/saved_foods_provider.dart';
import 'package:gutgood/features/insights/presentation/widgets/analysis_card.dart';
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
  Widget build(BuildContext context) {
    final visibleSections = _buildVisibleSections(context);

    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      body: CustomScrollView(
        slivers: [
          Consumer<SavedFoodsProvider>(
            builder: (context, savedProvider, _) {
              final isSaved = savedProvider.isSaved(widget.scanData.productName, barcode: widget.scanData.barcode);
              return ScanResultAppBar(
                isSaved: isSaved,
                isLoading: _isLoading,
                onSaveTap: () async {
                  setState(() => _isLoading = true);
                  try {
                    await _toggleSave();
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
              );
            },
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p10),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final isLast = index == visibleSections.length - 1;
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? AppSizes.p20 : AppSizes.p20),
                  child: visibleSections[index],
                );
              }, childCount: visibleSections.length),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildVisibleSections(BuildContext context) {
    final sections = <Widget>[ProductHero(scanData: widget.scanData, heroTag: widget.heroTag)];

    if (widget.scanData.nutrientLevels != null) {
      final levels = widget.scanData.nutrientLevels!;
      sections.add(
        DashboardEntrance(
          delay: 300,
          child: AnalysisCard(
            metric: 'NUTRIENT',
            label: AppStrings.nutrientLevelsLabel,
            icon: AppIcons.utensils,
            glowColor: context.appColorScheme.textPrimary,
            items: [
              AnalysisItem(title: levels.sugars.toUpperCase(), subtitle: AppStrings.sugars, icon: AppIcons.check, isDone: true),
              AnalysisItem(title: levels.salt.toUpperCase(), subtitle: AppStrings.salt, icon: AppIcons.check, isDone: true),
              AnalysisItem(title: levels.fat.toUpperCase(), subtitle: AppStrings.fatLabel, icon: AppIcons.check, isDone: true),
              AnalysisItem(title: levels.saturatedFat.toUpperCase(), subtitle: AppStrings.satFatLabel, icon: AppIcons.check, isDone: true),
            ],
          ),
        ),
      );
    }

    final hasAllergens = widget.scanData.allergens != null && widget.scanData.allergens!.isNotEmpty;
    final hasAdditives = widget.scanData.additives != null && widget.scanData.additives!.isNotEmpty;
    if (hasAllergens || hasAdditives) {
      sections.add(
        DashboardEntrance(
          delay: 400,
          child: AnalysisCard(
            metric: 'ALERT',
            label: AppStrings.safetyCautions,
            icon: AppIcons.alertTriangle,
            glowColor: AppPalette.red,
            items: [
              if (hasAllergens) AnalysisItem(title: widget.scanData.allergens!, subtitle: AppStrings.allergensLabel, icon: AppIcons.alertTriangle, isDone: true),
              if (hasAdditives) AnalysisItem(title: widget.scanData.additives!, subtitle: AppStrings.additivesLabel, icon: AppIcons.alertCircle, isDone: true),
            ],
          ),
        ),
      );
    }

    if (widget.scanData.ingredients.isNotEmpty) {
      sections.add(
        DashboardEntrance(
          delay: 500,
          child: AnalysisCard(
            metric: '${widget.scanData.ingredients.length}',
            label: AppStrings.ingredients,
            icon: AppIcons.clipboardList,
            glowColor: AppPalette.blue,
            items: widget.scanData.ingredients
                .map(
                  (ing) => AnalysisItem(
                    title: ing.name,
                    subtitle: '${getIngredientImpactLabel(ing.colorName)} • ${ing.impact}',
                    icon: ing.colorName.toLowerCase() == 'red' ? AppIcons.alertCircle : AppIcons.check,
                    isDone: true,
                  ),
                )
                .toList(),
          ),
        ),
      );
    }

    if (widget.scanData.swaps.isNotEmpty) {
      sections.add(
        DashboardEntrance(
          delay: 600,
          child: AnalysisCard(
            metric: '${widget.scanData.swaps.length}',
            label: AppStrings.betterSwapsLabel,
            icon: AppIcons.salad,
            glowColor: AppPalette.green,
            items: widget.scanData.swaps.map((swap) => AnalysisItem(title: swap.title, subtitle: swap.subtitle, icon: AppIcons.refreshCw, isDone: true)).toList(),
          ),
        ),
      );
    }

    final profile = context.watch<ProfileNotifier>().profile;
    final cycleEnabled = profile?.cycleSyncEnabled ?? false;
    final cycleInsight = widget.scanData.cycleInsight;
    if (cycleEnabled && cycleInsight != null && cycleInsight.description.isNotEmpty) {
      sections.add(CycleImpactDashboardSection(insight: cycleInsight));
    }

    sections.add(
      GutActionBanner(
        title: AppStrings.nutritionFacts,
        subtitle: AppStrings.per100g,
        icon: AppIcons.clipboardList,
        onTap: () => unawaited(context.push(AppRoutes.nutritionFacts, extra: widget.scanData)),
      ),
    );

    return sections;
  }

}
