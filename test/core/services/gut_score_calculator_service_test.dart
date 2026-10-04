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

    test('calculateWeeklyRecap pluralizes foods and symptoms and labels one meal', () {
      final now = DateTime.now();
      final recap = service.calculateWeeklyRecap(
        recentScans: const [],
        recentSymptoms: [SymptomLog(symptom: 'Bloating', createdAt: now)],
        recentMeals: [MealLog(items: const ['Oats'], createdAt: now)],
        weeklyTrend: const [0, 70, 0, 0, 0, 0, 0],
        exactScore: 70,
      );

      expect(recap.summary, startsWith('You logged 1 food and 1 symptom this week.'));
      expect(recap.loggedSub, 'meal');
      expect(recap.scoreSub, '1 of 7 days scored');
    });

    test('calculateWeeklyRecap uses plural labels for multiple records', () {
      final now = DateTime.now();
      final recap = service.calculateWeeklyRecap(
        recentScans: const [],
        recentSymptoms: [
          SymptomLog(symptom: 'Bloating', createdAt: now),
          SymptomLog(symptom: 'Gas', createdAt: now),
        ],
        recentMeals: [
          MealLog(items: const ['Oats'], createdAt: now),
          MealLog(items: const ['Rice'], createdAt: now.add(const Duration(minutes: 1))),
        ],
        weeklyTrend: const [0, 70, 0, 80, 0, 0, 0],
        exactScore: 75,
      );

      expect(recap.summary, startsWith('You logged 2 foods and 2 symptoms this week.'));
      expect(recap.loggedSub, 'meals');
    });

    test('calculateWeeklyRecap preserves the completed calendar-week window', () {
      final recap = service.calculateWeeklyRecap(
        recentScans: const [],
        recentSymptoms: const [],
        recentMeals: [MealLog(items: const ['Oats'], createdAt: DateTime(2026, 9, 28))],
        weeklyTrend: const [0, 70, 0, 0, 0, 0, 0],
        exactScore: 70,
        periodFrom: DateTime(2026, 9, 27),
        periodTo: DateTime(2026, 10, 3, 23, 59, 59),
      );

      expect(recap.periodFrom, DateTime(2026, 9, 27));
      expect(recap.periodTo, DateTime(2026, 10, 3, 23, 59, 59));
      expect(recap.dateRange, 'Sep 27–Oct 3');
    });
  });
}
