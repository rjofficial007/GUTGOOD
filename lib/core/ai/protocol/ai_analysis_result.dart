import 'package:equatable/equatable.dart';
import 'package:gutgood/core/models/journal/meal_log.dart';
import 'package:gutgood/core/models/journal/symptom_log.dart';
import 'package:gutgood/core/models/scans/menu_scan_result.dart';
import 'package:gutgood/core/models/scans/scan_result.dart';
import 'package:gutgood/core/models/scans/scan_result_details.dart';
import 'package:gutgood/core/utils/model_utils.dart';

/// Represents the unified structured output from an AI analysis turn.
class AiAnalysisResult extends Equatable {
  const AiAnalysisResult({
    required this.text,
    this.intent,
    this.imageMode,
    this.scan,
    this.meal,
    this.symptoms = const [],
    this.swaps = const [],
    this.menu,
    this.metadata = const {},
    this.confidence,
    this.schemaVersion,
    this.verdict,
  });

  factory AiAnalysisResult.fromMap(Map<String, dynamic> map) {
    final swapsList = ModelUtils.parseModelList<ProductSwap>(map['swaps'], ProductSwap.fromMap);
    var scanData = ModelUtils.parseNestedModel<ScanResult>(map['scan'], ScanResult.fromMap);

    // 🚀 Professional Sync: Ensure swaps from the unified data block are attached
    // to the ScanResult so they render correctly in the ScanResultScreen.
    if (scanData != null && swapsList.isNotEmpty && scanData.swaps.isEmpty) {
      scanData = scanData.copyWith(swaps: swapsList);
    }

    final metadata = ModelUtils.parseMap(map['metadata']);

    return AiAnalysisResult(
      text: map['text'] as String? ?? '',
      intent: map['intent'] as String?,
      imageMode: map['image_mode'] as String?,
      scan: scanData,
      meal: ModelUtils.parseNestedModel<MealLog>(map['meal'], MealLog.fromMap),
      symptoms: ModelUtils.parseModelList<SymptomLog>(map['symptoms'], SymptomLog.fromMap),
      swaps: swapsList,
      menu: ModelUtils.parseMap(map['menu']),
      metadata: metadata,
      confidence: (metadata['confidence'] as num?)?.toDouble(),
      schemaVersion: (map['v'] as num?)?.toInt(),
      verdict: map['verdict'] as String?,
    );
  }

  final String text;
  final String? intent;
  final String? imageMode;
  final ScanResult? scan;
  final MealLog? meal;
  final List<SymptomLog> symptoms;
  final List<ProductSwap> swaps;
  final Map<String, dynamic>? menu;
  final Map<String, dynamic> metadata;

  /// Strongly-typed model getter for menu scan results.
  MenuScanResult? get menuResult => menu != null ? MenuScanResult.fromMap(menu!) : null;

  /// AI's self-reported confidence (0.0-1.0) in the extracted scan/meal/
  /// symptom data (as opposed to the conversational `text`). Sourced from
  /// `metadata.confidence` in the [GUTGOOD_DATA] block. `null` means the
  /// model did not report a confidence value (treated as unknown/untrusted
  /// by callers that gate persistence on it).
  final double? confidence;

  /// Envelope version from the data block's `v` field (§F/§17). Null when the
  /// prompt didn't request it (legacy output — assumed current shape).
  final int? schemaVersion;

  /// Content verdict from the data block's `verdict` field (§F). Null when
  /// absent (legacy output — allowed through, unlike explicit `non_food`).
  final String? verdict;

  Map<String, dynamic> toMap() => {
    'text': text,
    'intent': intent,
    'image_mode': imageMode,
    'scan': scan?.toMap(),
    'meal': meal?.toMap(),
    'symptoms': symptoms.map((e) => e.toMap()).toList(),
    'swaps': swaps.map((e) => e.toMap()).toList(),
    'menu': menu,
    'metadata': metadata,
    if (schemaVersion != null) 'v': schemaVersion,
    if (verdict != null) 'verdict': verdict,
  };

  AiAnalysisResult copyWith({
    String? text,
    String? intent,
    String? imageMode,
    ScanResult? scan,
    MealLog? meal,
    bool clearMeal = false,
    List<SymptomLog>? symptoms,
    List<ProductSwap>? swaps,
    Map<String, dynamic>? menu,
    Map<String, dynamic>? metadata,
    double? confidence,
    int? schemaVersion,
    String? verdict,
  }) => AiAnalysisResult(
    text: text ?? this.text,
    intent: intent ?? this.intent,
    imageMode: imageMode ?? this.imageMode,
    scan: scan ?? this.scan,
    meal: clearMeal ? null : (meal ?? this.meal),
    symptoms: symptoms ?? this.symptoms,
    swaps: swaps ?? this.swaps,
    menu: menu ?? this.menu,
    metadata: metadata ?? this.metadata,
    confidence: confidence ?? this.confidence,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    verdict: verdict ?? this.verdict,
  );

  @override
  List<Object?> get props => [text, intent, imageMode, scan, meal, symptoms, swaps, menu, metadata, confidence, schemaVersion, verdict];
}
