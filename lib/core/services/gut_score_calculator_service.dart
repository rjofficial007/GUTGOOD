import 'package:gutgood/core/models/insights/ai_insight_details.dart';
import 'package:gutgood/core/models/insights/gut_score_record.dart';
import 'package:gutgood/core/models/journal/food_event_linking.dart';
import 'package:gutgood/core/models/journal/meal_log.dart';
import 'package:gutgood/core/models/journal/symptom_log.dart';
import 'package:gutgood/core/models/scans/scan_result.dart';
import 'package:gutgood/core/utils/insight_values.dart';

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

  static DateTime startOfLocalWeek(DateTime dt) {
    final local = dt.toLocal();
    return DateTime(local.year, local.month, local.day - local.weekday % 7);
  }

  static String _weeklyRecordId(DateTime weekStart) {
    final weekEnd = DateTime(weekStart.year, weekStart.month, weekStart.day + 6);
    final weekYear = weekEnd.year;
    final firstWeekStart = startOfLocalWeek(DateTime(weekYear));
    final weekStartDay = DateTime.utc(weekStart.year, weekStart.month, weekStart.day);
    final firstWeekStartDay = DateTime.utc(firstWeekStart.year, firstWeekStart.month, firstWeekStart.day);
    final weekNumber = weekStartDay.difference(firstWeekStartDay).inDays ~/ 7 + 1;
    return 'weekly_${weekYear}_W${weekNumber.toString().padLeft(2, '0')}';
  }

  /// One Sunday–Saturday definition for every score writer and display.
  GutScoreRecord calculateWeeklyRecord({
    required String uid,
    required List<ScanResult> scans,
    required List<SymptomLog> symptoms,
    required List<MealLog> meals,
    required DateTime asOf,
    DateTime? recordedThrough,
  }) {
    final start = startOfLocalWeek(asOf);
    final logCutoff = recordedThrough ?? asOf;
    bool inWindow(DateTime time) => !time.isBefore(start) && !time.isAfter(asOf);
    final weekScans = scans.where((scan) => scan.isLoggableProduct && inWindow(scan.createdAt)).toList();
    final weekMeals = meals.where((meal) => !meal.createdAt.isAfter(logCutoff) && inWindow(meal.eventTime)).toList();
    final weekSymptoms = symptoms.where((symptom) => !symptom.createdAt.isAfter(logCutoff) && inWindow(symptom.eventTime)).toList();
    final scoredIndices = weekScans.map((scan) => scan.createdAt.toLocal().weekday % 7).toSet().toList()..sort();
    return GutScoreRecord(
      id: _weeklyRecordId(start),
      uid: uid,
      type: 'weekly',
      scansCount: weekScans.length,
      mealsCount: weekMeals.length,
      symptomsCount: weekSymptoms.length,
      dailyScores: calculateWeeklyTrend(scans: weekScans, symptoms: weekSymptoms, meals: weekMeals, endDate: asOf, recordedThrough: logCutoff),
      scoredDayIndices: scoredIndices,
      periodFrom: start.toUtc(),
      periodTo: DateTime(start.year, start.month, start.day + 7).subtract(const Duration(microseconds: 1)).toUtc(),
      createdAt: logCutoff.toUtc(),
    );
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
    final sum = scans.fold<int>(0, (acc, scan) => acc + scan.score.clamp(0, 100));
    return (sum / scans.length).round().clamp(0, 100);
  }

  /// Mean of measured days only. Explicit activity includes genuine zeros;
  /// legacy series without activity infer measured days from positive values.
  int averageOfScoredDays(List<int> dailyScores, {List<int>? scoredDayIndices}) {
    final scored = scoredDayIndices == null ? dailyScores.where((s) => s > 0).toList() : [for (final index in scoredDayIndices) dailyScores[index]];
    if (scored.isEmpty) return 0;
    final sum = scored.fold<int>(0, (a, b) => a + b);
    return (sum / scored.length).round().clamp(0, 100);
  }

  /// Calculates symptom penalty based on severity (0 to 30 points penalty).
  int calculateSymptomPenalty(List<SymptomLog> symptoms) {
    if (symptoms.isEmpty) return 0;
    var totalPenalty = 0;
    for (final symptom in symptoms) {
      if (InsightValues.isPositiveReaction(symptom.symptom)) continue;
      final sev = symptom.severity ?? 1;
      if (sev >= 7) {
        totalPenalty += 9; // Severe symptom
      } else if (sev >= 4) {
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
  List<int> calculateWeeklyTrend({required List<ScanResult> scans, required List<SymptomLog> symptoms, required List<MealLog> meals, required DateTime endDate, DateTime? recordedThrough}) {
    final scores = <int>[];
    final sunday = startOfLocalWeek(endDate);

    for (var i = 0; i < 7; i++) {
      final dayStart = DateTime(sunday.year, sunday.month, sunday.day + i);
      final dayEnd = DateTime(sunday.year, sunday.month, sunday.day + i + 1);

      final dayScans = scans.where((s) {
        final t = s.createdAt.toLocal();
        return s.isLoggableProduct && !t.isAfter(endDate) && !t.isBefore(dayStart) && t.isBefore(dayEnd);
      }).toList();
      final daySymptoms = symptoms.where((s) {
        final t = s.eventTime.toLocal();
        return !s.createdAt.isAfter(recordedThrough ?? endDate) && !t.isAfter(endDate) && !t.isBefore(dayStart) && t.isBefore(dayEnd);
      }).toList();
      final dayMeals = meals.where((m) {
        final t = m.eventTime.toLocal();
        return !m.createdAt.isAfter(recordedThrough ?? endDate) && !t.isAfter(endDate) && !t.isBefore(dayStart) && t.isBefore(dayEnd);
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

  static String _formatDateRange(DateTime from, DateTime to) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final start = from.toLocal();
    final end = to.toLocal();
    if (start.year == end.year && start.month == end.month) {
      return '${months[start.month - 1]} ${start.day}–${end.day}';
    }
    return '${months[start.month - 1]} ${start.day}–${months[end.month - 1]} ${end.day}';
  }

  /// Deterministically generates the complete WeeklyRecap data structure.
  ///
  /// The headline averages measured daily scores; missing days do not produce
  /// a baseline and genuine zero scores remain part of the average.
  WeeklyRecap calculateWeeklyRecap({
    required List<ScanResult> recentScans,
    required List<SymptomLog> recentSymptoms,
    required List<MealLog> recentMeals,
    required List<int> weeklyTrend,
    List<int>? scoredDayIndices,
    DateTime? periodFrom,
    DateTime? periodTo,
  }) {
    // A scan is now also a journal meal. Count the event once in the recap,
    // while retaining standalone legacy scans that have no meal projection.
    final totalLogs = uniqueFoodEventCount(meals: recentMeals, scans: recentScans);
    final totalSymptoms = recentSymptoms.length;

    // Best day = highest real score only. 0 means "no score that day".
    final scoredIndices =
        scoredDayIndices ??
        [
          for (var i = 0; i < weeklyTrend.length; i++)
            if (weeklyTrend[i] > 0) i,
        ];
    var highestScore = -1;
    var bestDayIndex = -1;
    for (final i in scoredIndices) {
      if (weeklyTrend[i] > highestScore) {
        highestScore = weeklyTrend[i];
        bestDayIndex = i;
      }
    }

    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    var bestDayName = '';
    if (bestDayIndex != -1 && bestDayIndex < dayNames.length) {
      bestDayName = dayNames[bestDayIndex];
    }

    final trendAvg = averageOfScoredDays(weeklyTrend, scoredDayIndices: scoredIndices);
    final displayAvg = scoredIndices.isNotEmpty ? trendAvg : 0;

    final scoredDays = scoredIndices.length;
    final scoreSub = scoredDays == 0 ? 'No scored days yet' : '$scoredDays of 7 days scored';

    final foodLabel = totalLogs == 1 ? 'food' : 'foods';
    final symptomLabel = totalSymptoms == 1 ? 'symptom' : 'symptoms';
    final standaloneScans = standaloneScanRecords(meals: recentMeals, scans: recentScans);
    final loggedLabel = totalLogs == 0
        ? 'foods'
        : recentMeals.isNotEmpty && standaloneScans.isNotEmpty
        ? 'meals and scans'
        : standaloneScans.isNotEmpty
        ? (standaloneScans.length == 1 ? 'scan' : 'scans')
        : recentMeals.length == 1
        ? 'meal'
        : 'meals';
    var summary = 'You logged $totalLogs $foodLabel and $totalSymptoms $symptomLabel this week.';
    if (highestScore > 80) {
      summary += ' Great job maintaining a high gut score!';
    } else if (highestScore > 0) {
      summary += ' Keep logging to discover more patterns and improve your score.';
    } else {
      summary += ' Log more foods to see your score!';
    }

    final resolvedPeriodFrom = periodFrom?.toLocal();
    final resolvedPeriodTo = periodTo?.toLocal();
    final dateRange = resolvedPeriodFrom != null && resolvedPeriodTo != null ? _formatDateRange(resolvedPeriodFrom, resolvedPeriodTo) : 'This Week';

    return WeeklyRecap(
      dateRange: dateRange,
      avgScore: displayAvg,
      gutScoreTrend: weeklyTrend,
      scoredDayIndices: scoredIndices,
      summary: summary,
      scoreSub: scoreSub,
      bestDay: bestDayName.isNotEmpty ? bestDayName : null,
      foodsLogged: totalLogs,
      loggedSub: loggedLabel,
      periodFrom: resolvedPeriodFrom,
      periodTo: resolvedPeriodTo,
      highlights: [
        if (totalLogs > 5) const RecapHighlight(icon: 'sparkles', text: 'Great logging consistency!', color: 'green'),
        if (totalSymptoms > 0) const RecapHighlight(icon: 'alertCircle', text: 'Symptom logged. Keep tracking to find triggers.', color: 'purple'),
      ],
    );
  }
}
