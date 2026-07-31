import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/firestore_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class ScanResultScreen extends StatefulWidget {
  final ScanResult scanData;
  final String? heroTag;

  const ScanResultScreen({super.key, required this.scanData, this.heroTag});

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  bool _isSaved = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkSavedStatus();
  }

  Future<void> _checkSavedStatus() async {
    final saved = await sl<FirestoreService>().isFoodSaved(widget.scanData.productName, barcode: widget.scanData.barcode);
    if (mounted) setState(() => _isSaved = saved);
  }

  Future<void> _toggleSave() async {
    await sl<FirestoreService>().toggleSaveFood(widget.scanData);
    _checkSavedStatus();
    sl<AppStateService>().notifyProfileUpdated();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      body: CustomScrollView(
        slivers: [
          GutSliverAppBar(
            title: AppStrings.scanResult,
            leading: IconButton(
              icon: Icon(AppIcons.chevronLeft, color: context.appColorScheme.textPrimary),
              onPressed: () => context.pop(),
            ),
            actions: [
              _SaveButton(
                isSaved: _isSaved,
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
              Gap.w16,
            ],
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: Responsive.w(20.0), vertical: Responsive.h(10.0)),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ProductHero(scanData: widget.scanData, heroTag: widget.heroTag),
                Gap.h32,
                _GutImpactSection(scanData: widget.scanData),
                Gap.h32,
                _buildCycleImpactSection(context),
                if (widget.scanData.nutrientLevels != null) ...[
                  GutSection(
                    title: AppStrings.nutrientLevelsLabel,
                    info: 'Key markers identified by health standards.',
                    topPadding: 0,
                    child: _NutrientLevelsGrid(levels: widget.scanData.nutrientLevels!),
                  ),
                  Gap.h32,
                ],
                if ((widget.scanData.allergens != null && widget.scanData.allergens!.isNotEmpty) || (widget.scanData.additives != null && widget.scanData.additives!.isNotEmpty)) ...[
                  GutSection(
                    title: AppStrings.cautions,
                    info: 'Specific ingredients to be aware of based on your profile.',
                    topPadding: 0,
                    child: _CautionsList(scanData: widget.scanData),
                  ),
                  Gap.h32,
                ],
                if (widget.scanData.ingredients.isNotEmpty) ...[
                  GutSection(
                    title: AppStrings.ingredients,
                    info: 'Full list of identified ingredients with color-coded risk levels.',
                    topPadding: 0,
                    child: _IngredientsList(ingredients: widget.scanData.ingredients),
                  ),
                  Gap.h32,
                ],
                if (widget.scanData.swaps.isNotEmpty) ...[
                  GutSection(
                    title: AppStrings.betterSwapsLabel,
                    info: 'Healthier alternatives that satisfy the same craving.',
                    topPadding: 0,
                    child: _SwapsScroll(swaps: widget.scanData.swaps),
                  ),
                  Gap.h24,
                ],
                GutActionBanner(
                  title: AppStrings.nutritionFacts,
                  subtitle: AppStrings.per100g,
                  icon: AppIcons.clipboardList,
                  onTap: () => context.push('/nutrition-facts', extra: widget.scanData.toMap()),
                ),
                Gap.h64,
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleImpactSection(BuildContext context) {
    final profile = context.watch<ProfileNotifier>().profile;
    final bool cycleEnabled = profile?.cycleSyncEnabled ?? false;

    if (!cycleEnabled) return const SizedBox.shrink();
    if (widget.scanData.cycleInsight == null || widget.scanData.cycleInsight!.description.isEmpty) {
      return const SizedBox.shrink();
    }

    return GutSection(
      title: AppStrings.cycleImpact,
      info: 'How this food interacts with your current hormonal phase.',
      topPadding: 0,
      child: _CycleImpactCard(insight: widget.scanData.cycleInsight!),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isSaved;
  final bool isLoading;
  final VoidCallback onTap;

  const _SaveButton({required this.isSaved, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: isLoading
          ? SizedBox(
              width: AppSizes.icon24,
              height: AppSizes.icon24,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: context.appColorScheme.error),
            )
          : Icon(isSaved ? Icons.favorite : Icons.favorite_border, color: isSaved ? context.appColorScheme.error : context.appColorScheme.textMuted, size: 24.0.w),
    );
  }
}

class _ProductHero extends StatelessWidget {
  final ScanResult scanData;
  final String? heroTag;
  const _ProductHero({required this.scanData, this.heroTag});

  @override
  Widget build(BuildContext context) {
    final String? displayImageUrl = scanData.userImageUrl ?? scanData.imageUrl;

    return Container(
      decoration: BoxDecoration(
        color: context.appColorScheme.cardBackground,
        borderRadius: BorderRadius.circular(24.0.r),
        border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(Responsive.w(16.0)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80.0.w,
                  height: 80.0.w,
                  decoration: BoxDecoration(color: AppPalette.gray50, borderRadius: BorderRadius.circular(16.0.r)),
                  child: displayImageUrl != null
                      ? Hero(
                          tag: heroTag ?? '${AppStrings.scanImageHero}${scanData.barcode ?? scanData.productName}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16.0.r),
                            child: CachedNetworkImage(
                              imageUrl: displayImageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: CircularProgressIndicator(strokeWidth: 2.w, color: context.appColorScheme.textMuted),
                              ),
                              errorWidget: (_, _, _) => Icon(AppIcons.package, size: 32.0.w, color: context.appColorScheme.textMuted),
                            ),
                          ),
                        )
                      : Icon(AppIcons.package, size: 32.0.w, color: context.appColorScheme.textMuted),
                ),
                Gap.w16,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scanData.productName,
                        style: context.bodyBold.copyWith(fontSize: 18.0.sp, fontWeight: FontWeight.w800, height: 1.2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        scanData.brand,
                        style: context.caption.copyWith(color: context.appColorScheme.textMuted, fontSize: 13.0.sp),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Gap.h12,
                      Wrap(
                        spacing: 8.0.w,
                        runSpacing: 8.0.h,
                        children: [
                          if (scanData.nutriscore != null) _ClassificationBadge(label: AppStrings.nutriScore.toUpperCase(), value: scanData.nutriscore!.toUpperCase()),
                          if (scanData.novaGroup != null) _ClassificationBadge(label: AppStrings.nova.toUpperCase(), value: scanData.novaGroup!),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          _GutGoodScoreSection(scanData: scanData),
        ],
      ),
    );
  }
}

class _ClassificationBadge extends StatelessWidget {
  final String label;
  final String value;
  const _ClassificationBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    Color badgeColor = AppPalette.lime;
    if (label == AppStrings.nova.toUpperCase()) {
      badgeColor = AppPalette.gray50;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.0.w, vertical: 3.0.h),
      decoration: BoxDecoration(
        color: context.appColorScheme.cardBackground,
        borderRadius: BorderRadius.circular(8.0.r),
        border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: context.eyebrow.copyWith(fontSize: 9.0.sp, letterSpacing: 0.5)),
          Gap.w8,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.0.w, vertical: 2.0.h),
            decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(4.0.r)),
            child: Text(
              value,
              style: context.bodyBold.copyWith(fontSize: 11.0.sp, color: AppPalette.black),
            ),
          ),
        ],
      ),
    );
  }
}

class _GutImpactSection extends StatelessWidget {
  final ScanResult scanData;
  const _GutImpactSection({required this.scanData});

  @override
  Widget build(BuildContext context) {
    return GutSection(
      title: AppStrings.gutImpact,
      info: 'How this food interacts with your body based on recent patterns.',
      topPadding: 0,
      child: AdaptiveGrid(
        mainAxisExtent: Responsive.h(100.0),
        items: [
          _buildImpactTile(context, AppStrings.bloodSugar, AppIcons.activity),
          _buildImpactTile(context, AppStrings.digestibility, AppIcons.moon),
          _buildImpactTile(context, AppStrings.inflammation, AppIcons.shield),
          _buildImpactTile(context, AppStrings.satiety, AppIcons.target),
        ],
      ),
    );
  }

  Widget _buildImpactTile(BuildContext context, String label, IconData icon) {
    final status = _getImpactLevel(label);
    final color = _getImpactColorByLevel(status, context);

    return GutInsightTile(title: label, value: status, subtitle: '', icon: icon, statusColor: color);
  }

  String _getImpactLevel(String title) {
    final impact = scanData.impacts.firstWhere(
      (e) => e.title.toLowerCase().contains(title.toLowerCase()),
      orElse: () => const ImpactDetail(title: '', level: 'Neutral', color: 'gold'),
    );
    return impact.level;
  }

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
}

class _GutGoodScoreSection extends StatelessWidget {
  final ScanResult scanData;
  const _GutGoodScoreSection({required this.scanData});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValueListenableBuilder(
          valueListenable: sl<AppStateService>().insightsData,
          builder: (context, insight, _) {
            return GutSnapshotHeroCard(score: scanData.score, streak: insight?.streak ?? 0, simpleTrend: [], isActive: true, borderRadius: 20.0);
          },
        ),
      ],
    );
  }
}

class _CycleImpactCard extends StatelessWidget {
  final CycleInsight insight;
  const _CycleImpactCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0.w),
      decoration: BoxDecoration(
        color: AppPalette.pink.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24.0.r),
        border: Border.all(color: AppPalette.pink.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.0.w),
            decoration: const BoxDecoration(color: AppPalette.pink, shape: BoxShape.circle),
            child: Icon(AppIcons.flower, color: Colors.white, size: 20.0.w),
          ),
          Gap.w16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.phase.toUpperCase(),
                  style: context.bodyBold.copyWith(color: AppPalette.pink, fontSize: 12.0.sp, letterSpacing: 1.0),
                ),
                Gap.h2,
                Text(insight.description, style: context.body.copyWith(fontSize: 13.0.sp, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NutrientLevelsGrid extends StatelessWidget {
  final NutrientLevels levels;
  const _NutrientLevelsGrid({required this.levels});

  @override
  Widget build(BuildContext context) {
    return AdaptiveGrid(
      mainAxisExtent: Responsive.h(100.0),
      items: [
        _buildNutrientTile(context, AppStrings.sugars, levels.sugars, AppIcons.candy),
        _buildNutrientTile(context, AppStrings.salt, levels.salt, AppIcons.flaskConical),
        _buildNutrientTile(context, AppStrings.fatLabel, levels.fat, AppIcons.beef),
        _buildNutrientTile(context, AppStrings.satFatLabel, levels.saturatedFat, AppIcons.beef),
      ],
    );
  }

  Widget _buildNutrientTile(BuildContext context, String label, String? value, IconData icon) {
    final Color color = _getNutrientColor(value, context);
    return GutInsightTile(title: label, value: value?.toUpperCase() ?? 'N/A', subtitle: '', icon: icon, statusColor: color);
  }

  Color _getNutrientColor(String? val, BuildContext context) {
    switch (val?.toLowerCase()) {
      case 'low':
        return context.appColorScheme.success;
      case 'moderate':
        return context.appColorScheme.warning;
      case 'high':
        return context.appColorScheme.error;
      default:
        return context.appColorScheme.textMuted;
    }
  }
}

class _CautionsList extends StatelessWidget {
  final ScanResult scanData;
  const _CautionsList({required this.scanData});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (scanData.allergens != null && scanData.allergens!.isNotEmpty)
          _CautionCard(title: '${AppStrings.allergensLabel.toUpperCase()} DETECTED', content: scanData.allergens!, icon: AppIcons.alertTriangle, color: context.appColorScheme.error),
        if (scanData.additives != null && scanData.additives!.isNotEmpty) ...[
          if (scanData.allergens != null && scanData.allergens!.isNotEmpty) Gap.h12,
          _CautionCard(title: '${AppStrings.additivesLabel.toUpperCase()} FOUND', content: scanData.additives!, icon: AppIcons.flaskConical, color: context.appColorScheme.warning),
        ],
      ],
    );
  }
}

class _CautionCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color color;

  const _CautionCard({required this.title, required this.content, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.w(16.0)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(20.0.r),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.0.w),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20.0.w),
          ),
          Gap.w16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.eyebrow.copyWith(color: color, letterSpacing: 1.2)),
                Gap.h4,
                Text(content, style: context.bodyBold.copyWith(fontSize: 15.0.sp, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientsList extends StatelessWidget {
  final List<Ingredient> ingredients;
  const _IngredientsList({required this.ingredients});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: ingredients.map((ing) {
        final color = _getIngredientColor(ing.colorName, context);
        return Container(
          margin: EdgeInsets.only(bottom: 12.0.h),
          padding: EdgeInsets.all(16.0.w),
          decoration: BoxDecoration(
            color: context.appColorScheme.cardBackground,
            borderRadius: BorderRadius.circular(20.0.r),
            border: Border.all(color: context.appColorScheme.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.only(top: 4.0.h),
                width: 32.0.w,
                height: 32.0.w,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(_getIngredientIcon(ing.colorName), color: color, size: 16.0.w),
              ),
              Gap.w16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(ing.name, style: context.bodyBold.copyWith(fontSize: 16.0.sp)),
                        ),
                        Gap.w8,
                        _IngredientBadge(colorName: ing.colorName),
                      ],
                    ),
                    if (ing.impact.isNotEmpty) ...[
                      Gap.h4,
                      Text(
                        ing.impact,
                        style: context.caption.copyWith(color: context.appColorScheme.textSecondary, fontSize: 12.0.sp, height: 1.4, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _getIngredientIcon(String colorName) {
    return InsightUiUtils.getIngredientIcon(colorName);
  }

  Color _getIngredientColor(String colorName, BuildContext context) {
    return InsightUiUtils.getIngredientColor(colorName, error: context.appColorScheme.error, warning: context.appColorScheme.warning, success: context.appColorScheme.success);
  }
}

class _IngredientBadge extends StatelessWidget {
  final String colorName;
  const _IngredientBadge({required this.colorName});

  @override
  Widget build(BuildContext context) {
    final color = _getIngredientColor(colorName, context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0.w, vertical: 4.0.h),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8.0.r)),
      child: Text(
        _getIngredientImpactLabel(colorName).toUpperCase(),
        style: context.caption.copyWith(color: color, fontWeight: FontWeight.w900, fontSize: 8.0.sp),
      ),
    );
  }

  String _getIngredientImpactLabel(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return 'Avoid';
      case 'orange':
        return 'Limit';
      default:
        return 'Clean';
    }
  }

  Color _getIngredientColor(String colorName, BuildContext context) {
    return InsightUiUtils.getIngredientColor(colorName, error: context.appColorScheme.error, warning: context.appColorScheme.warning, success: context.appColorScheme.success);
  }
}

class _SwapsScroll extends StatelessWidget {
  final List<ProductSwap> swaps;
  const _SwapsScroll({required this.swaps});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: swaps
            .map(
              (swap) => Padding(
                padding: EdgeInsets.only(right: 12.0.w),
                child: SwapCard(title: swap.title, subtitle: swap.subtitle, imageKeyword: swap.imageKeyword, tag: swap.tag, badge: swap.badge),
              ),
            )
            .toList(),
      ),
    );
  }
}
