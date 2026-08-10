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
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/bottom_sheet_helper.dart';
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/history/presentation/providers/saved_foods_provider.dart';
import 'package:gutgood/features/insights/presentation/widgets/neon_glow_card.dart';
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
        child: GestureDetector(
          onTap: () => unawaited(_showGutImpactDetails(context)),
          child: NeonGlowCard(
            metric: '${widget.scanData.score}',
            label: AppStrings.gutImpact,
            icon: AppIcons.activity,
            glowColor: _getImpactColorByLevel(widget.scanData.score > 70 ? 'good' : (widget.scanData.score > 40 ? 'moderate' : 'bad'), context),
            items: widget.scanData.impacts.map((e) => NeonGlowItem(title: e.level, subtitle: e.title, isDone: ['good', 'positive', 'healing', 'high'].contains(e.level.toLowerCase()))).toList(),
          ),
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
      final levels = widget.scanData.nutrientLevels!;
      sections.add(
        DashboardEntrance(
          delay: 300,
          child: GestureDetector(
            onTap: () => unawaited(_showNutrientDetails(context)),
            child: NeonGlowCard(
              metric: 'PROFILE',
              label: AppStrings.nutrientLevelsLabel,
              icon: AppIcons.utensils,
              glowColor: context.appColorScheme.textPrimary,
              items: [
                NeonGlowItem(title: levels.sugars, subtitle: AppStrings.sugars, isDone: true),
                NeonGlowItem(title: levels.salt, subtitle: AppStrings.salt, isDone: true),
                NeonGlowItem(title: levels.fat, subtitle: AppStrings.fatLabel, isDone: true),
              ],
            ),
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
          child: NeonGlowCard(
            metric: 'ALERT',
            label: AppStrings.safetyCautions,
            icon: AppIcons.alertTriangle,
            glowColor: AppPalette.red,
            items: [
              if (hasAllergens) NeonGlowItem(title: widget.scanData.allergens!, subtitle: AppStrings.allergensLabel),
              if (hasAdditives) NeonGlowItem(title: widget.scanData.additives!, subtitle: AppStrings.additivesLabel),
            ],
          ),
        ),
      );
    }

    if (widget.scanData.ingredients.isNotEmpty) {
      sections.add(
        DashboardEntrance(
          delay: 500,
          child: GestureDetector(
            onTap: () => unawaited(_showAllIngredients(context)),
            child: NeonGlowCard(
              metric: '${widget.scanData.ingredients.length}',
              label: AppStrings.ingredients,
              icon: AppIcons.clipboardList,
              glowColor: AppPalette.blue,
              items: widget.scanData.ingredients.map((ing) => NeonGlowItem(title: ing.name, subtitle: getIngredientImpactLabel(ing.colorName), isDone: ing.colorName.toLowerCase() == 'green')).toList(),
            ),
          ),
        ),
      );
    }

    if (widget.scanData.swaps.isNotEmpty) {
      sections.add(
        DashboardEntrance(
          delay: 600,
          child: GestureDetector(
            onTap: () => unawaited(_showAllSwaps(context)),
            child: NeonGlowCard(
              metric: '${widget.scanData.swaps.length}',
              label: AppStrings.betterSwapsLabel,
              icon: AppIcons.sparkles,
              glowColor: AppPalette.green,
              items: widget.scanData.swaps.map((swap) => NeonGlowItem(title: swap.title, subtitle: swap.subtitle, isDone: true)).toList(),
            ),
          ),
        ),
      );
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

