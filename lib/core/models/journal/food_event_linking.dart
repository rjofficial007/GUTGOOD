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
  }).toList()
    ..sort((a, b) => symptomTime.difference(a.eventTime).compareTo(symptomTime.difference(b.eventTime)));
  if (candidates.isEmpty) return null;
  return _stableMealJournalId(candidates.first);
}

/// Returns scan-history records that do not already have a typed meal
/// projection in [meals].
///
/// The scan collection is a source record and the meal collection is the
/// consumed-food projection. New records have both; older records may have
/// only the scan. The insight pipeline uses this boundary to count each food
/// event once while retaining legacy scan-only records.
List<ScanResult> standaloneScanRecords({required List<MealLog> meals, required List<ScanResult> scans}) => scans.where((scan) => !meals.any((meal) => meal.representsScanId(scan.scanId))).toList();

/// Returns journal meals that are not represented by a scan entry in [scans].
/// This is useful for display counters where scan-derived meals should not be
/// shown as a second food event.
List<MealLog> standaloneMealRecords({required List<MealLog> meals, required List<ScanResult> scans}) => meals.where((meal) => !scans.any((scan) => meal.representsScanId(scan.scanId))).toList();

/// Counts unique consumed-food events across typed meals and scan history.
///
/// New scans already have a meal projection, so only scan-only legacy records
/// are added to the meal count.
int uniqueFoodEventCount({required List<MealLog> meals, required List<ScanResult> scans}) => meals.length + standaloneScanRecords(meals: meals, scans: scans).length;
