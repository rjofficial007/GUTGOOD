import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/services/firestore_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

abstract class ExportService {
  Future<void> exportHealthData();
}

class ExportServiceImpl implements ExportService {
  final FirestoreService _firestoreService;

  ExportServiceImpl({required FirestoreService firestoreService}) : _firestoreService = firestoreService;

  @override
  Future<void> exportHealthData() async {
    try {
      final meals = await _firestoreService.getRecentMealLogs(limit: 500);
      final symptoms = await _firestoreService.getRecentSymptomLogs(limit: 500);

      final StringBuffer buffer = StringBuffer();
      
      // 1. Meals Header
      buffer.writeln('--- MEAL LOGS ---');
      buffer.writeln('Date,Time,Meal Type,Items,Notes,Source');
      
      for (final meal in meals) {
        final date = DateFormat('yyyy-MM-dd').format(meal.time);
        final time = DateFormat('HH:mm').format(meal.time);
        final items = meal.items.join('; ');
        buffer.writeln('$date,$time,"${meal.mealType ?? ''}","$items","${meal.notes ?? ''}","${meal.source ?? ''}"');
      }

      buffer.writeln('\n');

      // 2. Symptoms Header
      buffer.writeln('--- SYMPTOM LOGS ---');
      buffer.writeln('Date,Time,Symptom,Severity,Energy,Mood,Sleep,Notes,Source');

      for (final symptom in symptoms) {
        final date = DateFormat('yyyy-MM-dd').format(symptom.time);
        final time = DateFormat('HH:mm').format(symptom.time);
        buffer.writeln('$date,$time,"${symptom.symptom}",${symptom.severity ?? ''},${symptom.energyLevel ?? ''},"${symptom.mood ?? ''}","${symptom.sleep ?? ''}","${symptom.notes ?? ''}","${symptom.source ?? ''}"');
      }

      final String csvData = buffer.toString();
      
      await Share.share(
        csvData,
        subject: 'GutGood Health Data Export - ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
      );

      AppLogger.info('ExportService: Health data shared successfully');
    } catch (e, st) {
      AppLogger.error('ExportService: Export failed', error: e, stackTrace: st);
    }
  }
}
