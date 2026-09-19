import 'package:equatable/equatable.dart';
import 'package:gutgood/core/utils/model_utils.dart';

class PatternOccurrence extends Equatable {
  const PatternOccurrence({
    this.id,
    this.patternId,
    required this.date,
    this.dateLabel,
    this.mealId,
    required this.mealName,
    this.imageUrl,
    this.mealTime,
    this.mealType,
    required this.reaction,
    this.symptomId,
    this.symptomSeverity,
    this.timeAfterMinutes,
    this.timeAfterLabel,
    required this.timeAfter,
    this.notes,
    this.commonFactors = const [],
  });

  factory PatternOccurrence.fromMap(Map<String, dynamic> map) {
    final dateStr = (map['date'] ?? '').toString();
    final timeAfterStr = (map['timeAfter'] ?? map['timeAfterLabel'] ?? '').toString();
    return PatternOccurrence(
      id: map['id']?.toString(),
      patternId: map['patternId']?.toString(),
      date: dateStr,
      dateLabel: map['dateLabel']?.toString() ?? dateStr,
      mealId: map['mealId']?.toString(),
      mealName: (map['mealName'] ?? map['meal'] ?? '').toString(),
      imageUrl: (map['mealImageUrl'] ?? map['imageUrl'])?.toString(),
      mealTime: map['mealTime']?.toString(),
      mealType: map['mealType']?.toString(),
      reaction: (map['reaction'] ?? map['symptom'] ?? '').toString(),
      symptomId: map['symptomId']?.toString(),
      symptomSeverity: map['symptomSeverity']?.toString(),
      timeAfterMinutes: (map['timeAfterMinutes'] as num?)?.toInt(),
      timeAfterLabel: timeAfterStr,
      timeAfter: timeAfterStr,
      notes: map['notes']?.toString(),
      commonFactors: ModelUtils.parseModelList<CommonFactor>(
        map['commonFactors'],
        CommonFactor.fromMap,
      ),
    );
  }

  final String? id;
  final String? patternId;
  final String date;
  final String? dateLabel;
  final String? mealId;
  final String mealName;
  final String? imageUrl;
  final String? mealTime;
  final String? mealType;
  final String reaction;
  final String? symptomId;
  final String? symptomSeverity;
  final int? timeAfterMinutes;
  final String? timeAfterLabel;
  final String timeAfter;
  final String? notes;
  final List<CommonFactor> commonFactors;

  Map<String, dynamic> toMap() => {
        'id': id,
        'patternId': patternId,
        'date': date,
        'dateLabel': dateLabel,
        'mealId': mealId,
        'mealName': mealName,
        'imageUrl': imageUrl,
        'mealTime': mealTime,
        'mealType': mealType,
        'reaction': reaction,
        'symptomId': symptomId,
        'symptomSeverity': symptomSeverity,
        'timeAfterMinutes': timeAfterMinutes,
        'timeAfterLabel': timeAfterLabel,
        'timeAfter': timeAfter,
        'notes': notes,
        'commonFactors': commonFactors.map((e) => e.toMap()).toList(),
      };

  @override
  List<Object?> get props => [
        id,
        patternId,
        date,
        dateLabel,
        mealId,
        mealName,
        imageUrl,
        mealTime,
        mealType,
        reaction,
        symptomId,
        symptomSeverity,
        timeAfterMinutes,
        timeAfterLabel,
        timeAfter,
        notes,
        commonFactors,
      ];
}

class CommonFactor extends Equatable {
  const CommonFactor({required this.label, required this.icon});

  factory CommonFactor.fromMap(Map<String, dynamic> map) => CommonFactor(
        label: (map['label'] ?? map['name'] ?? '').toString(),
        icon: (map['icon'] ?? 'tag').toString(),
      );

  final String label;
  final String icon;

  Map<String, dynamic> toMap() => {'label': label, 'icon': icon};

  @override
  List<Object?> get props => [label, icon];
}
