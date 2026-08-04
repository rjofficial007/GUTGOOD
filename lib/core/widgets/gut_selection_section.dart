import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/selection_option.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/widgets/widgets.dart';

class GutSelectionSection extends StatelessWidget {

  const GutSelectionSection({
    super.key,
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });
  final String title;
  final List<SelectionOption> options;
  final String selectedValue;
  final Function(String) onSelected;

  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: context.caption.copyWith(
            fontWeight: FontWeight.bold, 
            color: context.appColorScheme.textMuted,
          ),
        ),
        Gap.h12,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final isSelected = selectedValue == opt.label;
            return GutChip(
              icon: opt.icon, 
              label: opt.label, 
              isSelected: isSelected, 
              onTap: () => onSelected(opt.label),
            );
          }).toList(),
        ),
      ],
    );
}
