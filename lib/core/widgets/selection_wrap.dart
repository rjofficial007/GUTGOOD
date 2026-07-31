import 'package:flutter/material.dart';
import 'package:gutgood/core/models/selection_option.dart';
import 'package:gutgood/core/widgets/gut_chip.dart';

class SelectionWrap extends StatelessWidget {
  final List<SelectionOption> options;
  final Set<String> selectedValues;
  final Function(String) onToggle;

  const SelectionWrap({super.key, required this.options, required this.selectedValues, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((opt) {
        final isSelected = selectedValues.contains(opt.label);
        return GutChip(icon: opt.icon, label: opt.label, isSelected: isSelected, onTap: () => onToggle(opt.label));
      }).toList(),
    );
  }
}
