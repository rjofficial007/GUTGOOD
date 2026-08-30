import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';

class IngredientTile extends StatelessWidget {
  const IngredientTile({super.key, required this.ingredient});
  final Ingredient ingredient;

  @override
  Widget build(BuildContext context) {
    final accentColor = _getColor(context, ingredient.colorName);

    return Container(
      height: 140.0.h,
      padding: EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: context.appColorScheme.elevatedSurface,
        borderRadius: BorderRadius.circular(AppSizes.r24),
        border: Border.all(
          color: context.appColorScheme.borderSubtle,
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Stack(
                children: [
                  Container(
                    padding: EdgeInsets.all(AppSizes.p6),
                    decoration: BoxDecoration(
                      color: context.appColorScheme.cardBackground,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentColor.withAlpha(77),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      _getIcon(ingredient.colorName),
                      size: AppSizes.icon14,
                      color: context.appColorScheme.textPrimary,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: AppSizes.p8,
                      height: AppSizes.p8,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.appColorScheme.elevatedSurface,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withAlpha(127),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Text(
            _getLabel(ingredient.colorName).toUpperCase(),
            style: context.captionBold.copyWith(
              color: context.appColorScheme.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Gap.h2,
          Text(
            ingredient.name,
            style: context.labelBold.copyWith(
              color: context.appColorScheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            ingredient.impact,
            style: context.captionBold.copyWith(
              color: context.appColorScheme.textMuted,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getColor(BuildContext context, String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return context.appColorScheme.error;
      case 'orange':
        return context.appColorScheme.warning;
      default:
        return context.appColorScheme.success;
    }
  }

  IconData _getIcon(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return AppIcons.alertTriangle;
      case 'orange':
        return AppIcons.alertCircle;
      default:
        return AppIcons.leaf;
    }
  }

  String _getLabel(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return AppStrings.highRiskLabel;
      case 'orange':
        return AppStrings.moderateLabel;
      default:
        return AppStrings.cleanLabel;
    }
  }
}
