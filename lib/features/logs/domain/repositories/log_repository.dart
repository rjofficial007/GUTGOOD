import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/symptom_log.dart';

abstract class LogRepository {
  Future<void> logSymptom(SymptomLog log);
  Future<void> logMeal(MealLog log);
  Future<List<SymptomLog>> getRecentSymptomLogs(int limit);
  Future<List<MealLog>> getRecentMealLogs(int limit);
}
