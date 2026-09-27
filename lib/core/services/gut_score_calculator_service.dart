import 'package:gutgood/core/models/insights/ai_insight_details.dart';
import 'package:gutgood/core/models/journal/meal_log.dart';
import 'package:gutgood/core/models/journal/symptom_log.dart';
import 'package:gutgood/core/models/scans/scan_result.dart';

/// Pure deterministic service to calculate exact Gut Scores without AI hallucination.
class GutScoreCalculatorService {
  const GutScoreCalculatorService();

  /// Local calendar day key (YYYY-M-D) so bucketing matches what the user sees.
  static String dayKey(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${local.month}-${local.day}';
  }

  /// Local midnight for [dt]'s calendar day.
  static DateTime startOfLocalDay(DateTime dt) {
    final local = dt.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  /// Calculates an exact Gut Score based on scan history, symptom severity, and logging consistency.
  ///
  /// When [scans] is empty the result is **0** — never a fabricated baseline.
  int calculateGutScore({required List<ScanResult> scans, required List<SymptomLog> symptoms, required List<MealLog> meals}) {
    if (scans.isEmpty) return 0;

    final scanAvg = calculateAvgScanScore(scans);
    final penalty = calculateSymptomPenalty(symptoms);
    final bonus = calculateConsistencyBonus(meals: meals, scans: scans);

    final rawScore = scanAvg - penalty + bonus;
    return rawScore.clamp(0, 100);
  }

  /// Calculates the exact average score from scanned food products (0-100).
  ///
  /// Returns 0 when there are no scans — never invent a neutral baseline.
  /// Empty days in [calculateWeeklyTrend] must stay 0 in `dailyScores`.
  int calculateAvgScanScore(List<ScanResult> scans) {
    if (scans.isEmpty) return 0;
    final sum = scans.fold<int>(0, (acc, scan) => acc + scan.score);
    return (sum / scans.length).round().clamp(0, 100);
  }

  /// Mean of **scored** days only (values &gt; 0). Empty / missing days are ignored
  /// so a single real day is not diluted by six zeros, and zeros are never treated
  /// as real scores.
  int averageOfScoredDays(List<int> dailyScores) {
    final scored = dailyScores.where((s) => s > 0).toList();
    if (scored.isEmpty) return 0;
    final sum = scored.fold<int>(0, (a, b) => a + b);
    return (sum / scored.length).round().clamp(0, 100);
  }

  /// True when the period has at least one scan to ground a gut score.
  bool hasScoreData(List<ScanResult> scans) => scans.isNotEmpty;

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
      uniqueDays.add(dayKey(meal.eventTime));
    }
    for (final scan in scans) {
      uniqueDays.add(dayKey(scan.createdAt));
    }
    return (uniqueDays.length * 2).clamp(0, 10);
  }

  /// Generates 7 daily score trends for the weekly recap chart / `dailyScores`.
  ///
  /// Days with no scan data get **0** — we do not invent a baseline. Meals or
  /// symptoms alone do not produce a daily gut score without scans.
  ///
  /// Day windows use the **local** calendar of [endDate] so charts line up with
  /// weekday labels on device. Meals/symptoms bucket by [MealLog.eventTime] /
  /// [SymptomLog.eventTime] (occurredAt when known).
  List<int> calculateWeeklyTrend({required List<ScanResult> scans, required List<SymptomLog> symptoms, required List<MealLog> meals, required DateTime endDate}) {
    final scores = <int>[];
    final endLocal = startOfLocalDay(endDate);

    for (var i = 6; i >= 0; i--) {
      final dayStart = endLocal.subtract(Duration(days: i));
      final dayEnd = dayStart.add(const Duration(days: 1));

      final dayScans = scans.where((s) {
        final t = s.createdAt.toLocal();
        return !t.isBefore(dayStart) && t.isBefore(dayEnd);
      }).toList();
      final daySymptoms = symptoms.where((s) {
        final t = s.eventTime.toLocal();
        return !t.isBefore(dayStart) && t.isBefore(dayEnd);
      }).toList();
      final dayMeals = meals.where((m) {
        final t = m.eventTime.toLocal();
        return !t.isBefore(dayStart) && t.isBefore(dayEnd);
      }).toList();

      // No scan activity that day → no score available → 0 (do not fabricate).
      if (dayScans.isEmpty) {
        scores.add(0);
        continue;
      }

      final score = calculateGutScore(scans: dayScans, symptoms: daySymptoms, meals: dayMeals);
      scores.add(score);
    }
    return scores;
  }

  /// Deterministically generates the complete WeeklyRecap data structure.
  ///
  /// [exactScore] is the period gut score shown as the headline number.
  /// [avgScore] prefers the mean of scored days in [weeklyTrend] when any day
  /// has data, otherwise [exactScore].
  WeeklyRecap calculateWeeklyRecap({
    required List<ScanResult> recentScans,
    required List<SymptomLog> recentSymptoms,
    required List<MealLog> recentMeals,
    required List<int> weeklyTrend,
    required int exactScore,
    DateTime? endDate,
  }) {
    final totalLogs = recentMeals.length + recentScans.length;
    final totalSymptoms = recentSymptoms.length;

    // Best day = highest real score only. 0 means "no score that day".
    var highestScore = 0;
    var bestDayIndex = -1;
    for (var i = 0; i < weeklyTrend.length; i++) {
      if (weeklyTrend[i] > highestScore) {
        highestScore = weeklyTrend[i];
        bestDayIndex = i;
      }
    }

    final anchor = endDate != null ? startOfLocalDay(endDate) : startOfLocalDay(DateTime.now());
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    var bestDayName = '';
    if (bestDayIndex != -1) {
      // index 6 is the end day, 5 is day before, etc.
      final daysAgo = 6 - bestDayIndex;
      final bestDayDate = anchor.subtract(Duration(days: daysAgo));
      bestDayName = dayNames[bestDayDate.weekday - 1];
    }

    final trendAvg = averageOfScoredDays(weeklyTrend);
    final displayAvg = trendAvg > 0 ? trendAvg : exactScore;

    final scoredDays = weeklyTrend.where((s) => s > 0).length;
    final scoreSub = scoredDays == 0 ? 'No scored days yet' : '$scoredDays of 7 days scored';

    var summary = 'You logged $totalLogs foods and $totalSymptoms symptoms this week.';
    if (highestScore > 80) {
      summary += ' Great job maintaining a high gut score!';
    } else if (highestScore > 0) {
      summary += ' Keep logging to discover more patterns and improve your score.';
    } else {
      summary += ' Log more foods to see your score!';
    }

    return WeeklyRecap(
      dateRange: 'This Week',
      avgScore: displayAvg,
      gutScoreTrend: weeklyTrend,
      summary: summary,
      scoreSub: scoreSub,
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
