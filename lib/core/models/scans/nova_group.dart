import 'package:flutter/material.dart';
import 'package:gutgood/core/theme/app_palette.dart';

/// Represents a NOVA food processing classification group (1 to 4).
enum NovaGroup {
  unprocessed(group: 1, label: 'Unprocessed', description: 'Unprocessed or minimally processed foods', color: AppPalette.green),
  processedCulinary(group: 2, label: 'Processed Culinary', description: 'Processed culinary ingredients', color: AppPalette.green500),
  processed(group: 3, label: 'Processed', description: 'Processed foods', color: AppPalette.orange),
  ultraProcessed(group: 4, label: 'Ultra-Processed', description: 'Ultra-processed food and drink products', color: AppPalette.red);

  const NovaGroup({required this.group, required this.label, required this.description, required this.color});

  final int group;
  final String label;
  final String description;
  final Color color;

  static NovaGroup? fromGroup(dynamic groupVal) {
    final intGroup = int.tryParse(groupVal?.toString() ?? '');
    switch (intGroup) {
      case 1:
        return NovaGroup.unprocessed;
      case 2:
        return NovaGroup.processedCulinary;
      case 3:
        return NovaGroup.processed;
      case 4:
        return NovaGroup.ultraProcessed;
      default:
        return null;
    }
  }
}
