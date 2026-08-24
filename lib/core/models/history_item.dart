import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/symptom_log.dart';

enum HistoryItemType { scan, meal, symptom }

class HistoryItem {
  const HistoryItem({required this.type, required this.createdAt, this.scanData, this.mealLog, this.symptomLog});

  factory HistoryItem.fromScan(ScanResult scan) => HistoryItem(type: HistoryItemType.scan, createdAt: scan.createdAt, scanData: scan);

  factory HistoryItem.fromMeal(MealLog meal) => HistoryItem(type: HistoryItemType.meal, createdAt: meal.createdAt, mealLog: meal);

  factory HistoryItem.fromSymptom(SymptomLog symptom) => HistoryItem(type: HistoryItemType.symptom, createdAt: symptom.createdAt, symptomLog: symptom);

  final HistoryItemType type;
  final DateTime createdAt;
  final ScanResult? scanData;
  final MealLog? mealLog;
  final SymptomLog? symptomLog;
}
