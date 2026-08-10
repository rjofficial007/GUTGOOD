import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/bottom_sheet_helper.dart';
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
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
                  padding: EdgeInsets.only(bottom: isLast ? AppSizes.p64 : AppSizes.p32),
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
    final sections = <Widget>[
      ProductHero(scanData: widget.scanData, heroTag: widget.heroTag),
      DashboardEntrance(
        delay: 100,
        child: GutDashboardSection(
          title: AppStrings.gutImpact,
          subtitle: AppStrings.gutGoodScore,
          visualization: GutImpactChart(score: widget.scanData.score),
          items: [
            _buildImpactItem(context, AppStrings.bloodSugar, AppIcons.activity),
            Gap.h12,
            _buildImpactItem(context, AppStrings.inflammation, AppIcons.shield),
            Gap.h12,
            _buildImpactItem(context, AppStrings.digestibility, AppIcons.moon),
            Gap.h12,
            _buildImpactItem(context, AppStrings.satiety, AppIcons.target),
          ],
          footerLabel: AppStrings.viewImpactDetails,
          onFooterTap: () => unawaited(_showGutImpactDetails(context)),
        ),
      ),
    ];

    final profile = context.watch<ProfileNotifier>().profile;
    final cycleEnabled = profile?.cycleSyncEnabled ?? false;
    final cycleInsight = widget.scanData.cycleInsight;
    if (cycleEnabled && cycleInsight != null && cycleInsight.description.isNotEmpty) {
      sections.add(CycleImpactDashboardSection(insight: cycleInsight));
    }

    if (widget.scanData.nutrientLevels != null) {
      sections.add(_NutrientLevelsSection(scanData: widget.scanData, onDetailsTap: () => unawaited(_showNutrientDetails(context))));
    }

    final hasAllergens = widget.scanData.allergens != null && widget.scanData.allergens!.isNotEmpty;
    final hasAdditives = widget.scanData.additives != null && widget.scanData.additives!.isNotEmpty;
    if (hasAllergens || hasAdditives) {
      sections.add(_SafetySection(scanData: widget.scanData));
    }

    if (widget.scanData.ingredients.isNotEmpty) {
      sections.add(_IngredientsSection(scanData: widget.scanData, onDetailsTap: () => unawaited(_showAllIngredients(context))));
    }

    if (widget.scanData.swaps.isNotEmpty) {
      sections.add(_SwapsSection(scanData: widget.scanData, onDetailsTap: () => unawaited(_showAllSwaps(context))));
    }

    sections.add(
      GutActionBanner(
        title: AppStrings.nutritionFacts,
        subtitle: AppStrings.per100g,
        icon: AppIcons.clipboardList,
        onTap: () => unawaited(context.push(AppRoutes.nutritionFacts, extra: widget.scanData.toMap())),
      ),
    );

    return sections;
  }

  DashboardDetailItem _buildImpactItem(BuildContext context, String title, IconData icon) {
    final impact = widget.scanData.impacts.firstWhere(
      (e) => e.title.toLowerCase().contains(title.toLowerCase()),
      orElse: () => const ImpactDetail(title: '', level: 'Neutral', color: 'gold'),
    );
    return DashboardDetailItem(title: impact.level, subtitle: title, icon: icon, color: context.appColorScheme.textPrimary);
  }

  Future<void> _showGutImpactDetails(BuildContext context) async {
    final scanData = widget.scanData;
    unawaited(sl<AnalyticsService>().logEvent(name: 'view_impact_details', parameters: {'product_name': scanData.productName}));
    final positive = scanData.impacts.where((e) => ['good', 'positive', 'healing', 'high'].contains(e.level.toLowerCase())).toList();
    final moderate = scanData.impacts.where((e) => ['moderate', 'neutral', 'gold'].contains(e.level.toLowerCase())).toList();
    final negative = scanData.impacts.where((e) => ['bad', 'negative', 'trigger', 'low'].contains(e.level.toLowerCase())).toList();

    await BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: AppStrings.gutImpact,
      children: [
        SheetHeroSection(title: scanData.score.toString(), subtitle: AppStrings.overallGutHealthRating, color: context.appColorScheme.textPrimary, icon: AppIcons.activity),
        Gap.h32,
        if (positive.isNotEmpty) ...[SheetSectionHeader(title: AppStrings.positiveMarkers, color: context.appColorScheme.textPrimary), ...positive.map((e) => _buildImpactTile(context, e)), Gap.h24],
        if (moderate.isNotEmpty) ...[
          SheetSectionHeader(title: AppStrings.neutralObservations, color: context.appColorScheme.textPrimary),
          ...moderate.map((e) => _buildImpactTile(context, e)),
          Gap.h24,
        ],
        if (negative.isNotEmpty) ...[SheetSectionHeader(title: AppStrings.potentialTriggers, color: context.appColorScheme.textPrimary), ...negative.map((e) => _buildImpactTile(context, e)), Gap.h24],
        Gap.h32,
        GutButton(label: AppStrings.gotItThanks, onTap: () => context.pop()),
        Gap.h24,
      ],
    );
  }

  Widget _buildImpactTile(BuildContext context, ImpactDetail impact) => Padding(
    padding: EdgeInsets.only(bottom: AppSizes.p12),
    child: DashboardDetailItem(
      title: impact.level,
      subtitle: '${AppStrings.factorIndicatingState}${impact.level.toLowerCase()} state.',
      icon: AppIcons.checkCircle,
      color: _getImpactColorByLevel(impact.level, context),
    ),
  );

  Color _getImpactColorByLevel(String level, BuildContext context) {
    switch (level.toLowerCase()) {
      case 'good':
      case 'positive':
      case 'healing':
      case 'high':
        return context.appColorScheme.success;
      case 'moderate':
      case 'neutral':
      case 'gold':
        return context.appColorScheme.warning;
      case 'bad':
      case 'negative':
      case 'trigger':
      case 'low':
        return context.appColorScheme.error;
      default:
        return context.appColorScheme.success;
    }
  }

  Future<void> _showNutrientDetails(BuildContext context) async {
    final levels = widget.scanData.nutrientLevels!;
    unawaited(sl<AnalyticsService>().logEvent(name: 'view_nutrient_details', parameters: {'product_name': widget.scanData.productName}));
    await BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: AppStrings.nutrientLevelsLabel,
      children: [
        SheetHeroSection(title: AppStrings.profile, subtitle: AppStrings.nutrientBenchmarking, color: context.appColorScheme.textPrimary, icon: AppIcons.flaskConical),
        Gap.h24,
        Text(
          AppStrings.nutrientLevelsDisclaimer,
          style: context.caption.copyWith(color: context.appColorScheme.textMuted, height: 1.4),
          textAlign: TextAlign.center,
        ),
        Gap.h32,
        DashboardDetailItem(title: levels.sugars, subtitle: AppStrings.sugars, icon: AppIcons.candy, color: context.appColorScheme.textPrimary),
        Gap.h16,
        DashboardDetailItem(title: levels.salt, subtitle: AppStrings.salt, icon: AppIcons.flaskConical, color: context.appColorScheme.textPrimary),
        Gap.h16,
        DashboardDetailItem(title: levels.fat, subtitle: AppStrings.fatLabel, icon: AppIcons.beef, color: context.appColorScheme.textPrimary),
        Gap.h16,
        DashboardDetailItem(title: levels.saturatedFat, subtitle: AppStrings.satFatLabel, icon: AppIcons.beef, color: context.appColorScheme.textPrimary),
        Gap.h40,
        GutButton(label: AppStrings.gotItThanks, onTap: () => context.pop()),
        Gap.h24,
      ],
    );
  }

  Future<void> _showAllIngredients(BuildContext context) async {
    final ingredients = widget.scanData.ingredients;
    unawaited(sl<AnalyticsService>().logEvent(name: 'view_all_ingredients', parameters: {'product_name': widget.scanData.productName}));
    final avoid = ingredients.where((e) => e.colorName.toLowerCase() == 'red').toList();
    final limit = ingredients.where((e) => e.colorName.toLowerCase() == 'orange').toList();
    final clean = ingredients.where((e) => !['red', 'orange'].contains(e.colorName.toLowerCase())).toList();

    final cleanCount = ingredients.where((e) => e.colorName.toLowerCase() == 'green' || e.colorName.toLowerCase() == 'low').length;
    final cleanRatio = ingredients.isNotEmpty ? cleanCount / ingredients.length : 0;

    await BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: AppStrings.ingredients,
      children: [
        SheetHeroSection(title: '${(cleanRatio * 100).toInt()}%', subtitle: AppStrings.cleanCompositionScore, color: context.appColorScheme.textPrimary, icon: AppIcons.leaf),
        Gap.h32,
        if (avoid.isNotEmpty) ...[SheetSectionHeader(title: AppStrings.ingredientsToAvoid, color: context.appColorScheme.textPrimary), ...avoid.map((e) => _buildIngredientTile(context, e)), Gap.h24],
        if (limit.isNotEmpty) ...[SheetSectionHeader(title: AppStrings.limitConsumption, color: context.appColorScheme.textPrimary), ...limit.map((e) => _buildIngredientTile(context, e)), Gap.h24],
        if (clean.isNotEmpty) ...[SheetSectionHeader(title: AppStrings.cleanIngredients, color: context.appColorScheme.textPrimary), ...clean.map((e) => _buildIngredientTile(context, e)), Gap.h24],
        Gap.h32,
        GutButton(label: AppStrings.gotItThanks, onTap: () => context.pop()),
        Gap.h24,
      ],
    );
  }

  Widget _buildIngredientTile(BuildContext context, Ingredient ing) => Padding(
    padding: EdgeInsets.only(bottom: AppSizes.p16),
    child: DashboardDetailItem(
      title: ing.name,
      subtitle: ing.impact.isNotEmpty ? ing.impact : getIngredientImpactLabel(ing.colorName),
      icon: InsightUiUtils.getIngredientIcon(ing.colorName),
      color: InsightUiUtils.getIngredientColor(ing.colorName, error: context.appColorScheme.error, warning: context.appColorScheme.warning, success: context.appColorScheme.success),
    ),
  );

  Future<void> _showAllSwaps(BuildContext context) async {
    final swaps = widget.scanData.swaps;
    unawaited(sl<AnalyticsService>().logEvent(name: 'view_all_swaps', parameters: {'product_name': widget.scanData.productName, 'count': swaps.length}));
    await BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: AppStrings.betterSwapsLabel,
      children: [
        SheetHeroSection(title: '${swaps.length}', subtitle: AppStrings.healthierAlternativesFound, color: context.appColorScheme.textPrimary, icon: AppIcons.sparkles),
        Gap.h32,
        ...swaps.map(
          (swap) => Padding(
            padding: EdgeInsets.only(bottom: AppSizes.p16),
            child: DashboardDetailItem(title: swap.title, subtitle: swap.subtitle, icon: AppIcons.package, color: context.appColorScheme.textPrimary),
          ),
        ),
        Gap.h32,
        GutButton(label: AppStrings.gotItThanks, onTap: () => context.pop()),
        Gap.h24,
      ],
    );
  }
}

class _NutrientLevelsSection extends StatelessWidget {
  const _NutrientLevelsSection({required this.scanData, required this.onDetailsTap});
  final ScanResult scanData;
  final VoidCallback onDetailsTap;

  @override
  Widget build(BuildContext context) {
    final levels = scanData.nutrientLevels!;
    return DashboardEntrance(
      delay: 300,
      child: GutDashboardSection(
        title: AppStrings.labelHealth,
        subtitle: AppStrings.nutrientLevelsLabel,
        visualization: const NutrientVisualization(),
        items: [
          _buildItem(context, levels.sugars, AppStrings.sugars, AppIcons.candy),
          Gap.h12,
          _buildItem(context, levels.salt, AppStrings.salt, AppIcons.flaskConical),
          Gap.h12,
          _buildItem(context, levels.fat, AppStrings.fatLabel, AppIcons.beef),
          Gap.h12,
          _buildItem(context, levels.saturatedFat, AppStrings.satFatLabel, AppIcons.beef),
        ],
        footerLabel: AppStrings.viewStandardValues,
        onFooterTap: onDetailsTap,
      ),
    );
  }

  DashboardDetailItem _buildItem(BuildContext context, String val, String subtitle, IconData icon) =>
      DashboardDetailItem(title: val, subtitle: subtitle, icon: icon, color: context.appColorScheme.textPrimary);
}

class _SafetySection extends StatelessWidget {
  const _SafetySection({required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final hasAllergens = scanData.allergens != null && scanData.allergens!.isNotEmpty;
    final hasAdditives = scanData.additives != null && scanData.additives!.isNotEmpty;

    if (!hasAllergens && !hasAdditives) return const SizedBox.shrink();

    return DashboardEntrance(
      delay: 400,
      child: GutDashboardSection(
        title: AppStrings.safe,
        subtitle: AppStrings.safetyCautions,
        visualization: CautionRiskIcon(isSafe: !hasAllergens),
        items: [
          if (hasAllergens) DashboardDetailItem(title: scanData.allergens!, subtitle: AppStrings.allergensLabel, icon: AppIcons.alertTriangle, color: context.appColorScheme.error),
          if (hasAllergens && hasAdditives) Gap.h12,
          if (hasAdditives) DashboardDetailItem(title: scanData.additives!, subtitle: AppStrings.additivesLabel, icon: AppIcons.flaskConical, color: context.appColorScheme.warning),
        ],
      ),
    );
  }
}

class _IngredientsSection extends StatelessWidget {
  const _IngredientsSection({required this.scanData, required this.onDetailsTap});
  final ScanResult scanData;
  final VoidCallback onDetailsTap;

  @override
  Widget build(BuildContext context) => DashboardEntrance(
    delay: 500,
    child: GutDashboardSection(
      title: AppStrings.mix,
      subtitle: AppStrings.ingredients,
      visualization: const DashboardIconVisualization(icon: AppIcons.flaskConical),
      items: scanData.ingredients.take(4).map((ing) {
        final color = InsightUiUtils.getIngredientColor(ing.colorName, error: context.appColorScheme.error, warning: context.appColorScheme.warning, success: context.appColorScheme.success);
        return Padding(
          padding: EdgeInsets.only(bottom: AppSizes.p12),
          child: DashboardDetailItem(title: ing.name, subtitle: getIngredientImpactLabel(ing.colorName), icon: InsightUiUtils.getIngredientIcon(ing.colorName), color: color),
        );
      }).toList(),
      footerLabel: AppStrings.viewAllIngredients,
      onFooterTap: onDetailsTap,
    ),
  );
}

class _SwapsSection extends StatelessWidget {
  const _SwapsSection({required this.scanData, required this.onDetailsTap});
  final ScanResult scanData;
  final VoidCallback onDetailsTap;

  @override
  Widget build(BuildContext context) => DashboardEntrance(
    delay: 600,
    child: GutDashboardSection(
      title: AppStrings.upgradeLabel,
      subtitle: AppStrings.betterSwapsLabel,
      visualization: const SwapVisualization(),
      items: scanData.swaps
          .take(3)
          .map(
            (swap) => Padding(
              padding: EdgeInsets.only(bottom: AppSizes.p12),
              child: DashboardDetailItem(title: swap.title, subtitle: swap.subtitle, icon: AppIcons.sparkles, color: context.appColorScheme.textPrimary),
            ),
          )
          .toList(),
      footerLabel: AppStrings.viewAllAlternatives,
      onFooterTap: onDetailsTap,
    ),
  );
}
