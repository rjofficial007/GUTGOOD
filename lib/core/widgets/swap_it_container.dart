import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/widgets/swap_card.dart';
import 'package:gutgood/core/widgets/widgets.dart';

class SwapItContainer extends StatelessWidget {
  const SwapItContainer({super.key, required this.swaps, required this.onSeeMore});
  final List<ProductSwap> swaps;
  final VoidCallback onSeeMore;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;
    
    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.p24, right: AppSizes.p16),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(4),
          topRight: Radius.circular(AppSizes.r32),
          bottomLeft: Radius.circular(AppSizes.r32),
          bottomRight: Radius.circular(AppSizes.r32),
        ),
        border: Border.all(color: colorScheme.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.textPrimary.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(AppSizes.p20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSizes.p10),
                  decoration: BoxDecoration(
                    color: colorScheme.textPrimary,
                    borderRadius: BorderRadius.circular(AppSizes.r12),
                  ),
                  child: Icon(AppIcons.salad, size: AppSizes.icon32, color: colorScheme.cardBackground),
                ),
                Gap.w16,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.swapItFeelBetter.toUpperCase(),
                        style: context.eyebrow.copyWith(color: colorScheme.textPrimary, fontSize: 10),
                      ),
                      Text(
                        AppStrings.easySwapsDesc,
                        style: context.bodySm.copyWith(color: colorScheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p20),
            child: Divider(color: colorScheme.border.withValues(alpha: 0.3), height: 1),
          ),

          // Swaps Scroll
          Padding(
            padding: EdgeInsets.all(AppSizes.p20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: swaps.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final swap = entry.value;

                  return Padding(
                    padding: EdgeInsets.only(right: idx == swaps.length - 1 ? 0 : AppSizes.p12),
                    child: SwapCard(
                      title: swap.title,
                      subtitle: swap.subtitle,
                      imageKeyword: swap.imageKeyword,
                      imageUrl: swap.imageUrl,
                      tag: idx == 0 ? 'PRIME CHOICE' : 'VALID SWAP',
                      badge: idx == 0 ? 'TOP PICK' : null,
                      width: 140,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Actions
          Padding(
            padding: EdgeInsets.fromLTRB(AppSizes.p20, 0, AppSizes.p20, AppSizes.p20),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onSeeMore,
                borderRadius: BorderRadius.circular(AppSizes.r24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSizes.r24),
                    border: Border.all(color: colorScheme.border, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(AppIcons.refreshCcw, size: 12, color: colorScheme.textPrimary),
                      Gap.w8,
                      Text(
                        AppStrings.seeMoreSwaps.toUpperCase(),
                        style: context.eyebrow.copyWith(
                          color: colorScheme.textPrimary,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
