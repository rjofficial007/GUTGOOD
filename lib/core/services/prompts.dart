import 'package:gutgood/core/services/prompts/mode_prompts.dart';
import 'package:gutgood/core/services/prompts/mode_prompts/default_objective_prompt.dart';
import 'package:gutgood/core/services/prompts/mode_prompts/full_analysis_prompt.dart';
import 'package:gutgood/core/services/prompts/mode_prompts/general_rules_prompt.dart';
import 'package:gutgood/core/services/prompts/mode_prompts/health_assessment_prompt.dart';
import 'package:gutgood/core/services/prompts/mode_prompts/image_classification_prompt.dart';
import 'package:gutgood/core/services/prompts/mode_prompts/ingredients_label_prompt.dart';
import 'package:gutgood/core/services/prompts/mode_prompts/insights_prompt.dart';
import 'package:gutgood/core/services/prompts/mode_prompts/intent_detection_prompt.dart';
import 'package:gutgood/core/services/prompts/mode_prompts/meal_overview_prompt.dart';
import 'package:gutgood/core/services/prompts/mode_prompts/meal_planning_prompt.dart';
import 'package:gutgood/core/services/prompts/mode_prompts/meal_rating_prompt.dart';
import 'package:gutgood/core/services/prompts/mode_prompts/meal_swaps_prompt.dart';
import 'package:gutgood/core/services/prompts/mode_prompts/product_analysis_prompt.dart';
import 'package:gutgood/core/services/prompts/mode_prompts/product_comparison_prompt.dart';
import 'package:gutgood/core/services/prompts/mode_prompts/restaurant_menu_prompt.dart';
import 'package:gutgood/core/services/prompts/mode_prompts/summarization_prompt.dart';
import 'package:gutgood/core/services/prompts/mode_prompts/symptom_analysis_prompt.dart';
import 'package:gutgood/core/services/prompts/mode_prompts/unknown_vision_prompt.dart';
import 'package:gutgood/core/services/prompts/schema_definitions.dart';

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
  static String get _strictFormattingRules => GeneralRulesPrompt.strictFormattingRules;

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

    final intentPrompt = _getPromptForIntent(intent);

    return '''
$_identity

COMMUNICATION STYLE
$communicationStyle

$timeContext
$_visionCapability

$_corePhilosophy

$_safetyRules

$_strictFormattingRules

$intentPrompt

Turn Context:
${mode != null ? 'ACTIVE MODE: $mode' : 'ACTIVE MODE: General Chat'}

CRITICAL: YOUR RESPONSE IS NOT COMPLETE UNTIL YOU EMIT THE [GUTGOOD_DATA] BLOCK.
- You MUST output exactly ONE [GUTGOOD_DATA] block at the very end of your response.
- If an image was attached: You MUST populate BOTH the "scan" and "meal" objects in the data block. You MUST ESTIMATE high-fidelity details (nutrients, ingredients, novaGroup) for meals to ensure the user's scan result screen is fully grounded in data.
- If the user is reporting a symptom: You MUST populate the "symptoms" array.
- If you recommended swaps: You MUST populate the "swaps" array.

STRICT FORMAT: 
[Conversational Response in Markdown]

[GUTGOOD_DATA]
{
  "intent": "...",
  "scan": { ... },
  "meal": { ... },
  "symptoms": [ ... ],
  "swaps": [ ... ],
  "metadata": { ... }
}
[/GUTGOOD_DATA]

USER PROFILE

Health Goals:
$goals

Sensitivities & Allergies:
$sensitivities

Lifestyle:
$lifestyle

Current Cycle Phase:
$cyclePhase

$summaryText

${SchemaDefinitions.unifiedDataSchema}
${SchemaDefinitions.typeRules}

${includePatternEngine ? '\n$_patternEngineRules' : ''}
''';
  }

  static String _getPromptForIntent(String? intent) {
    if (intent == null) return DefaultObjectivePrompt.instruction;

    final normalized = intent.toLowerCase();

    // Check most specific intents first
    if (normalized.contains('full_analysis')) {
      return FullAnalysisPrompt.instruction;
    } else if (normalized.contains('meal_rating')) {
      return MealRatingPrompt.instruction;
    } else if (normalized.contains('health_assessment')) {
      return HealthAssessmentPrompt.instruction;
    } else if (normalized.contains('meal_swaps')) {
      return MealSwapsPrompt.instruction;
    } else if (normalized.contains('meal_overview')) {
      return MealOverviewPrompt.instruction;
    } else if (normalized.contains('symptom_analysis')) {
      return SymptomAnalysisPrompt.instruction;
    } else if (normalized.contains('product_comparison')) {
      return ProductComparisonPrompt.instruction;
    } else if (normalized.contains('meal_planning')) {
      return MealPlanningPrompt.instruction;
    } else if (normalized.contains('menu')) {
      return RestaurantMenuPrompt.instruction;
    } else if (normalized.contains('label')) {
      return IngredientsLabelPrompt.instruction;
    } else if (normalized.contains('food') || normalized.contains('gallery')) {
      return FullAnalysisPrompt.instruction;
    }

    return DefaultObjectivePrompt.instruction;
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

    switch (normalizedMode) {
      case 'RESTAURANT_MENU':
      case 'MENU':
        return ModePrompts.restaurantMenuInstruction(goals: userGoals, sensitivities: userSensitivities, lifestyle: userLifestyle, phase: cyclePhase);

      case 'FOOD':
      case 'MEAL':
        return ModePrompts.mealSnapInstruction(goals: userGoals, sensitivities: userSensitivities, lifestyle: userLifestyle, phase: cyclePhase);

      case 'INGREDIENTS_LABEL':
      case 'LABEL':
      case 'INGREDIENT':
        return ModePrompts.ingredientLabelInstruction(goals: userGoals, sensitivities: userSensitivities, lifestyle: userLifestyle, phase: cyclePhase);

      case 'PRODUCT_BARCODE':
      case 'BARCODE':
        return barcodeAnalysisSystemInstruction;

      default:
        return _unknownVisionModeInstruction(goals: userGoals, sensitivities: userSensitivities, lifestyle: userLifestyle, phase: cyclePhase);
    }
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

  // ---------------------------------------------------------------------------
  // INSIGHTS ANALYSIS
  // ---------------------------------------------------------------------------

  /// Prompt for analyzing history and generating personalized insights.
  static String insightsAnalysisPrompt({
    required List<String> userGoals,
    required List<String> userSensitivities,
    required List<String> userLifestyle,
    required String cyclePhase,
    required String historyJson,
    String? historySummary,
    String? recentJournalText,
    String? historicalJournalSummary,
    String? scoreHistory,
    String? preComputedPatternCandidates,
  }) {
    final goals = _formatList(userGoals, fallback: 'General Health');
    final sensitivities = _formatList(userSensitivities, fallback: 'None specified');
    final lifestyle = _formatList(userLifestyle, fallback: 'None specified');

    return """
${InsightsPrompt.instruction}

YOUR JOB
Analyze the user's logged food, symptoms, conversations, scans, and scores to
identify meaningful repeated associations.

USER PROFILE
Health Goals: $goals
Sensitivities: $sensitivities
Lifestyle: $lifestyle
Current Cycle Phase: $cyclePhase

DATA STREAMS
1. CHAT HISTORY
${historySummary != null ? 'LONG-TERM CHAT SUMMARY:\n$historySummary\n' : ''}
RECENT CHAT LOGS:
$historyJson

2. BODY JOURNAL (Tiered Context)
${historicalJournalSummary != null ? 'HISTORICAL TRENDS (Days 8-30):\n$historicalJournalSummary\n' : ''}
HIGH-FIDELITY RECENT EVENTS (Last 7 Days):
${recentJournalText ?? 'No recent journal data yet.'}

5. PREVIOUS GUT SCORES
${scoreHistory ?? 'No historical scores yet.'}
${preComputedPatternCandidates != null ? '''

6. PRE-QUALIFIED PATTERN CANDIDATES:
$preComputedPatternCandidates
''' : ''}

The final response must contain ONLY the JSON object.
""";
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
