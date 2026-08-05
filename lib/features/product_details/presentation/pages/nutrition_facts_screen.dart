import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/widgets/nutrition_row.dart';

class NutritionFactsScreen extends StatelessWidget {
  const NutritionFactsScreen({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final nutrients = scanData.nutrients;
    final hasData = nutrients != null &&
        (nutrients.calories != null ||
            nutrients.fat != null ||
            nutrients.carbs != null ||
            nutrients.proteins != null);

    return Scaffold(
      appBar: GutAppBar(
        title: AppStrings.nutritionFacts,
        leading: IconButton(
          icon: Icon(AppIcons.chevronLeft, color: context.appColorScheme.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: hasData ? _NutritionList(nutrients: nutrients) : const _NoNutritionData(),
    );
  }
}

class _NoNutritionData extends StatelessWidget {
  const _NoNutritionData();

  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
        padding: EdgeInsets.all(AppSizes.p40),
        child: Text(
          AppStrings.noNutritionData,
          textAlign: TextAlign.center,
          style: context.body.copyWith(color: context.appColorScheme.textMuted),
        ),
      ),
    );
}

class _NutritionList extends StatelessWidget {
  const _NutritionList({required this.nutrients});
  final NutrientData nutrients;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      padding: EdgeInsets.all(AppSizes.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.per100g,
              style: context.bodySm.copyWith(color: context.appColorScheme.textMuted)),
          Gap.h8,
          if (nutrients.calories != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppStrings.calories, style: context.title.copyWith(fontWeight: FontWeight.w800)),
                Text('${nutrients.calories}',
                    style: context.headingMd.copyWith(fontWeight: FontWeight.w900)),
              ],
            ),
          Divider(height: 32, thickness: 1, color: context.appColorScheme.textPrimary),
          Gap.h16,
          if (nutrients.fat != null)
            NutritionRow(
                label: AppStrings.totalFat,
                weight: '${nutrients.fat}${AppStrings.labelGramSuffix}',
                isBold: true),
          if (nutrients.saturatedFat != null)
            NutritionRow(
                label: AppStrings.saturatedFat,
                weight: '${nutrients.saturatedFat}${AppStrings.labelGramSuffix}',
                indent: true),
          if (nutrients.carbs != null)
            NutritionRow(
                label: AppStrings.totalCarbohydrate,
                weight: '${nutrients.carbs}${AppStrings.labelGramSuffix}',
                isBold: true),
          if (nutrients.fiber != null)
            NutritionRow(
                label: AppStrings.fiber,
                weight: '${nutrients.fiber}${AppStrings.labelGramSuffix}',
                indent: true),
          if (nutrients.sugars != null)
            NutritionRow(
                label: AppStrings.sugars,
                weight: '${nutrients.sugars}${AppStrings.labelGramSuffix}',
                indent: true),
          if (nutrients.proteins != null)
            NutritionRow(
                label: AppStrings.protein,
                weight: '${nutrients.proteins}${AppStrings.labelGramSuffix}',
                isBold: true),
          if (nutrients.salt != null)
            NutritionRow(
                label: AppStrings.salt,
                weight: '${nutrients.salt}${AppStrings.labelGramSuffix}',
                isBold: true),
          Divider(height: 32, thickness: 8, color: context.appColorScheme.textPrimary),
          Gap.h32,
        ],
      ),
    );
}
