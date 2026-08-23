import 'package:equatable/equatable.dart';
import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/utils/model_utils.dart';

/// Represents the unified structured output from an AI analysis turn.
class AiAnalysisResult extends Equatable {
  const AiAnalysisResult({
    required this.text,
    this.intent,
    this.scan,
    this.meal,
    this.symptoms = const [],
    this.swaps = const [],
    this.metadata = const {},
  });

  factory AiAnalysisResult.fromMap(Map<String, dynamic> map) {
    return AiAnalysisResult(
      text: map['text'] as String? ?? '',
      intent: map['intent'] as String?,
      scan: ModelUtils.parseNestedModel<ScanResult>(map['scan'], ScanResult.fromMap),
      meal: ModelUtils.parseNestedModel<MealLog>(map['meal'], MealLog.fromMap),
      symptoms: ModelUtils.parseModelList<SymptomLog>(map['symptoms'], SymptomLog.fromMap),
      swaps: ModelUtils.parseModelList<ProductSwap>(map['swaps'], ProductSwap.fromMap),
      metadata: ModelUtils.parseMap(map['metadata']),
    );
  }

  final String text;
  final String? intent;
  final ScanResult? scan;
  final MealLog? meal;
  final List<SymptomLog> symptoms;
  final List<ProductSwap> swaps;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toMap() => {
    'text': text,
    'intent': intent,
    'scan': scan?.toMap(),
    'meal': meal?.toMap(),
    'symptoms': symptoms.map((e) => e.toMap()).toList(),
    'swaps': swaps.map((e) => e.toMap()).toList(),
    'metadata': metadata,
  };

  AiAnalysisResult copyWith({
    String? text,
    String? intent,
    ScanResult? scan,
    MealLog? meal,
    List<SymptomLog>? symptoms,
    List<ProductSwap>? swaps,
    Map<String, dynamic>? metadata,
  }) {
    return AiAnalysisResult(
      text: text ?? this.text,
      intent: intent ?? this.intent,
      scan: scan ?? this.scan,
      meal: meal ?? this.meal,
      symptoms: symptoms ?? this.symptoms,
      swaps: swaps ?? this.swaps,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [text, intent, scan, meal, symptoms, swaps, metadata];
}
