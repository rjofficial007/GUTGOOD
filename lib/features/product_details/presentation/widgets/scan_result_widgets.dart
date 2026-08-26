import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/extensions.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class SaveButton extends StatelessWidget {
  const SaveButton({super.key, required this.isSaved, required this.isLoading, required this.onTap});
  final bool isSaved;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: isLoading ? null : onTap,
    child: Container(
      width: 40.0.w,
      height: 40.0.w,
      decoration: BoxDecoration(
        color: context.appColorScheme.elevatedSurface,
        shape: BoxShape.circle,
        border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
      ),
      child: isLoading
          ? Center(
              child: SizedBox(
                width: AppSizes.icon20,
                height: AppSizes.icon20,
                child: CircularProgressIndicator(strokeWidth: 2, color: context.appColorScheme.textPrimary),
              ),
            )
          : Icon(isSaved ? Icons.favorite : Icons.favorite_border, color: isSaved ? context.appColorScheme.error : context.appColorScheme.textPrimary, size: AppSizes.icon20),
    ),
  );
}

class NutritionFactsSection extends StatelessWidget {
  const NutritionFactsSection({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final n = scanData.nutrients;
    if (n == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(color: scheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.activity, size: 18.w, color: scheme.textPrimary),
              Gap.w12,
              Text("NUTRITION FACTS", style: context.bodyBold.copyWith(fontSize: 12.sp, letterSpacing: 0.5, color: scheme.textPrimary)),
              const Spacer(),
              if (scanData.servingSize != null)
                Text(scanData.servingSize!, style: context.caption.copyWith(fontSize: 10.sp, color: scheme.textMuted)),
            ],
          ),
          Gap.h24,
          _NutrientFactRow(label: AppStrings.calories, value: '${n.calories ?? 0}', unit: 'kcal'),
          _NutrientFactRow(label: AppStrings.protein, value: '${n.proteins ?? 0}', unit: 'g'),
          _NutrientFactRow(label: AppStrings.totalFat, value: '${n.fat ?? 0}', unit: 'g'),
          _NutrientFactRow(label: AppStrings.saturatedFat, value: '${n.saturatedFat ?? 0}', unit: 'g'),
          _NutrientFactRow(label: AppStrings.totalCarbohydrate, value: '${n.carbs ?? 0}', unit: 'g'),
          _NutrientFactRow(label: AppStrings.sugars, value: '${n.sugars ?? 0}', unit: 'g'),
          _NutrientFactRow(label: AppStrings.fiber, value: '${n.fiber ?? 0}', unit: 'g', isSuccess: true),
          _NutrientFactRow(label: AppStrings.salt, value: '${n.salt ?? 0}', unit: 'mg', isLast: true),
        ],
      ),
    );
  }
}

class _NutrientFactRow extends StatelessWidget {
  const _NutrientFactRow({required this.label, required this.value, required this.unit, this.isLast = false, this.isSuccess = false});
  final String label;
  final String value;
  final String unit;
  final bool isLast;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: scheme.border.withOpacity(0.3))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: context.bodySm.copyWith(color: scheme.textSecondary)),
          Row(
            children: [
              Text(value, style: context.bodyBold.copyWith(fontSize: 14.sp, color: isSuccess ? AppPalette.green : scheme.textPrimary)),
              Gap.w4,
              Text(unit, style: context.caption.copyWith(color: scheme.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class AdditivesSection extends StatelessWidget {
  const AdditivesSection({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final additives = scanData.additives ?? '';
    final count = additives.split(',').where((e) => e.trim().isNotEmpty).length;
    final scheme = context.appColorScheme;

    var riskColor = scheme.success;
    var riskLabel = 'CLEAN';

    if (count > 0) {
      riskColor = scheme.warning;
      riskLabel = count > 3 ? 'CAUTION' : 'MODERATE';
    }
    if (count > 5 || scanData.novaGroup == '4') {
      riskColor = scheme.error;
      riskLabel = 'AVOID';
    }

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(color: riskColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(color: riskColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(AppIcons.flaskConical, size: 16.w, color: riskColor),
              ),
              Gap.w12,
              Text("ADDITIVES ANALYSIS", style: context.bodyBold.copyWith(fontSize: 12.sp, color: scheme.textPrimary)),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(color: riskColor.withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
                child: Text(riskLabel, style: context.bodyBold.copyWith(fontSize: 8.sp, color: riskColor)),
              ),
            ],
          ),
          Gap.h16,
          Text(
            count > 0 ? 'Contains $count chemical additives' : 'No harmful additives detected',
            style: context.bodySm.copyWith(color: scheme.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class BetterSwapsCarousel extends StatelessWidget {
  const BetterSwapsCarousel({super.key, required this.swaps});
  final List<ProductSwap> swaps;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 110.h,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      itemCount: swaps.length,
      separatorBuilder: (_, __) => Gap.w16,
      itemBuilder: (context, i) => _SwapCard(swap: swaps[i]),
    ),
  );
}

class _SwapCard extends StatelessWidget {
  const _SwapCard({required this.swap});
  final ProductSwap swap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Container(
      width: 260.w,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: scheme.cardBackground,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: scheme.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 50.w,
            height: 70.h,
            decoration: BoxDecoration(
              color: scheme.elevatedSurface, 
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: scheme.border.withOpacity(0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: swap.imageUrl != null && swap.imageUrl!.isNotEmpty 
                  ? CachedNetworkImage(imageUrl: swap.imageUrl!, fit: BoxFit.contain) 
                  : Icon(AppIcons.package, color: scheme.textMuted, size: 24),
            ),
          ),
          Gap.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  swap.title.toUpperCase(),
                  style: context.bodyBold.copyWith(fontSize: 11.sp, color: scheme.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  swap.subtitle,
                  style: context.caption.copyWith(color: scheme.textMuted, fontSize: 10.sp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Gap.h8,
                Row(
                  children: [
                    Icon(AppIcons.trendingUp, size: 10.sp, color: AppPalette.green),
                    Gap.w4,
                    Text(
                      'BETTER CHOICE',
                      style: context.bodyBold.copyWith(color: AppPalette.green, fontSize: 8.sp, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CycleInsightSection extends StatelessWidget {
  const CycleInsightSection({super.key, required this.insight});
  final CycleInsight insight;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(color: scheme.lavender.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(color: AppPalette.purple.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.auto_awesome, size: 16.w, color: AppPalette.purple),
              ),
              Gap.w12,
              Text("CYCLE INSIGHT: ${insight.phase.toUpperCase()}", style: context.bodyBold.copyWith(fontSize: 12.sp, color: scheme.textPrimary)),
            ],
          ),
          Gap.h16,
          Text(insight.description, style: context.bodySm.copyWith(color: scheme.textSecondary, height: 1.4)),
        ],
      ),
    );
  }
}

class ProductMetadataSection extends StatelessWidget {
  const ProductMetadataSection({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final date = DateFormat('MMM dd, yyyy • hh:mm a').format(scanData.createdAt);

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(color: scheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18.w, color: scheme.textMuted),
              Gap.w12,
              Text("PRODUCT INFORMATION", style: context.bodyBold.copyWith(fontSize: 11.sp, color: scheme.textMuted)),
            ],
          ),
          Gap.h24,
          if (scanData.barcode != null) _MetadataRow(label: 'Barcode', value: scanData.barcode!),
          if (scanData.source != null) _MetadataRow(label: 'Source', value: scanData.source!.toUpperCase()),
          _MetadataRow(label: 'Analyzed On', value: date, isLast: true),
        ],
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.label, required this.value, this.isLast = false});
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: context.caption.copyWith(color: scheme.textMuted)),
          Text(
            value,
            style: context.caption.copyWith(color: scheme.textSecondary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
