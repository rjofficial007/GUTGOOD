import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/insights/gut_score_record.dart';
import 'package:gutgood/core/models/journal/meal_log.dart';
import 'package:gutgood/core/models/journal/symptom_log.dart';
import 'package:gutgood/core/models/scans/scan_result.dart';
import 'package:gutgood/core/services/gut_score_calculator_service.dart';

void main() {
  group('GutScoreCalculatorService Tests', () {
    const service = GutScoreCalculatorService();

    test('no scan data does not invent a baseline', () {
      expect(service.calculateAvgScanScore([]), 0);
      expect(service.calculateGutScore(scans: const [], symptoms: const [], meals: const []), 0);
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
        SymptomLog(symptom: 'Bloating', severity: 10, createdAt: DateTime.now()),
        SymptomLog(symptom: 'Pain', severity: 10, createdAt: DateTime.now()),
        SymptomLog(symptom: 'Gas', severity: 10, createdAt: DateTime.now()),
        SymptomLog(symptom: 'Nausea', severity: 10, createdAt: DateTime.now()),
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

    test('severity uses the reported 1–10 scale and positive reactions do not penalize', () {
      final at = DateTime(2026, 10, 6);
      expect(service.calculateSymptomPenalty([SymptomLog(symptom: 'Bloating', severity: 3, createdAt: at)]), 3);
      expect(service.calculateSymptomPenalty([SymptomLog(symptom: 'Bloating', severity: 6, createdAt: at)]), 6);
      expect(service.calculateSymptomPenalty([SymptomLog(symptom: 'Bloating', severity: 10, createdAt: at)]), 9);
      expect(service.calculateSymptomPenalty([SymptomLog(symptom: 'Energetic', createdAt: at)]), 0);
    });

    ScanResult scan(int score, DateTime at, {String category = 'food'}) =>
        ScanResult(productName: 'Oats', brand: 'Brand', score: score, category: category, impactType: ImpactType.neutral, impact: '', createdAt: at);

    test('weekly score, counts and daily trend use the same calendar window', () {
      final monday = DateTime(2026, 10, 5, 10);
      final tuesday = DateTime(2026, 10, 6, 10);
      final record = service.calculateWeeklyRecord(
        uid: 'user',
        asOf: DateTime(2026, 10, 6, 12),
        scans: [
          scan(100, DateTime(2026, 10, 3)),
          scan(60, monday),
          scan(100, monday),
          scan(80, tuesday),
          scan(100, DateTime(2026, 10, 6, 18)),
          scan(100, tuesday, category: 'menu'),
        ],
        meals: [
          MealLog(items: const ['Oats'], createdAt: monday),
          MealLog(items: const ['Old meal'], createdAt: tuesday, occurredAt: DateTime(2026, 10, 3)),
        ],
        symptoms: [SymptomLog(symptom: 'Bloating', severity: 10, createdAt: tuesday)],
      );
      expect(record.dailyScores, [0, 82, 73, 0, 0, 0, 0]);
      expect(record.id, 'weekly_2026_W41');
      expect(record.gutScore, 78);
      expect(record.scansCount, 3);
      expect(record.mealsCount, 1);
      expect(record.symptomsCount, 1);
      expect(record.scoredDayIndices, [1, 2]);
      expect(record.periodFrom.toLocal(), DateTime(2026, 10, 4));
    });

    test('weekly record IDs use Sunday-start week years across New Year', () {
      final newYearRecord = service.calculateWeeklyRecord(uid: 'user', asOf: DateTime(2027, 1, 1), scans: const [], symptoms: const [], meals: const []);
      final nextWeekRecord = service.calculateWeeklyRecord(uid: 'user', asOf: DateTime(2026, 10, 11), scans: const [], symptoms: const [], meals: const []);

      expect(newYearRecord.id, 'weekly_2027_W01');
      expect(newYearRecord.periodFrom, DateTime(2026, 12, 27).toUtc());
      expect(nextWeekRecord.id, 'weekly_2026_W42');
      expect(nextWeekRecord.periodFrom, DateTime(2026, 10, 11).toUtc());
    });

    test('a genuine zero day participates in the weekly mean and recap', () {
      final monday = DateTime(2026, 10, 5, 10);
      final tuesday = DateTime(2026, 10, 6, 10);
      final scans = [scan(1, monday), scan(83, tuesday)];
      final symptoms = [SymptomLog(symptom: 'Pain', severity: 10, createdAt: monday)];
      final record = service.calculateWeeklyRecord(uid: 'user', asOf: tuesday, scans: scans, symptoms: symptoms, meals: const []);
      expect(record.dailyScores, [0, 0, 85, 0, 0, 0, 0]);
      expect(record.gutScore, 43);
      expect(record.hasScore, isTrue);
      expect(record.scoredDayCount, 2);
      final restored = GutScoreRecord.fromMap(record.toMap());
      expect(restored.gutScore, 43);
      expect(restored.scoredDayIndices, [1, 2]);
      final recap = service.calculateWeeklyRecap(recentScans: scans, recentSymptoms: symptoms, recentMeals: const [], weeklyTrend: record.dailyScores, scoredDayIndices: record.scoredDayIndices);
      expect(recap.avgScore, 43);
      expect(recap.scoredDayCount, 2);
      expect(recap.scoreSub, '2 of 7 days scored');
    });

    test('a late symptom report belongs to its occurrence week', () {
      final saturday = DateTime(2026, 10, 3, 18);
      final loggedAt = DateTime(2026, 10, 6, 10);
      final record = service.calculateWeeklyRecord(
        uid: 'user',
        asOf: DateTime(2026, 10, 3, 23, 59, 59),
        recordedThrough: loggedAt,
        scans: [scan(80, saturday)],
        meals: const [],
        symptoms: [SymptomLog(symptom: 'Pain', severity: 10, createdAt: loggedAt, occurredAt: saturday)],
      );
      expect(record.gutScore, 73);
      expect(record.symptomsCount, 1);
      expect(record.scoredDayIndices, [6]);
    });

    test('malformed legacy scores preserve weekday slots', () {
      final record = GutScoreRecord.fromMap(const {
        'dailyScores': [60, 'bad', 80],
        'scoredDayIndices': [2, 1, 0, 2, -1, 99],
      });
      expect(record.dailyScores, [60, 0, 80]);
      expect(record.scoredDayIndices, [0, 2]);
      expect(record.gutScore, 70);
    });

    test('week id and midnight boundaries remain stable across Sunday, year and DST changes', () {
      GutScoreRecord record(DateTime at) => service.calculateWeeklyRecord(uid: 'user', asOf: at, scans: const [], symptoms: const [], meals: const []);
      expect(record(DateTime(2026, 12, 27)).id, record(DateTime(2027, 1, 2, 23)).id);
      expect(record(DateTime(2027, 1, 3)).id, isNot(record(DateTime(2027, 1, 2)).id));
      final dstWeek = record(DateTime(2026, 3, 10));
      expect(dstWeek.periodFrom.toLocal(), DateTime(2026, 3, 8));
      expect(dstWeek.periodTo.toLocal().add(const Duration(microseconds: 1)), DateTime(2026, 3, 15));
    });

    test('calculateWeeklyRecap pluralizes foods and symptoms and labels one meal', () {
      final now = DateTime.now();
      final recap = service.calculateWeeklyRecap(
        recentScans: const [],
        recentSymptoms: [SymptomLog(symptom: 'Bloating', createdAt: now)],
        recentMeals: [
          MealLog(items: const ['Oats'], createdAt: now),
        ],
        weeklyTrend: const [0, 70, 0, 0, 0, 0, 0],
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
      );

      expect(recap.summary, startsWith('You logged 2 foods and 2 symptoms this week.'));
      expect(recap.loggedSub, 'meals');
    });

    test('calculateWeeklyRecap preserves the completed calendar-week window', () {
      final recap = service.calculateWeeklyRecap(
        recentScans: const [],
        recentSymptoms: const [],
        recentMeals: [
          MealLog(items: const ['Oats'], createdAt: DateTime(2026, 9, 28)),
        ],
        weeklyTrend: const [0, 70, 0, 0, 0, 0, 0],
        periodFrom: DateTime(2026, 9, 27),
        periodTo: DateTime(2026, 10, 3, 23, 59, 59),
      );

      expect(recap.periodFrom, DateTime(2026, 9, 27));
      expect(recap.periodTo, DateTime(2026, 10, 3, 23, 59, 59));
      expect(recap.dateRange, 'Sep 27–Oct 3');
    });
  });
}
