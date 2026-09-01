import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:gutgood/features/scanner/presentation/providers/scanner_notifier.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class ScanSummarySheet extends StatefulWidget {
  const ScanSummarySheet({super.key, required this.product, this.capturedImage});
  final OffProduct product;
  final Uint8List? capturedImage;

  @override
  State<ScanSummarySheet> createState() => _ScanSummarySheetState();
}

class _ScanSummarySheetState extends State<ScanSummarySheet> {
  ScanResult? _analyzedResult;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isAnalyzed = _analyzedResult != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.26,
      minChildSize: 0.26,
      maxChildSize: 0.9,
      snap: true,
      expand: false,
      builder: (context, scrollController) => DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: const [BoxShadow(color: AppPalette.scrim, blurRadius: 20, offset: Offset(0, -5))],
        ),
        child: Column(
          children: [
            // Drag Handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: scheme.borderSubtle, borderRadius: BorderRadius.circular(2)),
              ),
            ),

            Expanded(
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(AppSizes.p24, 0, AppSizes.p24, MediaQuery.of(context).padding.bottom + AppSizes.p24),
                children: [
                  // 1. Primary Minimal Header
                  _buildMinimalHeader(context),

                  Gap.h16,
                  Divider(color: scheme.border.withAlpha(26)),
                  Gap.h16,

                  // 2. Intelligence Result
                  if (isAnalyzed) ...[_buildAnalyzedContent(context), Gap.h24, Divider(color: scheme.border.withAlpha(26)), Gap.h16],

                  // 3. Secondary Badges
                  _buildGroundTruthBadges(context),
                  Gap.h24,
                  // 3. Negatives Section
                  _buildFactorSection(context, title: AppStrings.negativesLabel, factors: _getNegatives(context)),

                  Gap.h24,

                  // 4. Positives Section
                  _buildFactorSection(context, title: AppStrings.positivesLabel, factors: _getPositives(context)),

                  Gap.h24,

                  // 5. Ingredients Section (New Style)
                  _buildFactorSection(context, title: AppStrings.ingredientsLabelText, factors: _getIngredients(context)),

                  Gap.h24,
                  Divider(color: scheme.border.withAlpha(26)),
                  Gap.h32,

                  // 7. Action Button
                  _buildActionButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalHeader(BuildContext context) {
    final scheme = context.appColorScheme;
    final score = widget.product.gutScore;
    final scoreColor = _getScoreColor(context, score);
    final gradeLabel = _getGradeLabel(score);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70.0.w,
          height: 120.0.w,

          child: widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: widget.product.imageUrl!,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: scheme.elevatedSurface,
                    highlightColor: scheme.border,
                    child: Container(color: AppPalette.white),
                  ),
                  errorWidget: (_, _, _) => Icon(AppIcons.utensils, color: scheme.textMuted, size: 40),
                )
              : Icon(AppIcons.utensils, color: scheme.textMuted, size: 40),
        ),
        Gap.w20,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.productName,
                style: context.headingSm.copyWith(color: scheme.textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Gap.h4,
              Text(widget.product.brand ?? 'Unknown Brand', style: context.bodySm.copyWith(color: scheme.textSecondary)),
              Gap.h16,
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: scoreColor, shape: BoxShape.circle),
                  ),
                  Gap.w12,
                  Text('$score/100', style: context.headingSm.copyWith(fontWeight: FontWeight.w900)),
                  Gap.w12,
                  Text(
                    gradeLabel,
                    style: context.bodySm.copyWith(color: scheme.textMuted, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFactorSection(BuildContext context, {required String title, required List<_HealthFactor> factors}) {
    if (factors.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.title.copyWith(fontSize: 20.sp, fontWeight: FontWeight.w800),
        ),
        Gap.h16,
        ...factors.asMap().entries.map((entry) {
          final isLast = entry.key == factors.length - 1;
          return _FactorRow(factor: entry.value, isLast: isLast);
        }),
      ],
    );
  }

  Widget _buildGroundTruthBadges(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      if (widget.product.nutriscore != null) _FactBadge(label: 'NUTRI-SCORE', value: widget.product.nutriscore!.toUpperCase(), color: _getNutriScoreColor(widget.product.nutriscore!)),
      if (widget.product.novaGroup != null) _FactBadge(label: 'NOVA GROUP', value: 'GROUP ${widget.product.novaGroup}', color: _getNovaColor(widget.product.novaGroup!)),
    ],
  );

  Widget _buildAnalyzedContent(BuildContext context) {
    final scheme = context.appColorScheme;
    final result = _analyzedResult!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.successSubtle,
        borderRadius: BorderRadius.circular(AppSizes.r20),
        border: Border.all(color: scheme.success.withAlpha(26)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(AppIcons.sparkles, color: scheme.success, size: 18),
              Gap.w10,
              Text(AppStrings.gutgoodHealthIntelligence, style: context.eyebrow.copyWith(color: scheme.success)),
            ],
          ),
          Gap.h12,
          Text(
            result.impact,
            textAlign: TextAlign.center,
            style: context.body.copyWith(fontWeight: FontWeight.w600),
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

  List<_HealthFactor> _getIngredients(BuildContext context) {
    final items = <_HealthFactor>[];
    final ingredients = widget.product.ingredients;
    if (ingredients != null && ingredients.isNotEmpty) {
      for (final ing in ingredients.take(8)) {
        items.add(_HealthFactor(label: ing, value: '', description: 'Product ingredient', color: AppPalette.gray400, icon: AppIcons.leaf));
      }
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

  Color _getScoreColor(BuildContext context, int score) {
    if (score >= 70) return context.appColorScheme.success;
    if (score >= 40) return AppPalette.purplePastel;
    return context.appColorScheme.error;
  }

  String _getGradeLabel(int score) {
    if (score >= 90) return AppStrings.excellent;
    if (score >= 70) return AppStrings.great;
    if (score >= 50) return AppStrings.good;
    if (score >= 30) return AppStrings.fair;
    return AppStrings.badLabel;
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
  const _FactorRow({required this.factor, required this.isLast});
  final _HealthFactor factor;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(factor.icon, size: 28, color: context.appColorScheme.textSecondary),
            Gap.w16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(factor.label, style: context.bodyBold),
                  Text(factor.description, style: context.caption),
                ],
              ),
            ),
            if (factor.value.isNotEmpty) Text(factor.value, style: context.caption.copyWith(fontWeight: FontWeight.bold)),
            Gap.w12,
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: factor.color, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
      if (!isLast) Divider(color: context.appColorScheme.border.withAlpha(26), height: 1),
    ],
  );
}

class _FactBadge extends StatelessWidget {
  const _FactBadge({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: context.eyebrow),
      Gap.h6,
      Text(
        value,
        style: context.bodyBold.copyWith(color: color, fontWeight: FontWeight.w900),
      ),
    ],
  );
}
