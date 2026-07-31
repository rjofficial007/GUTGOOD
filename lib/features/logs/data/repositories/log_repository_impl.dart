import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/services/firestore_service.dart';
import 'package:gutgood/features/logs/domain/repositories/log_repository.dart';

class LogRepositoryImpl implements LogRepository {
  final FirestoreService _firestoreService;

  LogRepositoryImpl({required FirestoreService firestoreService}) : _firestoreService = firestoreService;

  @override
  Future<void> logSymptom(SymptomLog log) async {
    await _firestoreService.logSymptom(log);
  }

  @override
  Future<void> logMeal(MealLog log) async {
    await _firestoreService.logMeal(log);
  }

  @override
  Future<List<SymptomLog>> getRecentSymptomLogs(int limit) async {
    return await _firestoreService.getRecentSymptomLogs(limit: limit);
  }

  @override
  Future<List<MealLog>> getRecentMealLogs(int limit) async {
    return await _firestoreService.getRecentMealLogs(limit: limit);
  }
}
