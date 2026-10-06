import 'package:equatable/equatable.dart';
import 'package:gutgood/core/utils/date_time_utils.dart';
import 'package:gutgood/core/utils/insight_values.dart';

/// Represents a deterministically calculated Gut Score record.
/// Stored in Firestore under `user_profiles/{uid}/gut_scores/{scoreId}`.
class GutScoreRecord extends Equatable {
  const GutScoreRecord({
    required this.id,
    required this.uid,
    required this.type,
    required this.scansCount,
    required this.mealsCount,
    required this.symptomsCount,
    this.dailyScores = const [],
    this.scoredDayIndices,
    required this.periodFrom,
    required this.periodTo,
    required this.createdAt,
  });

  factory GutScoreRecord.fromMap(Map<String, dynamic> map, {String? docId}) {
    final rawDaily = map['dailyScores'];
    // Preserve calendar slots when a legacy value is malformed.
    final dailyScores = rawDaily is List ? rawDaily.take(7).map((value) => (InsightValues.integer(value) ?? 0).clamp(0, 100)).toList() : const <int>[];

    return GutScoreRecord(
      id: docId ?? map['id'] ?? '',
      uid: map['uid'] ?? '',
      type: map['type'] ?? 'daily',
      scansCount: InsightValues.integer(map['scansCount']) ?? 0,
      mealsCount: InsightValues.integer(map['mealsCount']) ?? 0,
      symptomsCount: InsightValues.integer(map['symptomsCount']) ?? 0,
      dailyScores: dailyScores,
      scoredDayIndices: map['scoredDayIndices'] is List
          ? ((map['scoredDayIndices'] as List)
                .map(InsightValues.integer)
                .whereType<int>()
                .where((index) => index >= 0 && index < dailyScores.length && rawDaily is List && InsightValues.number(rawDaily[index]) != null)
                .toSet()
                .toList()
              ..sort())
          : null,
      periodFrom: DateTimeUtils.parse(map['periodFrom']),
      periodTo: DateTimeUtils.parse(map['periodTo']),
      createdAt: DateTimeUtils.parse(map['createdAt']),
    );
  }

  final String id;
  final String uid;
  final String type; // 'daily' or 'weekly'
  final int scansCount;
  final int mealsCount;
  final int symptomsCount;
  final List<int> dailyScores;

  /// Explicit activity distinguishes a measured zero from an empty day.
  /// Legacy records infer activity from positive daily scores.
  final List<int>? scoredDayIndices;
  final DateTime periodFrom;
  final DateTime periodTo;
  final DateTime createdAt;

  List<int> get scoredIndices =>
      scoredDayIndices ??
      [
        for (var i = 0; i < dailyScores.length; i++)
          if (dailyScores[i] > 0) i,
      ];
  List<int> get scoredScores => [for (final i in scoredIndices) dailyScores[i]];
  bool get hasScore => scoredIndices.isNotEmpty;
  int get scoredDayCount => scoredIndices.length;

  /// Mean of measured daily scores, including genuine zero scores.
  int get gutScore {
    final scored = scoredScores;
    if (scored.isEmpty) return 0;
    return (scored.fold<int>(0, (a, b) => a + b) / scored.length).round().clamp(0, 100);
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'uid': uid,
    'type': type,
    'scansCount': scansCount,
    'mealsCount': mealsCount,
    'symptomsCount': symptomsCount,
    'dailyScores': dailyScores,
    if (scoredDayIndices != null) 'scoredDayIndices': scoredDayIndices,
    'gutScore': gutScore,
    'hasGutScore': hasScore,
    'periodFrom': DateTimeUtils.toTimestamp(periodFrom),
    'periodTo': DateTimeUtils.toTimestamp(periodTo),
    'createdAt': DateTimeUtils.toTimestamp(createdAt),
  };

  @override
  List<Object?> get props => [id, uid, type, scansCount, mealsCount, symptomsCount, dailyScores, scoredDayIndices, periodFrom, periodTo, createdAt];
}
