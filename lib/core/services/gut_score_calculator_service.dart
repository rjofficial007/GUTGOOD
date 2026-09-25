import 'package:gutgood/core/models/insights/ai_insight_details.dart';
import 'package:gutgood/core/models/journal/meal_log.dart';
import 'package:gutgood/core/models/journal/symptom_log.dart';
import 'package:gutgood/core/models/scans/scan_result.dart';

/// Pure deterministic service to calculate exact Gut Scores without AI hallucination.
class GutScoreCalculatorService {
  const GutScoreCalculatorService();

  /// Calculates an exact Gut Score based on scan history, symptom severity, and logging consistency.
  int calculateGutScore({required List<ScanResult> scans, required List<SymptomLog> symptoms, required List<MealLog> meals}) {
    final scanAvg = calculateAvgScanScore(scans);
    final penalty = calculateSymptomPenalty(symptoms);
    final bonus = calculateConsistencyBonus(meals: meals, scans: scans);

    final rawScore = scanAvg - penalty + bonus;
    return rawScore.clamp(0, 100);
  }

  /// Calculates the exact average score from scanned food products (0-100).
  int calculateAvgScanScore(List<ScanResult> scans) {
    if (scans.isEmpty) return 70; // Neutral baseline when no scans exist
    final sum = scans.fold<int>(0, (acc, scan) => acc + scan.score);
    return (sum / scans.length).round().clamp(0, 100);
  }

  /// Calculates symptom penalty based on severity (0 to 30 points penalty).
  int calculateSymptomPenalty(List<SymptomLog> symptoms) {
    if (symptoms.isEmpty) return 0;
    var totalPenalty = 0;
    for (final symptom in symptoms) {
      final sev = symptom.severity ?? 1;
      if (sev >= 3) {
        totalPenalty += 9; // Severe symptom
      } else if (sev == 2) {
        totalPenalty += 6; // Moderate symptom
      } else {
        totalPenalty += 3; // Mild symptom
      }
    }
    return totalPenalty.clamp(0, 30);
  }

  /// Calculates logging consistency bonus based on unique days logged (0 to 10 points bonus).
  int calculateConsistencyBonus({required List<MealLog> meals, required List<ScanResult> scans}) {
    final uniqueDays = <String>{};
    for (final meal in meals) {
      final dt = meal.eventTime;
      uniqueDays.add('${dt.year}-${dt.month}-${dt.day}');
    }
    for (final scan in scans) {
      final dt = scan.createdAt;
      uniqueDays.add('${dt.year}-${dt.month}-${dt.day}');
    }
    return (uniqueDays.length * 2).clamp(0, 10);
  }

  /// Generates 7 daily score trends for the weekly recap chart.
  List<int> calculateWeeklyTrend({required List<ScanResult> scans, required List<SymptomLog> symptoms, required List<MealLog> meals, required DateTime endDate}) {
    final scores = <int>[];
    for (var i = 6; i >= 0; i--) {
      final dayStart = DateTime(endDate.year, endDate.month, endDate.day).subtract(Duration(days: i));
      final dayEnd = dayStart.add(const Duration(days: 1));

      final dayScans = scans.where((s) => s.createdAt.isAfter(dayStart) && s.createdAt.isBefore(dayEnd)).toList();
      final daySymptoms = symptoms.where((s) => s.createdAt.isAfter(dayStart) && s.createdAt.isBefore(dayEnd)).toList();
      final dayMeals = meals.where((m) => m.createdAt.isAfter(dayStart) && m.createdAt.isBefore(dayEnd)).toList();

      final score = calculateGutScore(scans: dayScans, symptoms: daySymptoms, meals: dayMeals);
      scores.add(score);
    }
    return scores;
  }

  /// Deterministically generates the complete WeeklyRecap data structure.
  WeeklyRecap calculateWeeklyRecap({
    required List<ScanResult> recentScans,
    required List<SymptomLog> recentSymptoms,
    required List<MealLog> recentMeals,
    required List<int> weeklyTrend,
    required int exactScore,
  }) {
    final totalLogs = recentMeals.length + recentScans.length;
    final totalSymptoms = recentSymptoms.length;

    // Find the best day based on the highest score in the trend
    int highestScore = -1;
    int bestDayIndex = -1;
    for (int i = 0; i < weeklyTrend.length; i++) {
      if (weeklyTrend[i] > highestScore) {
        highestScore = weeklyTrend[i];
        bestDayIndex = i;
      }
    }

    final now = DateTime.now();
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    String bestDayName = '';
    if (bestDayIndex != -1) {
      // index 6 is today, 5 is yesterday, etc.
      final daysAgo = 6 - bestDayIndex;
      final bestDayDate = now.subtract(Duration(days: daysAgo));
      bestDayName = dayNames[bestDayDate.weekday - 1];
    }

    String summary = 'You logged $totalLogs foods and $totalSymptoms symptoms this week.';
    if (highestScore > 80) {
      summary += ' Great job maintaining a high gut score!';
    } else if (highestScore > 0) {
      summary += ' Keep logging to discover more patterns and improve your score.';
    } else {
      summary += ' Log more foods to see your score!';
    }

    return WeeklyRecap(
      dateRange: 'This Week',
      avgScore: exactScore,
      gutScoreTrend: weeklyTrend,
      summary: summary,
      bestDay: bestDayName.isNotEmpty ? bestDayName : null,
      foodsLogged: totalLogs,
      loggedSub: 'meals and scans',
      highlights: [
        if (totalLogs > 5)
          const RecapHighlight(
            icon: 'sparkles',
            text: 'Great logging consistency!',
            color: 'green',
          ),
        if (totalSymptoms > 0)
          const RecapHighlight(
            icon: 'alertCircle',
            text: 'Symptom logged. Keep tracking to find triggers.',
            color: 'purple',
          ),
      ],
    );
  }
}

