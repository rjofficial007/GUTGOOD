import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/off_product.dart';
import 'package:gutgood/core/models/route_arguments.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_button.dart';
import 'package:gutgood/features/product_details/presentation/widgets/scan_result_widgets.dart';
import 'package:gutgood/features/scanner/presentation/providers/scanner_notifier.dart';
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
    final impactType = score >= 70 ? ImpactType.positive : (score >= 40 ? ImpactType.neutral : ImpactType.negative);

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
                  // 1. Bento Image & Score Card Hero Header
                  BentoImageCard(scanData: _headerScanData),

                  Gap.h16,

                  // 2. Intelligence Result
                  if (isAnalyzed) ...[_buildAnalyzedContent(context), Gap.h16],

                  // 3. Nutri-Score & NOVA Badges
                  _buildGroundTruthBadges(context),
                  Gap.h20,

                  // 4. Negatives Section
                  _buildFactorSection(context, title: AppStrings.negativesLabel, factors: _getNegatives(context)),

                  Gap.h20,

                  // 5. Positives Section
                  _buildFactorSection(context, title: AppStrings.positivesLabel, factors: _getPositives(context)),

                  Gap.h20,

                  // 6. Ingredients Section (Wrapped Bento Chips)
                  _buildIngredientsChips(context),

                  Gap.h24,

                  // 7. Action CTA Button
                  _buildActionButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFactorSection(BuildContext context, {required String title, required List<_HealthFactor> factors}) {
    if (factors.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.title.copyWith(fontSize: 18.sp, fontWeight: FontWeight.w900),
        ),
        Gap.h12,
        ...factors.asMap().entries.map((entry) {
          final isLast = entry.key == factors.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 8.h),
            child: _FactorRow(factor: entry.value),
          );
        }),
      ],
    );
  }

  Widget _buildIngredientsChips(BuildContext context) {
    final ingredients = widget.product.ingredients;
    if (ingredients == null || ingredients.isEmpty) return const SizedBox.shrink();

    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.ingredientsLabelText,
          style: context.title.copyWith(fontSize: 18.sp, fontWeight: FontWeight.w900),
        ),
        Gap.h12,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ingredients
              .take(10)
              .map(
                (ing) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppPalette.white.withAlpha(12) : scheme.elevatedSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(AppIcons.leaf, size: 12.sp, color: scheme.textMuted),
                      Gap.w6,
                      Text(
                        ing,
                        style: context.captionBold.copyWith(color: scheme.textPrimary, fontSize: 11.sp),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildGroundTruthBadges(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final nutriColor = _getNutriScoreColor(widget.product.nutriscore ?? '');
    final novaColor = _getNovaColor(widget.product.novaGroup ?? 0);

    return Row(
      children: [
        if (widget.product.nutriscore != null)
          Expanded(
            child: BentoCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: 16,
              backgroundColor: isDark ? AppPalette.darkCard : scheme.cardBackground,
              borderColor: nutriColor.withAlpha(50),
              child: Row(
                children: [
                  Container(
                    width: 36.h,
                    height: 36.h,
                    decoration: BoxDecoration(color: nutriColor.withAlpha(30), borderRadius: BorderRadius.circular(10)),
                    child: Center(
                      child: Text(
                        widget.product.nutriscore!.toUpperCase(),
                        style: context.headingSm.copyWith(color: nutriColor, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  Gap.w12,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NUTRI-SCORE',
                        style: context.captionMicro.copyWith(color: scheme.textMuted, fontWeight: FontWeight.w900, fontSize: 8.sp),
                      ),
                      const SizedBox(height: 2),
                      Text('Grade ${widget.product.nutriscore!.toUpperCase()}', style: context.captionBold.copyWith(color: scheme.textPrimary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        if (widget.product.nutriscore != null && widget.product.novaGroup != null) Gap.w12,
        if (widget.product.novaGroup != null)
          Expanded(
            child: BentoCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: 16,
              backgroundColor: isDark ? AppPalette.darkCard : scheme.cardBackground,
              borderColor: novaColor.withAlpha(50),
              child: Row(
                children: [
                  Container(
                    width: 36.h,
                    height: 36.h,
                    decoration: BoxDecoration(color: novaColor.withAlpha(30), borderRadius: BorderRadius.circular(10)),
                    child: Center(
                      child: Text(
                        '${widget.product.novaGroup}',
                        style: context.headingSm.copyWith(color: novaColor, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  Gap.w12,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NOVA GROUP',
                        style: context.captionMicro.copyWith(color: scheme.textMuted, fontWeight: FontWeight.w900, fontSize: 8.sp),
                      ),
                      const SizedBox(height: 2),
                      Text('Group ${widget.product.novaGroup}', style: context.captionBold.copyWith(color: scheme.textPrimary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAnalyzedContent(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = _analyzedResult!;

    return BentoCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      backgroundColor: isDark ? scheme.success.withAlpha(20) : scheme.successSubtle,
      borderColor: scheme.success.withAlpha(50),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(AppIcons.sparkles, color: scheme.success, size: 18),
              Gap.w10,
              Text(
                AppStrings.gutgoodHealthIntelligence,
                style: context.eyebrow.copyWith(color: scheme.success, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          Gap.h10,
          Text(
            result.impact,
            textAlign: TextAlign.center,
            style: context.body.copyWith(fontWeight: FontWeight.w600, height: 1.3),
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

          context
            ..pop()
            ..go(result.detailRoute, extra: ScanResultArgs(scanData: result));
        },
      );
    }

    return GutButton(
      label: AppStrings.getPersonalizedInsightsLabel,
      isLoading: notifier.isAnalyzing,
      onTap: () async {
        final result = await notifier.analyzeBarcodeProduct(widget.product, capturedImage: widget.capturedImage);
        if (result != null && mounted) {
          setState(() => _analyzedResult = result);
        }
      },
    );
  }

  List<_HealthFactor> _getNegatives(BuildContext context) {
    final items = <_HealthFactor>[];
    final n = widget.product.nutrients;
    final scheme = context.appColorScheme;

    final additivesCount = widget.product.additivesCount ?? 0;
    if (additivesCount > 0) {
      items.add(
        _HealthFactor(
          label: 'Additives',
          value: additivesCount.toString(),
          description: additivesCount > 3 ? 'Contains additives to avoid' : 'Few additives detected',
          color: additivesCount > 3 ? scheme.error : scheme.warning,
          icon: AppIcons.flaskConical,
        ),
      );
    }

    final salt = n?.salt;
    if (salt != null && salt > 0.3) {
      items.add(
        _HealthFactor(
          label: 'Sodium',
          value: '${(salt * 400).toInt()}mg',
          description: salt > 1.5 ? 'Too salty' : 'A bit salty',
          color: salt > 1.5 ? scheme.error : scheme.warning,
          icon: AppIcons.scale,
        ),
      );
    }

    final cal = n?.calories;
    if (cal != null && cal > 160) {
      items.add(
        _HealthFactor(
          label: 'Calories',
          value: '${cal.toInt()} Cal',
          description: cal > 360 ? 'Very caloric' : 'A bit too caloric',
          color: cal > 360 ? scheme.error : scheme.warning,
          icon: AppIcons.flame,
        ),
      );
    }

    final sugar = n?.sugars;
    if (sugar != null && sugar > 15) {
      items.add(
        _HealthFactor(
          label: 'Sugar',
          value: '${sugar.toInt()}g',
          description: sugar > 22.5 ? 'Too much sugar' : 'High in sugar',
          color: sugar > 22.5 ? scheme.error : scheme.warning,
          icon: AppIcons.candy,
        ),
      );
    }

    return items;
  }

  List<_HealthFactor> _getPositives(BuildContext context) {
    final items = <_HealthFactor>[];
    final n = widget.product.nutrients;
    final scheme = context.appColorScheme;

    final prot = n?.proteins;
    if (prot != null && prot >= 4) {
      items.add(
        _HealthFactor(label: 'Protein', value: '${prot.toInt()}g', description: prot >= 8 ? 'Excellent amount of protein' : 'Good source of protein', color: scheme.success, icon: AppIcons.dumbbell),
      );
    }

    final fib = n?.fiber;
    if (fib != null && fib >= 1.5) {
      items.add(_HealthFactor(label: 'Fiber', value: '${fib.toStringAsFixed(1)}g', description: fib >= 3 ? 'High fiber' : 'Some fiber', color: scheme.success, icon: AppIcons.wheat));
    }

    final sugar = n?.sugars;
    if (sugar != null && sugar <= 5) {
      items.add(_HealthFactor(label: 'Sugar', value: '${sugar.toInt()}g', description: sugar == 0 ? 'No sugar' : 'Low sugar', color: scheme.success, icon: AppIcons.candy));
    }

    return items;
  }

  Color _getNutriScoreColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
        return AppPalette.nutriGreen;
      case 'B':
        return AppPalette.nutriLightGreen;
      case 'C':
        return AppPalette.nutriYellow;
      case 'D':
        return AppPalette.nutriOrange;
      case 'E':
        return AppPalette.nutriRed;
      default:
        return AppPalette.gray400;
    }
  }

  Color _getNovaColor(int group) {
    switch (group) {
      case 1:
        return AppPalette.nutriGreen;
      case 2:
        return AppPalette.nutriYellow;
      case 3:
        return AppPalette.nutriOrange;
      case 4:
        return AppPalette.nutriRed;
      default:
        return AppPalette.gray400;
    }
  }
}

class _HealthFactor {
  _HealthFactor({required this.label, required this.value, required this.description, required this.color, required this.icon});
  final String label;
  final String value;
  final String description;
  final Color color;
  final IconData icon;
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({required this.factor});
  final _HealthFactor factor;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BentoCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 16,
      backgroundColor: isDark ? AppPalette.darkCard : scheme.cardBackground,
      borderColor: scheme.borderSubtle,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: factor.color.withAlpha(26), shape: BoxShape.circle),
            child: Icon(factor.icon, size: 18.sp, color: factor.color),
          ),
          Gap.w14,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  factor.label,
                  style: context.labelBold.copyWith(color: scheme.textPrimary, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(factor.description, style: context.caption.copyWith(color: scheme.textSecondary, height: 1.2)),
              ],
            ),
          ),
          if (factor.value.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: factor.color.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: factor.color.withAlpha(60), width: 0.8),
              ),
              child: Text(
                factor.value,
                style: context.captionBold.copyWith(color: factor.color, fontWeight: FontWeight.w900, fontSize: 10.sp),
              ),
            ),
        ],
      ),
    );
  }
}
