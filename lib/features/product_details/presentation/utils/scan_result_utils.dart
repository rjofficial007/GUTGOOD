import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:gutgood/core/services/notification_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';

/// Concern level → UI color.
Color additiveConcernColor(BuildContext context, AdditiveConcernLevel level) {
  final scheme = context.appColorScheme;
  switch (level) {
    case AdditiveConcernLevel.low:
      return scheme.success;
    case AdditiveConcernLevel.moderate:
      return AppPalette.orange;
    case AdditiveConcernLevel.higher:
      return scheme.error;
    case AdditiveConcernLevel.unknown:
      return scheme.textMuted;
  }
}

/// AI ingredient colorName → UI color.
Color ingredientSignalColor(BuildContext context, String colorName) {
  final scheme = context.appColorScheme;
  switch (colorName.toLowerCase()) {
    case 'green':
    case 'low':
    case 'positive':
      return scheme.success;
    case 'red':
      return scheme.error;
    case 'orange':
    case 'moderate':
    case 'yellow':
      return AppPalette.orange;
    default:
      return scheme.textMuted;
  }
}

/// Split a free-text allergen summary ('Milk, Soy', 'Contains: gluten') into items.
List<String> parseAllergenItems(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  final text = raw.trim().replaceAll(RegExp(r'^(contains|may contain)\s*:?\s*', caseSensitive: false), '');
  if (RegExp(r'^(none|no\s+allergens?|not\s+detected|n/?a)\b', caseSensitive: false).hasMatch(text)) return const [];
  var parts = text.split(RegExp(r'[,;•\n]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  if (parts.length == 1 && parts.first.contains(RegExp(r'\sand\s', caseSensitive: false))) {
    parts = parts.first.split(RegExp(r'\sand\s', caseSensitive: false)).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }
  return parts;
}

/// Concern rank for sorting additives.
int additiveConcernRank(AdditiveConcernLevel level) {
  switch (level) {
    case AdditiveConcernLevel.higher:
      return 3;
    case AdditiveConcernLevel.moderate:
      return 2;
    case AdditiveConcernLevel.low:
      return 1;
    case AdditiveConcernLevel.unknown:
      return 0;
  }
}

/// Human label for how this scan was captured.
String scanSourceLabel(ScanResult scan) {
  if (scan.barcode != null && scan.barcode!.isNotEmpty) return AppStrings.barcodeSource;
  final s = (scan.source ?? '').toLowerCase();
  if (s.contains('menu')) return AppStrings.menuSource;
  if (s.contains('label')) return AppStrings.labelSource;
  return AppStrings.photoSource;
}

/// Logs a swap to the journal as a snack. Shared by the swaps carousel + swap detail.
Future<void> logSwapToJournal(BuildContext context, ProductSwap swap) async {
  try {
    await sl<HistoryFirestoreService>().logMeal(MealLog(items: [swap.title], notes: swap.subtitle, mealType: 'snack', source: 'swap', createdAt: DateTime.now()));
    unawaited(sl<NotificationService>().scheduleNoMealLoggedReminder());
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.swapLogged(swap.title)), behavior: SnackBarBehavior.floating));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't log this swap — try again."), behavior: SnackBarBehavior.floating));
    }
  }
}
