import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/symptom_log.dart';

enum HistoryItemType { scan, meal, symptom }

class HistoryItem {
  const HistoryItem({required this.type, required this.time, this.scanData, this.mealLog, this.symptomLog});

  factory HistoryItem.fromScan(ScanResult scan) => HistoryItem(type: HistoryItemType.scan, time: scan.time ?? DateTime.now(), scanData: scan);

  factory HistoryItem.fromMeal(MealLog meal) => HistoryItem(type: HistoryItemType.meal, time: meal.time, mealLog: meal);

  factory HistoryItem.fromSymptom(SymptomLog symptom) => HistoryItem(type: HistoryItemType.symptom, time: symptom.time, symptomLog: symptom);

  final HistoryItemType type;
  final DateTime time;
  final ScanResult? scanData;
  final MealLog? mealLog;
  final SymptomLog? symptomLog;
}
