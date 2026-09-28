import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/data/additive_concern_db.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/gut_score_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_button.dart';
import 'package:gutgood/features/scanner/presentation/providers/scanner_notifier.dart';
import 'package:gutgood/features/scanner/presentation/widgets/scan_detail_sections.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class ScanSummarySheet extends StatefulWidget {
  const ScanSummarySheet({super.key, required this.product, this.capturedImage});
  final OffProduct product;
  final Uint8List? capturedImage;

  @override
  State<ScanSummarySheet> createState() => _ScanSummarySheetState();
}

class _ScanSummarySheetState extends State<ScanSummarySheet> {
  ScanResult? _analyzedResult;

  ScanResult get _headerScanData {
    if (_analyzedResult != null) return _analyzedResult!;

    final p = widget.product;
    final score = p.gutScore;
    final band = GutScoreBand.fromScore(score);
    final impactType = (band == GutScoreBand.excellent || band == GutScoreBand.great)
        ? ImpactType.positive
        : (band == GutScoreBand.good || band == GutScoreBand.fair ? ImpactType.neutral : ImpactType.negative);

    return ScanResult(
      productName: p.productName,
      brand: p.brand ?? 'GutGood',
      score: score,
      impactType: impactType,
      impact: 'Product from Open Food Facts Database',
      category: p.categoryTag ?? 'food',
      imageUrl: p.imageUrl,
      nutriscore: p.nutriscore,
      novaGroup: p.novaGroup?.toString(),
      createdAt: DateTime.now(),
    );
  }

  /// All nutrient figures in the Positives/Negatives sections come from OFF's
  /// per-100 g values (`Nutriments.getValue(..., PerSize.oneHundredGrams)`),
  /// so we always label that basis explicitly (100 ml for beverages).
  String get _perBasisLabel => widget.product.nutrientDataPer == '100ml' ? '100 ml' : '100 g';

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isAnalyzed = _analyzedResult != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      snap: true,
      shouldCloseOnMinExtent: false,
      expand: false,
      builder: (context, scrollController) => DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: const [BoxShadow(color: AppPalette.scrim, blurRadius: 20, offset: Offset(0, -5))],
        ),
        child: Column(
          children: [
            // Top Bar with Drag Handle & Close Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 4),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Drag Handle Bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: scheme.borderSubtle, borderRadius: BorderRadius.circular(2)),
                  ),

                  // Explicit Close Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: scheme.elevatedSurface,
                          shape: BoxShape.circle,
                          border: Border.all(color: scheme.borderSubtle),
                        ),
                        child: Icon(Icons.close_rounded, size: 18.sp, color: scheme.textPrimary),
                      ),
                      tooltip: 'Close Summary',
                      splashRadius: 20,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                controller: scrollController,
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(AppSizes.p20, 0, AppSizes.p20, MediaQuery.of(context).padding.bottom + AppSizes.p24),
                children: [
                  // 1. Header (Image + Name + Score)
                  _buildHeader(context),

                  Gap.h24,

                  // 2. Intelligence Result
                  if (isAnalyzed) ...[_buildAnalyzedContent(context), Gap.h24],

                  // 3. Positives Section (all figures are per 100 g)
                  _buildFactorSection(context, title: AppStrings.positivesLabel, subtitle: 'per $_perBasisLabel', factors: _getPositives(context)),

                  Gap.h24,

                  // 4. Negatives Section (all figures are per 100 g)
                  _buildFactorSection(context, title: AppStrings.negativesLabel, subtitle: 'per $_perBasisLabel', factors: _getNegatives(context)),

                  Gap.h24,

                  // 5. Full OFF fact sheet — expandable sections, shown only
                  // for data that actually exists on the product.
                  ScanProductDetails(product: widget.product),

                  Gap.h24,

                  // 6. Action CTA Button
                  _buildActionButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final scheme = context.appColorScheme;
    final scanData = _headerScanData;
    final band = GutScoreBand.fromScore(scanData.score);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Image
        Hero(
          tag: 'product_image_${scanData.productName}',
          child: Container(
            width: 80.w,
            height: 120.h,
            decoration: BoxDecoration(color: scheme.elevatedSurface, borderRadius: BorderRadius.circular(12)),
            child: (widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty)
                ? Image.network(
                    widget.product.imageUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Icon(AppIcons.package, size: 32.sp, color: scheme.textMuted),
                  )
                : Icon(AppIcons.package, size: 32.sp, color: scheme.textMuted),
          ),
        ),
        Gap.w20,
        // Product Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                scanData.productName,
                style: context.title.copyWith(fontSize: 20.sp, fontWeight: FontWeight.w600, height: 1.2, letterSpacing: -0.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                scanData.brand,
                style: context.body.copyWith(color: scheme.textSecondary, fontSize: 15.sp, fontWeight: FontWeight.w500),
              ),
              Gap.h12,
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 2.h),
                    width: 12.sp,
                    height: 12.sp,
                    decoration: BoxDecoration(color: scanData.impactColor, shape: BoxShape.circle),
                  ),
                  Gap.w12,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${scanData.score}/100',
                        style: context.title.copyWith(fontSize: 19.sp, fontWeight: FontWeight.w700, height: 1.0),
                      ),
                      Text(
                        band.label,
                        style: context.body.copyWith(color: scheme.textMuted, fontSize: 15.sp, fontWeight: FontWeight.w500, height: 1.3),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFactorSection(BuildContext context, {required String title, String? subtitle, required List<_HealthFactor> factors}) {
    if (factors.isEmpty) return const SizedBox.shrink();

    final scheme = context.appColorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              title,
              style: context.title.copyWith(fontSize: 20.sp, fontWeight: FontWeight.w900),
            ),
            const Spacer(),
            if (subtitle != null) Text(subtitle, style: context.caption.copyWith(color: scheme.textMuted)),
          ],
        ),
        Gap.h12,
        ...factors.map((factor) => _FactorRow(factor: factor)),
      ],
    );
  }

  Widget _buildAnalyzedContent(BuildContext context) {
    final scheme = context.appColorScheme;
    final result = _analyzedResult!;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: scheme.lavender,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.salad, color: scheme.info, size: 16.sp),
              Gap.w10,
              Text(
                'HEALTH INTELLIGENCE',
                style: context.captionBold.copyWith(color: scheme.info, fontSize: 10.sp, letterSpacing: 1.2, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          Gap.h12,
          Text(
            result.impact,
            style: context.body.copyWith(fontWeight: FontWeight.w600, fontSize: 15.sp, height: 1.4, color: scheme.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    final notifier = context.watch<ScannerNotifier>();
    final isAnalyzed = _analyzedResult != null;

    if (isAnalyzed) {
      return GutButton(
        label: AppStrings.viewFullReportButton,
        onTap: () {
          final result = _analyzedResult!;
          Navigator.of(context).pop(result);
        },
      );
    }

    return GutButton(
      label: AppStrings.getPersonalizedInsightsLabel,
      isLoading: notifier.isAnalyzing,
      onTap: () async {
        final result = await notifier.analyzeBarcodeProduct(widget.product, capturedImage: widget.capturedImage);
        if (!context.mounted) return;
        if (result != null) {
          Navigator.of(context).pop(result);
        } else {
          // Previously silent: the button just stopped spinning. Say why.
          final message = notifier.lastErrorWasOffline ? AppStrings.offlineMessage : AppStrings.failedToAnalyzeProduct;
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
          }
        }
      },
    );
  }

  List<_HealthFactor> _getNegatives(BuildContext context) {
    final isAnalyzed = _analyzedResult != null;
    final items = <_HealthFactor>[];
    final n = widget.product.nutrients;
    final scheme = context.appColorScheme;
    final breakdown = widget.product.yukaBreakdown;
    final pts = breakdown.nutriScorePoints;

    // 1. Processing (NOVA 3/4)
    final nova = widget.product.novaGroup;
    if (nova != null && nova >= 3) {
      items.add(
        _HealthFactor(
          label: 'Processing',
          value: 'NOVA $nova',
          description: nova == 4 ? 'Ultra-processed food' : 'Processed food',
          color: nova == 4 ? scheme.error : scheme.warning,
          icon: AppIcons.package,
          isPositive: false,
        ),
      );
    }

    // 2. Saturated Fat (High)
    final pSatFat = pts['saturatedFat'] ?? 0;
    final valSatFat = n?.saturatedFat;
    if (pSatFat > 0 && valSatFat != null) {
      items.add(
        _HealthFactor(
          label: 'Saturated fat',
          value: '${valSatFat.toStringAsFixed(1)}g',
          description: pSatFat >= 5 ? 'High in saturated fat' : 'Significant saturated fat',
          color: pSatFat >= 5 ? scheme.error : scheme.warning,
          icon: AppIcons.droplet,
          isPositive: false,
          points: pSatFat,
        ),
      );
    }

    // 3. Sugar (High)
    final pSugar = pts['sugar'] ?? 0;
    final valSugar = n?.sugars;
    if (pSugar > 0 && valSugar != null) {
      items.add(
        _HealthFactor(
          label: 'Sugar',
          value: '${valSugar.toInt()}g',
          description: pSugar >= 5 ? 'Too much sugar' : 'High in sugar',
          color: pSugar >= 5 ? scheme.error : scheme.warning,
          icon: LucideIcons.box,
          isPositive: false,
          points: pSugar,
        ),
      );
    }

    // 4. Calories (High)
    final pEnergy = pts['energy'] ?? 0;
    final valCal = n?.calories;
    if (pEnergy > 0 && valCal != null) {
      items.add(
        _HealthFactor(
          label: 'Calories',
          value: '${valCal.toInt()} kcal',
          description: pEnergy >= 5 ? 'Very caloric' : 'High calorie density',
          color: pEnergy >= 5 ? scheme.error : scheme.warning,
          icon: AppIcons.flame,
          isPositive: false,
          points: pEnergy,
        ),
      );
    }

    // 5. Sodium (Salt)
    final pSodium = pts['sodium'] ?? 0;
    final valSalt = n?.salt;
    if (pSodium > 0 && valSalt != null) {
      items.add(
        _HealthFactor(
          label: 'Sodium',
          value: '${(valSalt * 400).toInt()}mg',
          description: pSodium >= 5 ? 'Too salty' : 'Significant sodium',
          color: pSodium >= 5 ? scheme.error : scheme.warning,
          icon: AppIcons.scale,
          isPositive: false,
          points: pSodium,
        ),
      );
    }

    // 6. Palm Oil (ingredient analysis)
    if (widget.product.ingredientAnalysisPalmOilFree == 'no') {
      items.add(_HealthFactor(label: 'Palm oil', value: 'Present', description: 'Contains palm oil', color: scheme.warning, icon: LucideIcons.treePalm, isPositive: false));
    }

    // 7. Environmental Footprint (Eco-Score D/E)
    final ecoNeg = widget.product.ecoscore?.toLowerCase();
    if (ecoNeg == 'd' || ecoNeg == 'e') {
      final ecoScore = widget.product.ecoscoreScore;
      items.add(
        _HealthFactor(
          label: 'Environment',
          value: 'Eco ${ecoNeg!.toUpperCase()}',
          description: ecoScore != null ? 'Low Eco-Score ($ecoScore/100)' : 'High environmental impact',
          color: ecoNeg == 'e' ? scheme.error : scheme.warning,
          icon: AppIcons.globe,
          isPositive: false,
        ),
      );
    }

    // 8. Allergens (caution — not a health penalty, but flag it loudly)
    final allergens = widget.product.allergens ?? const <String>[];
    final traces = widget.product.tracesTags ?? const <String>[];
    if (allergens.isNotEmpty || traces.isNotEmpty) {
      items.add(
        _HealthFactor(
          label: 'Allergens',
          value: allergens.isNotEmpty ? '${allergens.length}' : 'May contain',
          description: allergens.isNotEmpty ? 'Contains: ${allergens.take(3).join(', ')}${allergens.length > 3 ? ' +${allergens.length - 3} more' : ''}' : 'May contain: ${traces.take(2).join(', ')}',
          color: scheme.warning,
          icon: AppIcons.alertTriangle,
          details: [...allergens.map((a) => 'Contains: $a'), ...traces.map((t) => 'May contain: $t')],
          detailsArePlain: true,
          isPositive: false,
        ),
      );
    }

    // 9. Intelligence Warnings (if analyzed)
    if (isAnalyzed && _analyzedResult!.impactType == ImpactType.negative) {
      items.add(_HealthFactor(label: 'Caution', value: 'Alert', description: _analyzedResult!.impact, color: scheme.error, icon: AppIcons.alertTriangle, isPositive: false));
    }

    // 10. Risky Additives
    final riskyAdditives = widget.product.additiveConcerns.where((a) => a.level == AdditiveConcernLevel.higher || a.level == AdditiveConcernLevel.moderate).toList();
    if (riskyAdditives.isNotEmpty) {
      final names = riskyAdditives.map((a) => a.code.isNotEmpty ? a.code : a.name).join(', ');
      final hasHigher = riskyAdditives.any((a) => a.level == AdditiveConcernLevel.higher);
      items.add(
        _HealthFactor(
          label: 'Additives',
          value: widget.product.additivesCount?.toString() ?? riskyAdditives.length.toString(),
          description: '${hasHigher ? 'Avoid' : 'Limit'}: $names',
          color: hasHigher ? scheme.error : scheme.warning,
          icon: AppIcons.flaskConical,
          details: widget.product.additives ?? [],
          isPositive: false,
        ),
      );
    }

    return items;
  }

  List<_HealthFactor> _getPositives(BuildContext context) {
    final isAnalyzed = _analyzedResult != null;
    final items = <_HealthFactor>[];
    final n = widget.product.nutrients;
    final scheme = context.appColorScheme;
    final breakdown = widget.product.yukaBreakdown;
    final pts = breakdown.nutriScorePoints;

    // 1. Personalized Insights (if analyzed)
    if (isAnalyzed && _analyzedResult!.impactType == ImpactType.positive) {
      items.add(_HealthFactor(label: 'For You', value: 'Personal', description: _analyzedResult!.impact, color: scheme.info, icon: AppIcons.userCheck, isPositive: true));
    }

    // 2. Calories (Low/Zero)
    final pEnergy = pts['energy'] ?? 10;
    final valCal = n?.calories;
    if (pEnergy <= 1 && valCal != null) {
      items.add(
        _HealthFactor(
          label: 'Calories',
          value: '${valCal.toInt()} kcal',
          description: valCal < 10 ? 'Zero calories' : 'Low calories',
          color: scheme.success,
          icon: AppIcons.flame,
          isPositive: true,
          points: pEnergy,
        ),
      );
    }

    // 3. Saturated Fat (Low/Zero)
    final pSatFat = pts['saturatedFat'] ?? 10;
    final valSatFat = n?.saturatedFat;
    if (pSatFat <= 1 && valSatFat != null) {
      items.add(
        _HealthFactor(
          label: 'Saturated fat',
          value: '${valSatFat.toStringAsFixed(1)}g',
          description: valSatFat == 0 ? 'No saturated fat' : 'Low saturated fat',
          color: scheme.success,
          icon: AppIcons.droplet,
          isPositive: true,
          points: pSatFat,
        ),
      );
    }

    // 4. Sugar (Low/Zero)
    final pSugar = pts['sugar'] ?? 10;
    final valSugar = n?.sugars;
    if (pSugar <= 1 && valSugar != null) {
      items.add(
        _HealthFactor(
          label: 'Sugar',
          value: '${valSugar.toInt()}g',
          description: valSugar == 0 ? 'No sugar' : 'Low sugar',
          color: scheme.success,
          icon: LucideIcons.box,
          isPositive: true,
          points: pSugar,
        ),
      );
    }

    // 5. Nutrients (Fiber, Protein)
    final pFiber = pts['fiber'] ?? 0;
    final valFib = n?.fiber;
    if (pFiber < 0 && valFib != null) {
      items.add(
        _HealthFactor(
          label: 'Fiber',
          value: '${valFib.toStringAsFixed(1)}g',
          description: pFiber <= -3 ? 'High fiber' : 'Source of fiber',
          color: scheme.success,
          icon: AppIcons.wheat,
          isPositive: true,
          points: pFiber,
        ),
      );
    }

    final pProt = pts['protein'] ?? 0;
    final valProt = n?.proteins;
    if (pProt < 0 && valProt != null) {
      items.add(
        _HealthFactor(
          label: 'Protein',
          value: '${valProt.toInt()}g',
          description: pProt <= -3 ? 'Excellent amount of protein' : 'Good source of protein',
          color: scheme.success,
          icon: AppIcons.dumbbell,
          isPositive: true,
          points: pProt,
        ),
      );
    }

    // 6. Salt (Low/Zero) — symmetry with the negatives side
    final pSodiumPos = pts['sodium'] ?? 10;
    final valSaltPos = n?.salt;
    if (pSodiumPos <= 1 && valSaltPos != null) {
      items.add(
        _HealthFactor(
          label: 'Salt',
          value: '${valSaltPos.toStringAsFixed(1)}g',
          description: valSaltPos < 0.1 ? 'Almost no salt' : 'Low in salt',
          color: scheme.success,
          icon: AppIcons.scale,
          isPositive: true,
          points: pSodiumPos,
        ),
      );
    }

    // 7. Fat (Low nutrient level)
    final levels = widget.product.nutrientLevels;
    final valFat = n?.fat;
    if (levels != null && levels.fat == 'low' && valFat != null) {
      items.add(_HealthFactor(label: 'Fat', value: '${valFat.toStringAsFixed(1)}g', description: 'Low in fat', color: scheme.success, icon: AppIcons.droplet, isPositive: true));
    }

    // 8. Diet-friendly verdicts (OFF ingredient analysis)
    if (widget.product.ingredientAnalysisVegan == 'yes') {
      items.add(
        _HealthFactor(label: 'Vegan', value: '', description: 'No animal-derived ingredients', color: scheme.success, icon: LucideIcons.sprout, isPositive: true, useTick: true, expandable: false),
      );
    }
    if (widget.product.ingredientAnalysisVegetarian == 'yes') {
      items.add(
        _HealthFactor(label: 'Vegetarian', value: '', description: 'No meat or fish ingredients', color: scheme.success, icon: AppIcons.leaf, isPositive: true, useTick: true, expandable: false),
      );
    }
    if (widget.product.ingredientAnalysisPalmOilFree == 'yes') {
      items.add(
        _HealthFactor(
          label: 'Palm oil free',
          value: '',
          description: 'No palm oil in the ingredient list',
          color: scheme.success,
          icon: LucideIcons.treePalm,
          isPositive: true,
          useTick: true,
          expandable: false,
        ),
      );
    }

    // 9. Environmental Footprint (Eco-Score A/B)
    final ecoPos = widget.product.ecoscore?.toLowerCase();
    if (ecoPos == 'a' || ecoPos == 'b') {
      final ecoScore = widget.product.ecoscoreScore;
      items.add(
        _HealthFactor(
          label: 'Environment',
          value: 'Eco ${ecoPos!.toUpperCase()}',
          description: ecoScore != null ? 'Great Eco-Score ($ecoScore/100)' : 'Low environmental impact',
          color: scheme.success,
          icon: AppIcons.globe,
          isPositive: true,
        ),
      );
    }

    // 10. Organic Bonus
    if (widget.product.isOrganic == true) {
      items.add(_HealthFactor(label: 'Organic', value: '', description: 'Certified organic product', color: scheme.success, icon: AppIcons.leaf, isPositive: true, useTick: true, expandable: false));
    }

    // 11. Processing (NOVA 1/2)
    final nova = widget.product.novaGroup;
    if (nova != null && nova <= 2) {
      items.add(
        _HealthFactor(
          label: 'Processing',
          value: 'NOVA $nova',
          description: nova == 1 ? 'Minimally processed' : 'Culinary ingredient',
          color: scheme.success,
          icon: AppIcons.utensils,
          isPositive: true,
        ),
      );
    }

    // 12. Additives (No Risky ones)
    final riskyAdditives = widget.product.additiveConcerns.where((a) => a.level == AdditiveConcernLevel.higher || a.level == AdditiveConcernLevel.moderate).toList();
    if (riskyAdditives.isEmpty) {
      final totalCount = widget.product.additivesCount ?? 0;
      items.add(
        _HealthFactor(
          label: totalCount == 0 ? 'No additives' : 'Additives',
          value: totalCount == 0 ? '' : totalCount.toString(),
          description: totalCount == 0 ? 'Pure product with no industrial additives' : 'Safe additives only',
          color: scheme.success,
          icon: totalCount == 0 ? AppIcons.shieldCheck : AppIcons.flaskConical,
          details: widget.product.additives ?? [],
          isPositive: true,
          useTick: totalCount == 0,
          expandable: totalCount > 0,
        ),
      );
    }

    return items;
  }
}

class _HealthFactor {
  _HealthFactor({
    required this.label,
    required this.value,
    required this.description,
    required this.color,
    required this.icon,
    this.details = const [],
    this.isPositive = true,
    this.points = 0,
    this.useTick = false,
    this.expandable = true,
    this.detailsArePlain = false,
  });
  final String label;
  final String value;
  final String description;
  final Color color;
  final IconData icon;
  final List<String> details;
  final bool isPositive;
  final int points;
  final bool useTick;
  final bool expandable;

  /// True when [details] are informational lines (allergens, traces) that
  /// must render verbatim — false when they are additive labels to resolve
  /// against the concern database.
  final bool detailsArePlain;

  String get longDescription {
    if (details.isNotEmpty) return '';
    final impact = isPositive ? 'positive' : 'negative';
    final action = isPositive ? 'supports' : 'can disrupt';
    final absPoints = points.abs();
    final pointNote = absPoints > 2 ? ' (Impact: -$absPoints points)' : '';

    // Narrative logic based on label
    switch (label.toLowerCase()) {
      case 'calories':
        return isPositive
            ? 'A low energy density supports metabolic efficiency and helps maintain a healthy weight without overloading the system.'
            : 'Higher calorie density can lead to unwanted weight gain and metabolic stress if not balanced with physical activity.$pointNote';
      case 'saturated fat':
        return isPositive
            ? 'Absence of saturated fats helps maintain low levels of systemic inflammation and supports vascular health.'
            : 'High intake of saturated fats is linked to increased systemic inflammation and can negatively alter gut microbiota diversity.$pointNote';
      case 'sugar':
        return isPositive
            ? 'Zero or low sugar content prevents rapid glucose spikes, supporting stable energy levels and protecting the gut barrier.'
            : 'High sugar intake can trigger rapid insulin spikes and feed non-beneficial gut bacteria, potentially leading to dysbiosis.$pointNote';
      case 'sodium':
        return 'Significant sodium intake can affect blood pressure and may influence the gut-immune axis, potentially increasing inflammatory signals.$pointNote';
      case 'fiber':
        return 'High fiber content is essential for gut motility and acts as a prebiotic, feeding the beneficial bacteria that produce short-chain fatty acids.';
      case 'protein':
        return 'A good source of protein provides the essential amino acids needed for tissue repair and the maintenance of the intestinal lining.';
      case 'processing':
        return isPositive
            ? 'Minimally processed foods retain their natural structure and micronutrients, which are more easily recognized and utilized by your gut.'
            : 'Ultra-processing often strips natural fiber and adds industrial markers that can interfere with normal satiety signals and gut health.';
      case 'organic':
        return 'Certified organic products are produced without synthetic pesticides, reducing the chemical load on your microbiome.';
      case 'palm oil':
        return 'Palm oil is high in saturated fat and its production is a major driver of deforestation. Choosing palm-oil-free products is kinder to your gut and the planet.';
      case 'environment':
        return isPositive
            ? 'This product has one of the best environmental footprints in its category, according to the Open Food Facts Eco-Score.'
            : 'This product has a below-average environmental footprint (Eco-Score), driven by its ingredients, packaging or transport.';
      default:
        return 'This property has a $impact impact on your gut health score. Maintaining optimal levels $action your long-term wellness goals.';
    }
  }
}

class _FactorRow extends StatefulWidget {
  const _FactorRow({required this.factor});
  final _HealthFactor factor;

  @override
  State<_FactorRow> createState() => _FactorRowState();
}

class _FactorRowState extends State<_FactorRow> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final factor = widget.factor;

    return Column(
      children: [
        InkWell(
          onTap: factor.expandable ? () => setState(() => _isExpanded = !_isExpanded) : null,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Row(
              children: [
                Icon(factor.icon, size: 24.sp, color: scheme.textPrimary.withAlpha(200)),
                Gap.w16,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        factor.label,
                        style: context.body.copyWith(fontWeight: FontWeight.w700, color: scheme.textPrimary),
                      ),
                      Text(factor.description, style: context.caption.copyWith(color: scheme.textSecondary)),
                    ],
                  ),
                ),
                if (factor.value.isNotEmpty) Text(factor.value, style: context.captionBold.copyWith(color: scheme.textSecondary)),
                Gap.w12,
                if (factor.useTick)
                  Icon(AppIcons.check, size: 16.sp, color: factor.color)
                else
                  Container(
                    width: 12.sp,
                    height: 12.sp,
                    decoration: BoxDecoration(color: factor.color, shape: BoxShape.circle),
                  ),
                if (factor.expandable) ...[Gap.w8, Icon(_isExpanded ? AppIcons.chevronUp : AppIcons.chevronDown, size: 16.sp, color: scheme.textMuted)],
              ],
            ),
          ),
        ),
        if (_isExpanded)
          Padding(
            padding: EdgeInsets.only(left: 40.w, bottom: 12.h),
            child: factor.details.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: factor.details.map((detail) {
                      final concern = factor.detailsArePlain ? null : AdditiveConcernDb.resolve(detail);
                      final label = factor.detailsArePlain ? detail : concern!.displayTitle;
                      final dotColor = factor.detailsArePlain ? factor.color : _getConcernColor(concern!.level, scheme);
                      return Padding(
                        padding: EdgeInsets.only(bottom: 6.h),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                            ),
                            Gap.w10,
                            Expanded(
                              child: Text(label, style: context.caption.copyWith(color: scheme.textPrimary)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                : Text(factor.longDescription, style: context.caption.copyWith(color: scheme.textSecondary, height: 1.4)),
          ),
      ],
    );
  }

  Color _getConcernColor(AdditiveConcernLevel level, AppColorScheme scheme) {
    switch (level) {
      case AdditiveConcernLevel.higher:
        return scheme.error;
      case AdditiveConcernLevel.moderate:
        return scheme.warning;
      case AdditiveConcernLevel.low:
        return scheme.success;
      case AdditiveConcernLevel.unknown:
        return scheme.textMuted;
    }
  }
}
