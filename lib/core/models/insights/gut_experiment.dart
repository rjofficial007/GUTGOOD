import 'package:equatable/equatable.dart';
import 'package:gutgood/core/utils/insight_values.dart';

class ExperimentDailyCheckIn extends Equatable {
  const ExperimentDailyCheckIn({
    required this.date,
    required this.adhered,
    this.hadSymptoms = false,
    this.notes,
  });

  factory ExperimentDailyCheckIn.fromMap(Map<String, dynamic> map) => ExperimentDailyCheckIn(
        date: map['date']?.toString() ?? '',
        adhered: map['adhered'] as bool? ?? false,
        hadSymptoms: map['hadSymptoms'] as bool? ?? false,
        notes: map['notes']?.toString(),
      );

  final String date; // YYYY-MM-DD
  final bool adhered;
  final bool hadSymptoms;
  final String? notes;

  Map<String, dynamic> toMap() => {
        'date': date,
        'adhered': adhered,
        'hadSymptoms': hadSymptoms,
        'notes': notes,
      };

  @override
  List<Object?> get props => [date, adhered, hadSymptoms, notes];
}

class GutExperiment extends Equatable {
  const GutExperiment({
    required this.id,
    required this.actionId,
    required this.title,
    required this.hypothesis,
    this.targetDays = 7,
    required this.startDate,
    required this.endDate,
    this.checkIns = const {},
    this.status = 'active', // active, completed, abandoned
    this.triggerFood,
    this.baselineSymptomRate,
    this.completedOutcome,
  });

  factory GutExperiment.fromMap(Map<String, dynamic> map) {
    final rawCheckIns = map['checkIns'];
    final parsedCheckIns = <String, ExperimentDailyCheckIn>{};
    if (rawCheckIns is Map<String, dynamic>) {
      rawCheckIns.forEach((key, val) {
        if (val is Map<String, dynamic>) {
          parsedCheckIns[key] = ExperimentDailyCheckIn.fromMap(val);
        }
      });
    }

    return GutExperiment(
      id: (map['id'] ?? '').toString(),
      actionId: (map['actionId'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      hypothesis: (map['hypothesis'] ?? '').toString(),
      targetDays: InsightValues.integer(map['targetDays']) ?? 7,
      startDate: DateTime.tryParse(map['startDate']?.toString() ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(map['endDate']?.toString() ?? '') ?? DateTime.now().add(const Duration(days: 7)),
      checkIns: parsedCheckIns,
      status: (map['status'] ?? 'active').toString(),
      triggerFood: map['triggerFood']?.toString(),
      baselineSymptomRate: map['baselineSymptomRate']?.toString(),
      completedOutcome: map['completedOutcome']?.toString(),
    );
  }

  final String id;
  final String actionId;
  final String title;
  final String hypothesis;
  final int targetDays;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, ExperimentDailyCheckIn> checkIns;
  final String status;
  final String? triggerFood;
  final String? baselineSymptomRate;
  final String? completedOutcome;

  int get currentDayNumber {
    final diff = DateTime.now().difference(startDate).inDays + 1;
    return diff.clamp(1, targetDays);
  }

  int get completedCheckInsCount => checkIns.length;
  int get adheredCount => checkIns.values.where((c) => c.adhered).length;
  int get symptomFreeCount => checkIns.values.where((c) => !c.hadSymptoms).length;

  bool get isCompleted => status == 'completed' || currentDayNumber >= targetDays && completedCheckInsCount >= targetDays;

  bool isCheckedInToday() {
    final todayKey = _dateKey(DateTime.now());
    return checkIns.containsKey(todayKey);
  }

  ExperimentDailyCheckIn? todayCheckIn() {
    final todayKey = _dateKey(DateTime.now());
    return checkIns[todayKey];
  }

  static String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  GutExperiment copyWith({
    String? id,
    String? actionId,
    String? title,
    String? hypothesis,
    int? targetDays,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, ExperimentDailyCheckIn>? checkIns,
    String? status,
    String? triggerFood,
    String? baselineSymptomRate,
    String? completedOutcome,
  }) => GutExperiment(
        id: id ?? this.id,
        actionId: actionId ?? this.actionId,
        title: title ?? this.title,
        hypothesis: hypothesis ?? this.hypothesis,
        targetDays: targetDays ?? this.targetDays,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        checkIns: checkIns ?? this.checkIns,
        status: status ?? this.status,
        triggerFood: triggerFood ?? this.triggerFood,
        baselineSymptomRate: baselineSymptomRate ?? this.baselineSymptomRate,
        completedOutcome: completedOutcome ?? this.completedOutcome,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'actionId': actionId,
        'title': title,
        'hypothesis': hypothesis,
        'targetDays': targetDays,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'checkIns': checkIns.map((k, v) => MapEntry(k, v.toMap())),
        'status': status,
        'triggerFood': triggerFood,
        'baselineSymptomRate': baselineSymptomRate,
        'completedOutcome': completedOutcome,
      };

  @override
  List<Object?> get props => [
        id,
        actionId,
        title,
        hypothesis,
        targetDays,
        startDate,
        endDate,
        checkIns,
        status,
        triggerFood,
        baselineSymptomRate,
        completedOutcome,
      ];
}
