import 'package:gutgood/core/ai/protocol/ai_analysis_result.dart';
import 'package:gutgood/core/ai/protocol/ai_constants.dart';

/// Outcome of [AiResponseValidator.validate].
class ValidatedAiResponse {
  const ValidatedAiResponse({required this.result, required this.persistRecords, this.reasons = const []});

  /// The result with insane values sanitized (out-of-range numbers voided).
  /// Always safe to render in chat.
  final AiAnalysisResult result;

  /// Whether the records may be written to scan_history/journal_logs.
  /// False degrades the turn to chat-only: the user still sees everything,
  /// but nothing enters permanent history.
  final bool persistRecords;

  /// Human-readable reasons for blocked persistence / sanitization.
  final List<String> reasons;
}

/// §F/§18 parse boundary: validates a parsed AI turn before anything is
/// persisted. Malformed output degrades to prose/chat-only; it can never
/// crash or corrupt history.
///
/// Transitional semantics (the §F two-call split hasn't happened yet, so the
/// mixed prose+JSON protocol is still the norm):
/// - ABSENT envelope fields (v/verdict/confidence) mean "legacy prompt
///   output" and are allowed through — blocking on absence would nuke all
///   traffic. Only PRESENT-but-insane values gate.
/// - The confidence gate moved here from the chat persister so BOTH paths
///   (chat + scanner) share it; the scanner can explicitly opt into the
///   consumed-scan override because every completed scan is a food event.
class AiResponseValidator {
  AiResponseValidator._();

  static ValidatedAiResponse validate(AiAnalysisResult result, {bool preserveScanRecords = false}) {
    final reasons = <String>[];
    var persistRecords = true;
    void block(String reason) {
      persistRecords = false;
      reasons.add(reason);
    }
    void blockOrRecordScanOverride(String reason) {
      if (preserveScanRecords) {
        reasons.add('$reason; scan persistence override');
      } else {
        block(reason);
      }
    }

    // 1. Envelope version: newer than we understand → chat-only unless the
    // caller is persisting a concrete scan event.
    final v = result.schemaVersion;
    if (v != null && v != AiVersions.schemaVersion) {
      blockOrRecordScanOverride('unsupported envelope v$v (supports v${AiVersions.schemaVersion})');
    }

    // 2. Intent vocab: advisory only. An unknown token is logged but does not
    // block — downstream policy (consumption gate) treats unrecognized
    // intents conservatively already, and the meal items themselves are
    // user-stated facts regardless of the label.
    final intent = result.intent;
    if (intent != null && intent.isNotEmpty && !UserIntent.all.contains(intent)) {
      reasons.add('unknown intent "$intent" (not in UserIntent.all)');
    }

    // 3. Verdict gate: explicit non_food / uncertain blocks records unless
    // the caller is persisting a concrete scan event.
    final verdict = result.verdict;
    if (verdict != null) {
      if (!Verdict.all.contains(verdict)) {
        blockOrRecordScanOverride('unknown verdict "$verdict"');
      } else if (verdict == Verdict.nonFood) {
        blockOrRecordScanOverride('verdict is non_food: analysis stays chat-only, no records');
      } else if (verdict == Verdict.uncertain) {
        blockOrRecordScanOverride('verdict is uncertain: refusing to persist ambiguous extraction');
      }
    }

    // 4. Confidence gate (§F: < 0.6 → chat-only for non-scan records).
    // Null (unreported) passes,
    // preserving legacy-prompt behavior; out-of-range values are treated as
    // unreported rather than trusted.
    final confidence = result.confidence;
    if (confidence != null) {
      if (confidence.isNaN || confidence < 0 || confidence > 1) {
        reasons.add('confidence $confidence out of range 0..1 (treated as unreported)');
      } else if (confidence < AiConfidenceThresholds.minPersistenceConfidence) {
        blockOrRecordScanOverride('low AI confidence ($confidence < ${AiConfidenceThresholds.minPersistenceConfidence})');
      }
    }

    // 5. The model's own persistence hint (schema `metadata.requiresPersistence`).
    if (result.metadata['requiresPersistence'] == false) {
      blockOrRecordScanOverride('model declined persistence (requiresPersistence: false)');
    }

    // 6. Symptom ranges: severity/energyLevel must be 1..10. Out-of-range
    // values are voided (null), never clamped — a confused number is worse
    // than an honest unknown. Non-blocking: the symptom name itself persists.
    var sanitized = result;
    if (result.symptoms.isNotEmpty) {
      var changed = false;
      final symptoms = result.symptoms.map((s) {
        final badSeverity = _outOfRange(s.severity);
        final badEnergy = _outOfRange(s.energyLevel);
        if (!badSeverity && !badEnergy) return s;
        changed = true;
        reasons.add('voided out-of-range ${badSeverity ? 'severity=${s.severity}' : ''}${badSeverity && badEnergy ? ' + ' : ''}${badEnergy ? 'energy=${s.energyLevel}' : ''} on "${s.symptom}"');
        return s.copyWith(clearSeverity: badSeverity, clearEnergyLevel: badEnergy);
      }).toList();
      if (changed) sanitized = result.copyWith(symptoms: symptoms);
    }

    // 7. Per-intent output contracts (J-2/§F): each intent declares which data
    // subsets it may persist. Unknown/null intent (legacy prompts) → no
    // opinion. Two tools, chosen by render-safety: BLOCK keeps the result
    // intact for chat while quarantining history; STRIP erases from both, so
    // it applies only to blocks nothing renders (meal) or embargoed by policy
    // (label/menu symptoms for non-scan turns — mirrors the persister,
    // enforced here so all writers share it).
    final upperIntent = (intent ?? '').toUpperCase();
    if (intent != null && UserIntent.all.contains(intent)) {
      final isLabelMenu = upperIntent.contains('LABEL') || upperIntent.contains('MENU') || upperIntent.contains('INGREDIENT');
      final isGeneral =
          upperIntent == UserIntent.generalChat || upperIntent == UserIntent.generalFoodQuestion || upperIntent == UserIntent.generalWellness || upperIntent == UserIntent.generalImageAnalysis;
      if (isLabelMenu || isGeneral) {
        // Zero-data intents normally block scan/meal blocks. A concrete scan
        // is intentionally preserved because the product treats it as food.
        if (sanitized.meal != null && !preserveScanRecords) {
          sanitized = sanitized.copyWith(clearMeal: true);
          reasons.add('intent $intent is zero-data; meal block dropped (also closes the GENERAL_IMAGE_ANALYSIS consumption-gate hole)');
        }
        if (result.scan != null) {
          blockOrRecordScanOverride('intent $intent is zero-data; scan block stays chat-only');
        }
        if (isLabelMenu && sanitized.symptoms.isNotEmpty && !preserveScanRecords) {
          sanitized = sanitized.copyWith(symptoms: const []);
          reasons.add('label/menu intent: symptom blocks dropped (prose renders, nothing logs)');
        }
      } else if (upperIntent == UserIntent.symptomAnalysis || upperIntent == UserIntent.swapRequest) {
        // Scoped intents: a scan WITHOUT a user photo is invented (photo-
        // derived scans carry userImageUrl and pass — the user supplied the
        // bytes). Meal needs no opinion: the persister's consumption gate
        // already rejects it for these intents.
        final scan = result.scan;
        if (scan != null && (scan.userImageUrl == null || scan.userImageUrl!.isEmpty)) {
          blockOrRecordScanOverride('intent $intent allows no invented scan block (photo-derived scans pass via userImageUrl)');
        }
      }
    }

    return ValidatedAiResponse(result: sanitized, persistRecords: persistRecords, reasons: reasons);
  }

  static bool _outOfRange(int? value) => value != null && (value < 1 || value > 10);
}
