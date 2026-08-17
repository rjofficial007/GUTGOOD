import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/widgets/swap_card.dart';

class SwapItContainer extends StatelessWidget {
  const SwapItContainer({super.key, required this.swaps, required this.onSeeMore});
  final List<ProductSwap> swaps;
  final VoidCallback onSeeMore;

  @override
  Widget build(BuildContext context) => Container(
    margin: EdgeInsets.only(bottom: AppSizes.p16, right: AppSizes.p16),
    padding: EdgeInsets.all(AppSizes.p18),
    decoration: BoxDecoration(color: context.appColorScheme.aiResponseBackground, borderRadius: BorderRadius.circular(AppSizes.r24)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(AppIcons.sparkles, size: 22, color: context.appColorScheme.textPrimary),
            ),
            SizedBox(width: AppSizes.p12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.swapItFeelBetter, style: context.title.copyWith(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text(AppStrings.easySwapsDesc, style: context.bodySm.copyWith(color: context.appColorScheme.textMuted)),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: AppSizes.p24),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: swaps.asMap().entries.map((entry) {
              final idx = entry.key;
              final swap = entry.value;

              var calculatedTag = 'GOOD OPTIONS';
              if (idx == 0) {
                calculatedTag = 'BETTER CHOICE';
              } else if (idx == 1) {
                calculatedTag = 'GOOD FOR YOU';
              }

              return Padding(
                padding: EdgeInsets.only(right: idx == swaps.length - 1 ? 0 : AppSizes.p12),
                child: SwapCard(title: swap.title, subtitle: swap.subtitle, imageKeyword: swap.imageKeyword, imageUrl: swap.imageUrl, tag: calculatedTag, badge: idx == 0 ? '#1 PICK' : swap.badge),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: AppSizes.p20),
        GestureDetector(
          onTap: onSeeMore,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p12),
            decoration: BoxDecoration(color: context.appColorScheme.cardBackground.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(AppSizes.r24)),
            child: Row(
              children: [
                SizedBox(width: AppSizes.p16),
                Expanded(
                  child: Text(AppStrings.seeMoreSwaps, textAlign: TextAlign.center, style: context.bodyBold.copyWith(fontSize: 14)),
                ),
                Icon(AppIcons.chevronRight, size: AppSizes.icon16, color: context.appColorScheme.textPrimary),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
