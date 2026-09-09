import 'package:equatable/equatable.dart';

/// Server-maintained history totals, read from `counters/totals`.
///
/// Replaces full-collection `.get()` + `.size` counting (which billed one read
/// per document on every dashboard open) with a single 1-doc read. The
/// `counters/totals` doc is maintained by Cloud Functions triggers — see
/// `functions/src/counters.ts`. Clients must never write it (enforced by
/// Firestore rules, same model as `daily_usage`).
class HistoryCounts extends Equatable {
  const HistoryCounts({this.scans = 0, this.meals = 0, this.symptoms = 0, this.foodScoreSum = 0, this.foodScoreCount = 0});

  factory HistoryCounts.fromMap(Map<String, dynamic> map) => HistoryCounts(
    scans: (map['scans'] as num?)?.toInt() ?? 0,
    meals: (map['meals'] as num?)?.toInt() ?? 0,
    symptoms: (map['symptoms'] as num?)?.toInt() ?? 0,
    foodScoreSum: (map['foodScoreSum'] as num?)?.toInt() ?? 0,
    foodScoreCount: (map['foodScoreCount'] as num?)?.toInt() ?? 0,
  );

  static const HistoryCounts zero = HistoryCounts();

  /// Total documents in `scan_history`.
  final int scans;

  /// Total `type == 'meal'` documents in `journal_logs`.
  final int meals;

  /// Total `type == 'symptom'` documents in `journal_logs`.
  final int symptoms;

  /// Sum of engine scores across loggable food scans.
  final int foodScoreSum;

  /// Number of loggable food scans contributing to [foodScoreSum].
  final int foodScoreCount;

  /// Mean engine score across loggable food scans (0 when no data yet).
  int get averageFoodScore => foodScoreCount == 0 ? 0 : (foodScoreSum / foodScoreCount).round();

  HistoryCounts copyWith({int? scans, int? meals, int? symptoms, int? foodScoreSum, int? foodScoreCount}) => HistoryCounts(
    scans: scans ?? this.scans,
    meals: meals ?? this.meals,
    symptoms: symptoms ?? this.symptoms,
    foodScoreSum: foodScoreSum ?? this.foodScoreSum,
    foodScoreCount: foodScoreCount ?? this.foodScoreCount,
  );

  Map<String, dynamic> toMap() => {'scans': scans, 'meals': meals, 'symptoms': symptoms, 'foodScoreSum': foodScoreSum, 'foodScoreCount': foodScoreCount};

  @override
  List<Object?> get props => [scans, meals, symptoms, foodScoreSum, foodScoreCount];
}
