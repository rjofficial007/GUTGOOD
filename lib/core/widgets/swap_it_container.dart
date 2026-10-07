import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/scans/scan_result_details.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/widgets/widgets.dart';

class SwapItContainer extends StatelessWidget {
  const SwapItContainer({super.key, required this.swaps, this.onSeeMore, this.isEmbedded = false});
  final List<ProductSwap> swaps;
  final VoidCallback? onSeeMore;
  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;

    return Container(
      margin: isEmbedded ? EdgeInsets.zero : EdgeInsets.only(bottom: AppSizes.p24, right: AppSizes.p16),
      decoration: BoxDecoration(
        color: isEmbedded ? AppPalette.transparent : colorScheme.cardBackground,
        borderRadius: isEmbedded
            ? null
            : BorderRadius.only(topLeft: const Radius.circular(4), topRight: Radius.circular(AppSizes.r32), bottomLeft: Radius.circular(AppSizes.r32), bottomRight: Radius.circular(AppSizes.r32)),
        border: isEmbedded ? null : Border.all(color: colorScheme.borderSubtle),
        boxShadow: isEmbedded ? null : [BoxShadow(color: colorScheme.surfaceSubtle, blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: isEmbedded ? EdgeInsets.only(bottom: AppSizes.p16) : EdgeInsets.all(AppSizes.p20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSizes.p10),
                  decoration: BoxDecoration(color: colorScheme.textPrimary, borderRadius: BorderRadius.circular(AppSizes.r12)),
                  child: Icon(AppIcons.salad, size: AppSizes.icon32, color: colorScheme.cardBackground),
                ),
                Gap.w10,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.swapItFeelBetter.toUpperCase(), style: context.eyebrow.copyWith(color: colorScheme.textPrimary)),
                      Text(AppStrings.easySwapsDesc, style: context.label.copyWith(color: colorScheme.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (!isEmbedded)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p20),
              child: Divider(color: colorScheme.borderSubtle, height: 1),
            ),

          // Swaps Scroll
          Padding(
            padding: isEmbedded ? EdgeInsets.symmetric(vertical: AppSizes.p8) : EdgeInsets.all(AppSizes.p20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: swaps.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final swap = entry.value;

                  return Padding(
                    padding: EdgeInsets.only(right: idx == swaps.length - 1 ? 0 : AppSizes.p12),
                    child: InkWell(
                      onTap: () => context.push(AppRoutes.swapDetail, extra: swap),
                      child: SwapCard(title: swap.title, subtitle: swap.subtitle, imageKeyword: swap.imageKeyword, imageUrl: swap.imageUrl, tag: swap.tag, badge: swap.badge, width: 140),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          FooterActionButton(label: AppStrings.seeMoreSwaps, onTap: onSeeMore, isEmbedded: isEmbedded, icon: AppIcons.refreshCcw),
        ],
      ),
    );
  }
}
