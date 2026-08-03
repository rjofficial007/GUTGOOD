import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/firestore_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/bottom_sheet_helper.dart';
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

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
    final List<Widget?> sections = [
      _ProductHero(scanData: widget.scanData, heroTag: widget.heroTag),
      DashboardEntrance(delay: 100, child: _GutImpactSection(scanData: widget.scanData)),
      _buildCycleImpactSection(context),
      if (widget.scanData.nutrientLevels != null) DashboardEntrance(delay: 300, child: _NutrientDashboardSection(levels: widget.scanData.nutrientLevels!)),
      if ((widget.scanData.allergens != null && widget.scanData.allergens!.isNotEmpty) || (widget.scanData.additives != null && widget.scanData.additives!.isNotEmpty))
        DashboardEntrance(delay: 400, child: _CautionsDashboardSection(scanData: widget.scanData)),
      if (widget.scanData.ingredients.isNotEmpty) DashboardEntrance(delay: 500, child: _IngredientsDashboardSection(ingredients: widget.scanData.ingredients)),
      if (widget.scanData.swaps.isNotEmpty) DashboardEntrance(delay: 600, child: _SwapsDashboardSection(swaps: widget.scanData.swaps)),
      GutActionBanner(
        title: AppStrings.nutritionFacts,
        subtitle: AppStrings.per100g,
        icon: AppIcons.clipboardList,
        onTap: () => context.push(AppRoutes.nutritionFacts, extra: widget.scanData.toMap()),
      ),
    ];

    final visibleSections = sections.whereType<Widget>().toList();

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

  Widget? _buildCycleImpactSection(BuildContext context) {
    final profile = context.watch<ProfileNotifier>().profile;
    final bool cycleEnabled = profile?.cycleSyncEnabled ?? false;

    if (!cycleEnabled) return null;
    if (widget.scanData.cycleInsight == null || widget.scanData.cycleInsight!.description.isEmpty) {
      return null;
    }

    return DashboardEntrance(delay: 200, child: _CycleImpactDashboardSection(insight: widget.scanData.cycleInsight!));
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
    // 🟢 Fix: Handle potential empty strings from older DB records
    String? userImg = scanData.userImageUrl;
    if (userImg != null && userImg.isEmpty) userImg = null;
    String? prodImg = scanData.imageUrl;
    if (prodImg != null && prodImg.isEmpty) prodImg = null;

    final String? displayImageUrl = userImg ?? prodImg;

    return Container(
      decoration: BoxDecoration(
        color: context.appColorScheme.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.r24),
        border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: AppPalette.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(AppSizes.p16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: AppSizes.w80,
                  height: AppSizes.w80,
                  decoration: BoxDecoration(color: AppPalette.gray50, borderRadius: BorderRadius.circular(AppSizes.r16)),
                  child: displayImageUrl != null
                      ? Hero(
                          tag: heroTag ?? '${AppStrings.scanImageHero}${scanData.barcode ?? scanData.productName}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppSizes.r16),
                            child: CachedNetworkImage(
                              imageUrl: displayImageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: context.appColorScheme.border.withValues(alpha: 0.2),
                                highlightColor: context.appColorScheme.border.withValues(alpha: 0.1),
                                child: Container(color: Colors.white),
                              ),
                              errorWidget: (_, _, _) => Icon(AppIcons.package, size: AppSizes.icon32, color: context.appColorScheme.textMuted),
                            ),
                          ),
                        )
                      : Icon(AppIcons.package, size: AppSizes.icon32, color: context.appColorScheme.textMuted),
                ),
                Gap.w16,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scanData.productName,
                        style: context.bodyBold.copyWith(fontSize: AppSizes.s18, fontWeight: FontWeight.w800, height: 1.2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        scanData.brand,
                        style: context.caption.copyWith(color: context.appColorScheme.textMuted, fontSize: AppSizes.s13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Gap.h12,
                      Wrap(
                        spacing: AppSizes.p8,
                        runSpacing: AppSizes.p8,
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
    Color badgeColor = context.appColorScheme.elevatedSurface;
    if (label == AppStrings.nova.toUpperCase()) {
      badgeColor = context.appColorScheme.elevatedSurface;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.p10, vertical: AppSizes.p4 / 1.3),
      decoration: BoxDecoration(
        color: context.appColorScheme.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.r8),
        border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: context.eyebrow.copyWith(fontSize: AppSizes.s9, letterSpacing: 0.5)),
          Gap.w8,
          Container(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p6, vertical: AppSizes.p2),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(AppSizes.r4),
              border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
            ),
            child: Text(
              value,
              style: context.bodyBold.copyWith(fontSize: AppSizes.s11, color: context.appColorScheme.textPrimary),
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
    return DashboardCard(
      onFooterTap: () => _showGutImpactDetails(context),
      footerLabel: AppStrings.viewImpactDetails,
      child: Padding(
        padding: EdgeInsets.all(AppSizes.p20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Side: Score & Chart
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scanData.score.toString(),
                    style: context.bodyBold.copyWith(fontSize: AppSizes.s32, fontWeight: FontWeight.w900, letterSpacing: -1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    AppStrings.gutGoodScore,
                    style: context.caption.copyWith(color: context.appColorScheme.textMuted, fontSize: AppSizes.s12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap.h24,
                  const _GutImpactChart(),
                ],
              ),
            ),
            Gap.w16,
            // Right Side: Breakdown
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  DashboardDetailItem(title: _getImpactLevel(AppStrings.bloodSugar), subtitle: AppStrings.bloodSugar, icon: AppIcons.activity, color: context.appColorScheme.textPrimary),
                  Gap.h12,
                  DashboardDetailItem(title: _getImpactLevel(AppStrings.inflammation), subtitle: AppStrings.inflammation, icon: AppIcons.shield, color: context.appColorScheme.textPrimary),
                  Gap.h12,
                  DashboardDetailItem(title: _getImpactLevel(AppStrings.digestibility), subtitle: AppStrings.digestibility, icon: AppIcons.moon, color: context.appColorScheme.textPrimary),
                  Gap.h12,
                  DashboardDetailItem(title: _getImpactLevel(AppStrings.satiety), subtitle: AppStrings.satiety, icon: AppIcons.target, color: context.appColorScheme.textPrimary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGutImpactDetails(BuildContext context) {
    final positive = scanData.impacts.where((e) => ['good', 'positive', 'healing', 'high'].contains(e.level.toLowerCase())).toList();
    final moderate = scanData.impacts.where((e) => ['moderate', 'neutral', 'gold'].contains(e.level.toLowerCase())).toList();
    final negative = scanData.impacts.where((e) => ['bad', 'negative', 'trigger', 'low'].contains(e.level.toLowerCase())).toList();

    BottomSheetHelper.showGutBottomSheet(
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

  Widget _buildImpactTile(BuildContext context, ImpactDetail impact) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.p12),
      child: DashboardDetailItem(
        title: impact.title,
        subtitle: '${AppStrings.factorIndicatingState}${impact.level.toLowerCase()} state.',
        icon: AppIcons.checkCircle,
        color: _getImpactColorByLevel(impact.level, context),
      ),
    );
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

  String _getImpactLevel(String title) {
    final impact = scanData.impacts.firstWhere(
      (e) => e.title.toLowerCase().contains(title.toLowerCase()),
      orElse: () => const ImpactDetail(title: '', level: 'Neutral', color: 'gold'),
    );
    return impact.level;
  }
}

class _GutImpactChart extends StatelessWidget {
  const _GutImpactChart();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, width: double.infinity, color: context.appColorScheme.border.withValues(alpha: 0.5)),
        Gap.h16,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(5, (index) {
            final heights = [12.0, 8.0, 16.0, 24.0, 18.0];
            final colors = [
              context.appColorScheme.textPrimary,
              context.appColorScheme.textPrimary,
              context.appColorScheme.textPrimary,
              context.appColorScheme.textPrimary,
              context.appColorScheme.border,
            ];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: heights[index]),
              duration: Duration(milliseconds: 600 + (index * 100)),
              curve: Curves.easeOutQuart,
              builder: (context, value, _) {
                return Container(
                  width: 8.0.w,
                  height: value.h,
                  decoration: BoxDecoration(color: colors[index], borderRadius: BorderRadius.circular(4.0.r)),
                );
              },
            );
          }),
        ),
        Gap.h8,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '00:00',
              style: context.caption.copyWith(fontSize: 9.0.sp, color: context.appColorScheme.textMuted),
            ),
            Text(
              '12:00',
              style: context.caption.copyWith(fontSize: 9.0.sp, color: context.appColorScheme.textMuted),
            ),
            Text(
              '24:00',
              style: context.caption.copyWith(fontSize: 9.0.sp, color: context.appColorScheme.textMuted),
            ),
          ],
        ),
      ],
    );
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
        Consumer<ProfileNotifier>(
          builder: (context, profile, _) {
            return GutSnapshotHeroCard(score: scanData.score, streak: profile.profile?.streak ?? 0, isActive: true, borderRadius: 20.0);
          },
        ),
      ],
    );
  }
}

class _CycleImpactDashboardSection extends StatelessWidget {
  final CycleInsight insight;
  const _CycleImpactDashboardSection({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSizes.p24),
      decoration: BoxDecoration(
        color: context.appColorScheme.textPrimary,
        borderRadius: BorderRadius.circular(AppSizes.r28),
        boxShadow: [BoxShadow(color: AppPalette.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.phase, style: context.eyebrow.copyWith(color: context.appColorScheme.cardBackground.withValues(alpha: 0.8), letterSpacing: 2.0)),
                    Text(
                      insight.phase.toUpperCase(),
                      style: context.bodyBold.copyWith(color: context.appColorScheme.cardBackground, fontSize: AppSizes.s32, fontWeight: FontWeight.w900, height: 1.1),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Gap.w16,
              Container(
                padding: EdgeInsets.all(AppSizes.p12),
                decoration: BoxDecoration(color: context.appColorScheme.cardBackground.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: Icon(AppIcons.sun, color: context.appColorScheme.cardBackground, size: AppSizes.icon28),
              ),
            ],
          ),
          Gap.h24,
          Text(
            insight.description,
            style: context.body.copyWith(color: context.appColorScheme.cardBackground.withValues(alpha: 0.9), fontSize: AppSizes.s15, height: 1.4, fontWeight: FontWeight.w500),
          ),
          Gap.h16,
          Row(
            children: [
              Icon(AppIcons.trendingUp, color: context.appColorScheme.cardBackground, size: AppSizes.icon14),
              Gap.w8,
              Text(
                AppStrings.highMetabolicImpact,
                style: context.caption.copyWith(color: context.appColorScheme.cardBackground, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IngredientsDashboardSection extends StatelessWidget {
  final List<Ingredient> ingredients;
  const _IngredientsDashboardSection({required this.ingredients});

  @override
  Widget build(BuildContext context) {
    final displayIngredients = ingredients.take(4).toList();

    return DashboardCard(
      onFooterTap: () => _showAllIngredients(context),
      footerLabel: AppStrings.viewAllIngredients,
      child: Padding(
        padding: EdgeInsets.all(AppSizes.p20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Side: Composition Summary
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.mix,
                    style: context.bodyBold.copyWith(fontSize: AppSizes.s28, fontWeight: FontWeight.w900, letterSpacing: -1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    AppStrings.ingredients,
                    style: context.caption.copyWith(color: context.appColorScheme.textMuted, fontSize: AppSizes.s12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap.h24,
                  _IngredientCompositionVisualization(ingredients: ingredients),
                ],
              ),
            ),
            Gap.w16,
            // Right Side: Ingredient List
            Expanded(
              flex: 5,
              child: Column(
                children: displayIngredients.map((ing) {
                  final color = _getIngredientColor(ing.colorName, context);
                  return Padding(
                    padding: EdgeInsets.only(bottom: AppSizes.p12),
                    child: DashboardDetailItem(title: ing.name, subtitle: _getIngredientImpactLabel(ing.colorName), icon: InsightUiUtils.getIngredientIcon(ing.colorName), color: color),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllIngredients(BuildContext context) {
    final avoid = ingredients.where((e) => e.colorName.toLowerCase() == 'red').toList();
    final limit = ingredients.where((e) => e.colorName.toLowerCase() == 'orange').toList();
    final clean = ingredients.where((e) => !['red', 'orange'].contains(e.colorName.toLowerCase())).toList();

    int cleanCount = ingredients.where((e) => e.colorName.toLowerCase() == 'green' || e.colorName.toLowerCase() == 'low').length;
    double cleanRatio = ingredients.isNotEmpty ? cleanCount / ingredients.length : 0;

    BottomSheetHelper.showGutBottomSheet(
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

  Widget _buildIngredientTile(BuildContext context, Ingredient ing) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.p16),
      child: DashboardDetailItem(
        title: ing.name,
        subtitle: ing.impact.isNotEmpty ? ing.impact : _getIngredientImpactLabel(ing.colorName),
        icon: InsightUiUtils.getIngredientIcon(ing.colorName),
        color: _getIngredientColor(ing.colorName, context),
      ),
    );
  }

  Color _getIngredientColor(String colorName, BuildContext context) {
    return InsightUiUtils.getIngredientColor(colorName, error: context.appColorScheme.error, warning: context.appColorScheme.warning, success: context.appColorScheme.success);
  }
}

class _IngredientCompositionVisualization extends StatelessWidget {
  final List<Ingredient> ingredients;
  const _IngredientCompositionVisualization({required this.ingredients});

  @override
  Widget build(BuildContext context) {
    int cleanCount = ingredients.where((e) => e.colorName.toLowerCase() == 'green' || e.colorName.toLowerCase() == 'low').length;
    int total = ingredients.isNotEmpty ? ingredients.length : 1;
    double cleanRatio = cleanCount / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GutProgressBar(ratio: cleanRatio.clamp(0.0, 1.0)),
        Gap.h12,
        Text(
          '${(cleanRatio * 100).toInt()}% ${AppStrings.cleanComposition}',
          style: context.caption.copyWith(fontSize: AppSizes.s10, color: context.appColorScheme.textMuted),
        ),
      ],
    );
  }
}

class _NutrientDashboardSection extends StatelessWidget {
  final NutrientLevels levels;
  const _NutrientDashboardSection({required this.levels});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      onFooterTap: () => _showNutrientDetails(context),
      footerLabel: AppStrings.viewStandardValues,
      child: Padding(
        padding: EdgeInsets.all(20.0.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Side: Summary Visualization
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HEALTH',
                    style: context.bodyBold.copyWith(fontSize: AppSizes.s28, fontWeight: FontWeight.w900, letterSpacing: -1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    AppStrings.nutrientLevelsLabel,
                    style: context.caption.copyWith(color: context.appColorScheme.textMuted, fontSize: AppSizes.s12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap.h24,
                  const _NutrientVisualization(),
                ],
              ),
            ),
            Gap.w16,
            // Right Side: Details
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  DashboardDetailItem(title: levels.sugars, subtitle: AppStrings.sugars, icon: AppIcons.candy, color: _getNutrientColor(levels.sugars, context)),
                  Gap.h12,
                  DashboardDetailItem(title: levels.salt, subtitle: AppStrings.salt, icon: AppIcons.flaskConical, color: _getNutrientColor(levels.salt, context)),
                  Gap.h12,
                  DashboardDetailItem(title: levels.fat, subtitle: AppStrings.fatLabel, icon: AppIcons.beef, color: _getNutrientColor(levels.fat, context)),
                  Gap.h12,
                  DashboardDetailItem(title: levels.saturatedFat, subtitle: AppStrings.satFatLabel, icon: AppIcons.beef, color: _getNutrientColor(levels.saturatedFat, context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNutrientDetails(BuildContext context) {
    BottomSheetHelper.showGutBottomSheet(
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
        DashboardDetailItem(title: levels.sugars, subtitle: AppStrings.sugars, icon: AppIcons.candy, color: _getNutrientColor(levels.sugars, context)),
        Gap.h16,
        DashboardDetailItem(title: levels.salt, subtitle: AppStrings.salt, icon: AppIcons.flaskConical, color: _getNutrientColor(levels.salt, context)),
        Gap.h16,
        DashboardDetailItem(title: levels.fat, subtitle: AppStrings.fatLabel, icon: AppIcons.beef, color: _getNutrientColor(levels.fat, context)),
        Gap.h16,
        DashboardDetailItem(title: levels.saturatedFat, subtitle: AppStrings.satFatLabel, icon: AppIcons.beef, color: _getNutrientColor(levels.saturatedFat, context)),
        Gap.h40,
        GutButton(label: AppStrings.gotItThanks, onTap: () => context.pop()),
        Gap.h24,
      ],
    );
  }

  Color _getNutrientColor(String? val, BuildContext context) {
    return context.appColorScheme.textPrimary;
  }
}

class _NutrientVisualization extends StatelessWidget {
  const _NutrientVisualization();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GutProgressBar(ratio: 0.7),
        Gap.h12,
        Text(
          AppStrings.optimalProfileIdentified,
          style: context.caption.copyWith(fontSize: AppSizes.s10, color: context.appColorScheme.textMuted),
        ),
      ],
    );
  }
}

class _CautionsDashboardSection extends StatelessWidget {
  final ScanResult scanData;
  const _CautionsDashboardSection({required this.scanData});

  @override
  Widget build(BuildContext context) {
    final hasAllergens = scanData.allergens != null && scanData.allergens!.isNotEmpty;
    final hasAdditives = scanData.additives != null && scanData.additives!.isNotEmpty;

    return DashboardCard(
      child: Padding(
        padding: EdgeInsets.all(AppSizes.p20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Side: Risk Indicator
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.safe,
                    style: context.bodyBold.copyWith(fontSize: AppSizes.s28, fontWeight: FontWeight.w900, letterSpacing: -1, color: context.appColorScheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    AppStrings.safetyCautions,
                    style: context.caption.copyWith(color: context.appColorScheme.textMuted, fontSize: AppSizes.s12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap.h24,
                  _CautionRiskIcon(isSafe: !hasAllergens),
                ],
              ),
            ),
            Gap.w16,
            // Right Side: Detail List
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  if (hasAllergens) DashboardDetailItem(title: scanData.allergens!, subtitle: AppStrings.allergensLabel, icon: AppIcons.alertTriangle, color: context.appColorScheme.error),
                  if (hasAllergens && hasAdditives) Gap.h12,
                  if (hasAdditives) DashboardDetailItem(title: scanData.additives!, subtitle: AppStrings.additivesLabel, icon: AppIcons.flaskConical, color: context.appColorScheme.warning),
                  if (!hasAllergens && !hasAdditives) Text(AppStrings.noCautionsFound, style: context.caption.copyWith(color: context.appColorScheme.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CautionRiskIcon extends StatelessWidget {
  final bool isSafe;
  const _CautionRiskIcon({required this.isSafe});

  @override
  Widget build(BuildContext context) {
    final color = context.appColorScheme.textPrimary;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        padding: EdgeInsets.all(AppSizes.p12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(isSafe ? AppIcons.shieldCheck : AppIcons.alertCircle, color: color, size: AppSizes.icon32),
      ),
    );
  }
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

class _SwapsDashboardSection extends StatelessWidget {
  final List<ProductSwap> swaps;
  const _SwapsDashboardSection({required this.swaps});

  @override
  Widget build(BuildContext context) {
    final displaySwaps = swaps.take(3).toList();

    return DashboardCard(
      onFooterTap: () => _showAllSwaps(context),
      footerLabel: AppStrings.viewAllAlternatives,
      child: Padding(
        padding: EdgeInsets.all(AppSizes.p20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Side: Upgrade Hero
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.upgradeLabel,
                    style: context.bodyBold.copyWith(fontSize: AppSizes.s28, fontWeight: FontWeight.w900, letterSpacing: -1, color: context.appColorScheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    AppStrings.betterSwapsLabel,
                    style: context.caption.copyWith(color: context.appColorScheme.textMuted, fontSize: AppSizes.s12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap.h24,
                  const _SwapVisualization(),
                ],
              ),
            ),
            Gap.w16,
            // Right Side: Swap List
            Expanded(
              flex: 5,
              child: Column(
                children: displaySwaps.map((swap) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: AppSizes.p12),
                    child: DashboardDetailItem(title: swap.title, subtitle: swap.subtitle, icon: AppIcons.sparkles, color: context.appColorScheme.textPrimary),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllSwaps(BuildContext context) {
    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: AppStrings.betterSwapsLabel,
      children: [
        SheetHeroSection(title: '${swaps.length}', subtitle: AppStrings.healthierAlternativesFound, color: context.appColorScheme.textPrimary, icon: AppIcons.sparkles),
        Gap.h32,
        ...swaps.map((swap) {
          return Padding(
            padding: EdgeInsets.only(bottom: AppSizes.p16),
            child: DashboardDetailItem(title: swap.title, subtitle: swap.subtitle, icon: AppIcons.package, color: context.appColorScheme.textPrimary),
          );
        }),
        Gap.h32,
        GutButton(label: AppStrings.gotItThanks, onTap: () => context.pop()),
        Gap.h24,
      ],
    );
  }
}

class _SwapVisualization extends StatelessWidget {
  const _SwapVisualization();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(AppSizes.p12),
          decoration: BoxDecoration(
            color: context.appColorScheme.elevatedSurface,
            shape: BoxShape.circle,
            border: Border.all(color: context.appColorScheme.border),
          ),
          child: Icon(AppIcons.arrowRightLeft, color: context.appColorScheme.textPrimary, size: AppSizes.icon32),
        ),
        Gap.h16,
        Text(
          AppStrings.optimizedChoices,
          style: context.caption.copyWith(fontSize: AppSizes.s10, color: context.appColorScheme.textMuted),
        ),
      ],
    );
  }
}
