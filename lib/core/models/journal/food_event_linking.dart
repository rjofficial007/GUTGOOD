import 'package:gutgood/core/models/journal/meal_log.dart';
import 'package:gutgood/core/models/scans/scan_result.dart';

/// Symptoms are associated with the nearest earlier meal only within this
/// window. Keep the value shared by AI-turn persistence and direct Firestore
/// symptom writes so their relation behavior cannot drift.
const journalSymptomMealLinkWindow = Duration(hours: 4);

String? _stableMealJournalId(MealLog meal) {
  final journalId = meal.journalEntryId?.trim();
  if (journalId != null && journalId.isNotEmpty) return journalId;
  final firestoreId = meal.firestoreId?.trim();
  return firestoreId != null && firestoreId.isNotEmpty ? firestoreId : null;
}

/// Returns the stable journal ID of the nearest earlier meal for [symptomTime].
/// Future meals, meals outside the correlation window, and meals without a
/// stable ID are ignored.
String? nearestMealJournalEntryId({required DateTime symptomTime, required Iterable<MealLog> meals}) {
  final candidates = meals.where((meal) {
    final gap = symptomTime.difference(meal.eventTime);
    final journalId = _stableMealJournalId(meal);
    return !gap.isNegative && gap <= journalSymptomMealLinkWindow && journalId != null;
  }).toList()..sort((a, b) => symptomTime.difference(a.eventTime).compareTo(symptomTime.difference(b.eventTime)));
  if (candidates.isEmpty) return null;
  return _stableMealJournalId(candidates.first);
}

/// Returns scan-history records that do not already have a typed meal
/// projection in [meals].
///
/// The scan collection is a source record and the meal collection is the
/// consumed-food projection. Scan-only records count only after explicit
/// confirmation; informational scans remain excluded from personal insights.
List<ScanResult> standaloneScanRecords({required List<MealLog> meals, required List<ScanResult> scans}) =>
    scans.where((scan) => scan.consumed == true && !meals.any((meal) => meal.representsScanId(scan.scanId))).toList();

/// Keeps manually logged meals and only scan-linked meals with explicit
/// consumption confirmation. This also excludes legacy auto-created meals
/// whose scan has no confirmation status.
List<MealLog> confirmedFoodMeals({required List<MealLog> meals, required List<ScanResult> scans}) => meals.where((meal) {
  final scanId = meal.scanId?.trim();
  if (scanId == null || scanId.isEmpty) return true;
  if (meal.consumptionConfirmed == true) return true;
  return scans.any((scan) => scan.consumed == true && meal.representsScanId(scan.scanId));
}).toList();

/// Returns journal meals that are not represented by a scan entry in [scans].
/// This is useful for display counters where scan-derived meals should not be
/// shown as a second food event.
List<MealLog> standaloneMealRecords({required List<MealLog> meals, required List<ScanResult> scans}) => meals.where((meal) => !scans.any((scan) => meal.representsScanId(scan.scanId))).toList();

/// Counts unique consumed-food events across typed meals and scan history.
///
/// Scan-only records are included only after explicit consumption confirmation.
int uniqueFoodEventCount({required List<MealLog> meals, required List<ScanResult> scans}) =>
    confirmedFoodMeals(meals: meals, scans: scans).length + standaloneScanRecords(meals: meals, scans: scans).length;

/// Score projections use confirmed consumption and the meal's occurrence time,
/// leaving the source scan's original createdAt unchanged in Firestore.
List<ScanResult> confirmedFoodScans({required List<MealLog> meals, required List<ScanResult> scans}) {
  // ponytail: linear meal lookup per scan in the 30-day snapshot; index scan
  // references if high journal volumes make this scan-by-meal loop expensive.
  final confirmedMeals = confirmedFoodMeals(meals: meals, scans: scans);
  final results = <ScanResult>[];
  for (final scan in scans) {
    if (!scan.isLoggableProduct || scan.consumed == false) continue;
    final meal = confirmedMeals.where((meal) => meal.representsScanId(scan.scanId)).firstOrNull;
    if (scan.consumed != true && meal == null) continue;
    results.add(scan.copyWith(consumed: true, createdAt: meal?.eventTime ?? scan.createdAt));
  }
  return results;
}
