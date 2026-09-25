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
    required this.gutScore,
    required this.avgScanScore,
    required this.symptomPenalty,
    required this.consistencyBonus,
    required this.scansCount,
    required this.mealsCount,
    required this.symptomsCount,
    this.dailyScores = const [],
    required this.periodFrom,
    required this.periodTo,
    required this.createdAt,
  });

  factory GutScoreRecord.fromMap(Map<String, dynamic> map, {String? docId}) {
    final rawDaily = map['dailyScores'];
    final dailyScores = rawDaily is List ? rawDaily.map(InsightValues.integer).whereType<int>().where((score) => score >= 0 && score <= 100).toList() : const <int>[];

    return GutScoreRecord(
      id: docId ?? map['id'] ?? '',
      uid: map['uid'] ?? '',
      type: map['type'] ?? 'daily',
      gutScore: InsightValues.integer(map['gutScore']) ?? 0,
      avgScanScore: InsightValues.integer(map['avgScanScore']) ?? 0,
      symptomPenalty: InsightValues.integer(map['symptomPenalty']) ?? 0,
      consistencyBonus: InsightValues.integer(map['consistencyBonus']) ?? 0,
      scansCount: InsightValues.integer(map['scansCount']) ?? 0,
      mealsCount: InsightValues.integer(map['mealsCount']) ?? 0,
      symptomsCount: InsightValues.integer(map['symptomsCount']) ?? 0,
      dailyScores: dailyScores,
      periodFrom: DateTimeUtils.parse(map['periodFrom']),
      periodTo: DateTimeUtils.parse(map['periodTo']),
      createdAt: DateTimeUtils.parse(map['createdAt']),
    );
  }

  final String id;
  final String uid;
  final String type; // 'daily' or 'weekly'
  final int gutScore;
  final int avgScanScore;
  final int symptomPenalty;
  final int consistencyBonus;
  final int scansCount;
  final int mealsCount;
  final int symptomsCount;
  final List<int> dailyScores;
  final DateTime periodFrom;
  final DateTime periodTo;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'uid': uid,
    'type': type,
    'gutScore': gutScore,
    'avgScanScore': avgScanScore,
    'symptomPenalty': symptomPenalty,
    'consistencyBonus': consistencyBonus,
    'scansCount': scansCount,
    'mealsCount': mealsCount,
    'symptomsCount': symptomsCount,
    'dailyScores': dailyScores,
    'periodFrom': DateTimeUtils.toTimestamp(periodFrom),
    'periodTo': DateTimeUtils.toTimestamp(periodTo),
    'createdAt': DateTimeUtils.toTimestamp(createdAt),
  };

  @override
  List<Object?> get props => [id, uid, type, gutScore, avgScanScore, symptomPenalty, consistencyBonus, scansCount, mealsCount, symptomsCount, dailyScores, periodFrom, periodTo, createdAt];
}
