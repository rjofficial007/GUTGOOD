import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';

class NutritionRow extends StatelessWidget {
  final String label;
  final String weight;
  final bool isBold;
  final bool indent;

  const NutritionRow({super.key, required this.label, required this.weight, this.isBold = false, this.indent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: AppSizes.p8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.appColorScheme.border)),
      ),
      child: Row(
        children: [
          if (indent) Gap.w16,
          Text(label, style: context.bodySm.copyWith(fontWeight: isBold ? FontWeight.w800 : FontWeight.w500)),
          Spacer(),
          Text(weight, style: context.bodySm.copyWith(fontWeight: isBold ? FontWeight.w800 : FontWeight.w500)),
        ],
      ),
    );
  }
}
