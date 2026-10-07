import 'package:gutgood/core/ai/prompts/mode_prompts.dart';
import 'package:gutgood/core/ai/prompts/mode_prompts/full_analysis_prompt.dart';
import 'package:gutgood/core/ai/prompts/mode_prompts/general_rules_prompt.dart';
import 'package:gutgood/core/ai/prompts/mode_prompts/health_assessment_prompt.dart';
import 'package:gutgood/core/ai/prompts/mode_prompts/image_classification_prompt.dart';
import 'package:gutgood/core/ai/prompts/mode_prompts/ingredients_label_prompt.dart';
import 'package:gutgood/core/ai/prompts/mode_prompts/intent_detection_prompt.dart';
import 'package:gutgood/core/ai/prompts/mode_prompts/meal_planning_prompt.dart';
import 'package:gutgood/core/ai/prompts/mode_prompts/meal_rating_prompt.dart';
import 'package:gutgood/core/ai/prompts/mode_prompts/meal_snap_prompt.dart';
import 'package:gutgood/core/ai/prompts/mode_prompts/meal_swaps_prompt.dart';
import 'package:gutgood/core/ai/prompts/mode_prompts/product_analysis_prompt.dart';
import 'package:gutgood/core/ai/prompts/mode_prompts/product_comparison_prompt.dart';
import 'package:gutgood/core/ai/prompts/mode_prompts/restaurant_menu_prompt.dart';
import 'package:gutgood/core/ai/prompts/mode_prompts/summarization_prompt.dart';
import 'package:gutgood/core/ai/prompts/mode_prompts/symptom_analysis_prompt.dart';
import 'package:gutgood/core/ai/prompts/mode_prompts/unknown_vision_prompt.dart';
import 'package:gutgood/core/ai/prompts/schema_definitions.dart';

class Prompts {
  Prompts._();

  // ---------------------------------------------------------------------------
  // SHARED SYSTEM RULES
  // ---------------------------------------------------------------------------

  static String get _identity => GeneralRulesPrompt.identity;
  static String get _visionCapability => GeneralRulesPrompt.visionCapability;
  static String get _corePhilosophy => GeneralRulesPrompt.corePhilosophy;
  static String get _safetyRules => GeneralRulesPrompt.safetyRules;
  static String get _patternEngineRules => GeneralRulesPrompt.patternEngineRules;
  static String get _journalDataRules => GeneralRulesPrompt.journalDataRules;
  static String get _analysisDiscipline => GeneralRulesPrompt.analysisDiscipline;

  // ---------------------------------------------------------------------------
  // IMAGE CLASSIFICATION
  // ---------------------------------------------------------------------------

  /// Instruction for classifying the image mode and user intent.
  static String get imageClassificationInstruction => ImageClassificationPrompt.instruction;

  // ---------------------------------------------------------------------------
  // INTENT DETECTION
  // ---------------------------------------------------------------------------

  /// Instruction for identifying the user's intent from their message.
  static String get intentDetectionInstruction => IntentDetectionPrompt.instruction;

  // ---------------------------------------------------------------------------
  // CHAT SYSTEM INSTRUCTION
  // ---------------------------------------------------------------------------

  /// System instruction for the main GutGood chat assistant, tailored by intent.
  static String chatSystemInstruction({
    required List<String> userGoals,
    required List<String> userSensitivities,
    List<String> userLifestyle = const [],
    String cyclePhase = 'Not specified',
    String communicationStyle = 'Friendly & Supportive',
    String? historySummary,
    String? pinnedEntities,
    String? currentTime,
    String? mode,
    String? intent,
    bool includePatternEngine = true,
    bool includeStructuredSchemas = true,
  }) {
    final goals = _formatList(userGoals, fallback: 'None specified');
    final sensitivities = _formatList(userSensitivities, fallback: 'None specified');
    final lifestyle = _formatList(userLifestyle, fallback: 'None specified');

    final timeContext = currentTime != null ? 'CURRENT TIME: $currentTime\n' : '';

    final summaryText = historySummary != null && historySummary.trim().isNotEmpty
        ? '''
RECENT HISTORY SUMMARY
$historySummary
'''
        : 'No recent history summary is available.';

    // K-4: entity names from turns outside the context window. Rendered in
    // the dynamic (non-cacheable) section alongside the summary.
    final pinsText = pinnedEntities != null && pinnedEntities.trim().isNotEmpty
        ? '''

PINNED ENTITIES (names from earlier in this conversation; no detail)
$pinnedEntities
'''
        : '';

    final intentPrompt = _getPromptForIntent(intent);

    final normalizedIntent = (intent ?? '').toUpperCase();
    final normalizedMode = (mode ?? '').toUpperCase();
    final isLabelOrMenu =
        normalizedMode.contains('LABEL') ||
        normalizedMode.contains('MENU') ||
        normalizedMode.contains('PACKAGED_PRODUCT') ||
        normalizedIntent.contains('LABEL') ||
        normalizedIntent.contains('MENU') ||
        normalizedIntent.contains('INGREDIENT');

    // The schema body is emitted ONCE (see the static block below). It used to
    // be interpolated a second time inside `formatInstruction`, which cost
    // ~790 tokens on every single turn and made the model see the same
    // contract twice.
    final includeSchema = includeStructuredSchemas && !isLabelOrMenu;

    final formatInstruction = isLabelOrMenu
        ? '''
STRICT FORMAT (TOKEN OPTIMIZATION FOR LABELS & MENUS):
Provide ONLY your clean conversational Markdown response.
CRITICAL: Do NOT output a [GUTGOOD_DATA] block or any JSON tags at all.
'''
        : '''
STRICT FORMAT:
[Conversational Response in Markdown]
${includeSchema ? '\nThen emit exactly ONE [GUTGOOD_DATA] block matching the JSON schema defined above.' : '\nEmit no [GUTGOOD_DATA] block for this turn.'}
''';

    // -------------------------------------------------------------------------
    // ORDERING CONTRACT (cost + cacheability) — please don't reshuffle blindly.
    //
    // OpenAI prompt caching only discounts the longest *identical prefix* of a
    // request (minimum ~1024 tokens). Everything above the DYNAMIC CONTEXT
    // marker is byte-identical for a given turn shape, so it is cacheable;
    // everything that varies per user or per request (time, profile, cycle
    // phase, rolling summary) is deliberately placed AFTER it. Injecting
    // dynamic values above this line silently disables caching for the whole
    // ~2.4k-token schema/rules block.
    // -------------------------------------------------------------------------
    return '''
$_identity

$_visionCapability

$_corePhilosophy

$_safetyRules

$_analysisDiscipline

${includeSchema ? '${SchemaDefinitions.unifiedDataSchema}\n${SchemaDefinitions.typeRules}\n$_journalDataRules' : ''}${includePatternEngine ? '\n$_patternEngineRules' : ''}

$formatInstruction

$intentPrompt

=================== DYNAMIC CONTEXT (not cacheable) ===================

COMMUNICATION STYLE
$communicationStyle

Turn Context:
${mode != null ? 'ACTIVE MODE: $mode' : 'ACTIVE MODE: General Chat'}

$timeContext
USER PROFILE

Health Goals:
$goals

Sensitivities & Allergies:
$sensitivities

Lifestyle:
$lifestyle

Current Cycle Phase:
$cyclePhase

$summaryText$pinsText
''';
  }

  static String _getPromptForIntent(String? intent) {
    if (intent == null) return FullAnalysisPrompt.instruction;

    final normalized = intent.toUpperCase().trim();

    // Route strictly to the proper intent-aware prompt
    if (normalized.contains('MEAL_RATING') || normalized.contains('RATE_MEAL')) {
      return MealRatingPrompt.instruction;
    } else if (normalized.contains('HEALTH_ASSESSMENT') || normalized.contains('IS_HEALTHY')) {
      return HealthAssessmentPrompt.instruction;
    } else if (normalized.contains('SWAP_REQUEST') || normalized.contains('MEAL_SWAPS') || normalized.contains('IMPROVEMENT_REQUEST') || normalized.contains('IMPROVE')) {
      return MealSwapsPrompt.instruction;
    } else if (normalized.contains('SYMPTOM_ANALYSIS') || normalized.contains('GENERAL_WELLNESS') || normalized.contains('SYMPTOM') || normalized.contains('FEELING')) {
      return SymptomAnalysisPrompt.instruction;
    } else if (normalized.contains('MEAL_SNAP') || normalized.contains('MEAL_RECOGNITION') || normalized.contains('FOOD_SNAP')) {
      return MealSnapPrompt.instruction;
    } else if (normalized.contains('PRODUCT_COMPARISON') || normalized.contains('NUTRITION_COMPARISON')) {
      return ProductComparisonPrompt.instruction;
    } else if (normalized.contains('MEAL_PLANNING')) {
      return MealPlanningPrompt.instruction;
    } else if (normalized.contains('MENU') || normalized.contains('MENU_RECOMMENDATION')) {
      return RestaurantMenuPrompt.instruction;
    } else if (normalized.contains('LABEL') || normalized.contains('INGREDIENT_ANALYSIS')) {
      return IngredientsLabelPrompt.instruction;
    } else if (normalized.contains('COMPLETE_ANALYSIS') || normalized.contains('FULL_ANALYSIS')) {
      return FullAnalysisPrompt.instruction;
    }

    return FullAnalysisPrompt.instruction;
  }

  // ---------------------------------------------------------------------------
  // VISION ANALYSIS
  // ---------------------------------------------------------------------------

  /// Specialized instruction for one-shot vision scans.
  static String visionAnalysisSystemInstruction({
    required String mode,
    required List<String> userGoals,
    required List<String> userSensitivities,
    List<String> userLifestyle = const [],
    String cyclePhase = 'Not specified',
  }) {
    final normalizedMode = mode.trim().toUpperCase();

    final instruction = switch (normalizedMode) {
      'RESTAURANT_MENU' || 'MENU' => ModePrompts.restaurantMenuInstruction(goals: userGoals, sensitivities: userSensitivities, lifestyle: userLifestyle, phase: cyclePhase),
      'FOOD' || 'MEAL' => ModePrompts.mealSnapInstruction(goals: userGoals, sensitivities: userSensitivities, lifestyle: userLifestyle, phase: cyclePhase),
      'INGREDIENTS_LABEL' || 'LABEL' || 'INGREDIENT' => ModePrompts.ingredientLabelInstruction(goals: userGoals, sensitivities: userSensitivities, lifestyle: userLifestyle, phase: cyclePhase),
      'PRODUCT_BARCODE' || 'BARCODE' => barcodeAnalysisSystemInstruction,
      _ => _unknownVisionModeInstruction(goals: userGoals, sensitivities: userSensitivities, lifestyle: userLifestyle, phase: cyclePhase),
    };

    if (cyclePhase != 'Not specified' && !{'RESTAURANT_MENU', 'MENU', 'INGREDIENTS_LABEL', 'LABEL', 'INGREDIENT'}.contains(normalizedMode)) {
      return '$instruction\n\nREQUIRED: Since the user\'s cycle phase is known ($cyclePhase), you MUST populate the "cycleInsight" object within the "scan" block of the [GUTGOOD_DATA] block.';
    }
    return instruction;
  }

  static String _unknownVisionModeInstruction({required List<String> goals, required List<String> sensitivities, required List<String> lifestyle, required String phase}) =>
      '''
$_identity

$_visionCapability

$_corePhilosophy

$_safetyRules

${UnknownVisionPrompt.instruction}

USER PROFILE
Goals: ${_formatList(goals, fallback: 'None specified')}
Sensitivities: ${_formatList(sensitivities, fallback: 'None specified')}
Lifestyle: ${_formatList(lifestyle, fallback: 'None specified')}
Phase: $phase

SENSITIVITY CHECK
Explicitly check for: ${_formatList(sensitivities, fallback: 'None specified')}.

${SchemaDefinitions.unifiedDataSchema}
${SchemaDefinitions.typeRules}
''';

  // ---------------------------------------------------------------------------
  // BARCODE ANALYSIS
  // ---------------------------------------------------------------------------

  /// System instruction for Open Food Facts barcode analysis.
  static String get barcodeAnalysisSystemInstruction =>
      '''
$_identity

$_corePhilosophy

$_safetyRules

${ModePrompts.barcodeAnalysisInstruction()}
''';

  // ---------------------------------------------------------------------------
  // PRODUCT ANALYSIS
  // ---------------------------------------------------------------------------

  /// User prompt for analyzing product data.
  static String productAnalysisPrompt({
    required dynamic productData,
    required List<String> userGoals,
    required List<String> userSensitivities,
    required List<String> userLifestyle,
    required String cyclePhase,
  }) {
    final goals = _formatList(userGoals, fallback: 'General health');
    final sensitivities = _formatList(userSensitivities, fallback: 'None specified');
    final lifestyle = _formatList(userLifestyle, fallback: 'None specified');

    return '''
${ProductAnalysisPrompt.instruction}

PRODUCT DATA
$productData

USER CONTEXT
Health Goals: $goals
Sensitivities & Allergies: $sensitivities
Lifestyle: $lifestyle
Current Cycle Phase: $cyclePhase
''';
  }

  /// Specialized instruction for history summarization.
  static String summarizationInstruction({String? previousSummary}) {
    final priorContext = previousSummary != null && previousSummary.isNotEmpty ? 'PREVIOUS SUMMARY (fold new info into this, don\'t discard it): $previousSummary\n\n' : '';
    return '$priorContext${SummarizationPrompt.instruction}';
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  static String _formatList(List<String> values, {required String fallback}) {
    final cleaned = values.map((value) => value.trim()).where((value) => value.isNotEmpty).toList();

    if (cleaned.isEmpty) {
      return fallback;
    }

    return cleaned.join(', ');
  }
}
