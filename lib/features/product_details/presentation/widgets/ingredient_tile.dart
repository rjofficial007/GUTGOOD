import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';

class IngredientTile extends StatelessWidget {
  final Ingredient ingredient;

  const IngredientTile({super.key, required this.ingredient});

  @override
  Widget build(BuildContext context) {
    final Color accentColor = _getColor(context, ingredient.colorName);

    return Container(
      height: 140.0.h,
      padding: EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: context.appColorScheme.elevatedSurface,
        borderRadius: BorderRadius.circular(AppSizes.r24),
        border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: AppPalette.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
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
                      border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Icon(_getIcon(ingredient.colorName), size: AppSizes.icon14, color: context.appColorScheme.textPrimary),
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
                        border: Border.all(color: context.appColorScheme.elevatedSurface, width: 1.5),
                        boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.5), blurRadius: 4)],
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
            style: context.caption.copyWith(fontWeight: FontWeight.w900, fontSize: AppSizes.s8, letterSpacing: 1.2, color: context.appColorScheme.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Gap.h2,
          Text(
            ingredient.name,
            style: context.bodyBold.copyWith(fontSize: AppSizes.s13, color: context.appColorScheme.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            ingredient.impact,
            style: context.caption.copyWith(fontSize: AppSizes.s9, color: context.appColorScheme.textMuted, fontWeight: FontWeight.bold),
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
        return 'High Risk';
      case 'orange':
        return 'Moderate';
      default:
        return 'Clean Label';
    }
  }
}
