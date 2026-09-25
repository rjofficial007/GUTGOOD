import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/journal/meal_log.dart';
import 'package:gutgood/core/models/journal/symptom_log.dart';
import 'package:gutgood/core/models/scans/scan_result.dart';
import 'package:gutgood/core/services/gut_score_calculator_service.dart';

void main() {
  group('GutScoreCalculatorService Tests', () {
    const service = GutScoreCalculatorService();

    test('calculateAvgScanScore returns neutral 70 when scans is empty', () {
      expect(service.calculateAvgScanScore([]), 70);
    });

    test('calculateAvgScanScore calculates exact average of scan scores', () {
      final scans = [
        ScanResult(productName: 'P1', brand: 'B', score: 80, impactType: ImpactType.positive, impact: '', createdAt: DateTime.now()),
        ScanResult(productName: 'P2', brand: 'B', score: 60, impactType: ImpactType.neutral, impact: '', createdAt: DateTime.now()),
      ];
      expect(service.calculateAvgScanScore(scans), 70);
    });

    test('calculateSymptomPenalty caps at 30 points', () {
      final symptoms = <SymptomLog>[
        SymptomLog(symptom: 'Bloating', severity: 3, createdAt: DateTime.now()),
        SymptomLog(symptom: 'Pain', severity: 3, createdAt: DateTime.now()),
        SymptomLog(symptom: 'Gas', severity: 3, createdAt: DateTime.now()),
        SymptomLog(symptom: 'Nausea', severity: 3, createdAt: DateTime.now()),
      ];
      expect(service.calculateSymptomPenalty(symptoms), 30);
    });

    test('calculateGutScore combines scan avg, symptom penalty, and consistency bonus', () {
      final now = DateTime.now();
      final scans = [ScanResult(productName: 'P1', brand: 'B', score: 85, impactType: ImpactType.positive, impact: '', createdAt: now)];
      final symptoms = <SymptomLog>[SymptomLog(symptom: 'Bloating', severity: 1, createdAt: now)];
      final meals = [
        MealLog(items: const ['Oats'], createdAt: now),
      ];

      final score = service.calculateGutScore(scans: scans, symptoms: symptoms, meals: meals);
      expect(score, 84);
    });
  });
}
