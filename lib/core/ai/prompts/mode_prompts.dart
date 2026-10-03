import 'package:gutgood/core/ai/prompts/mode_prompts/barcode_analysis_prompt.dart';
import 'package:gutgood/core/ai/prompts/mode_prompts/full_analysis_prompt.dart';
import 'package:gutgood/core/ai/prompts/mode_prompts/general_rules_prompt.dart';
import 'package:gutgood/core/ai/prompts/mode_prompts/ingredients_label_prompt.dart';
import 'package:gutgood/core/ai/prompts/mode_prompts/restaurant_menu_prompt.dart';
import 'package:gutgood/core/ai/prompts/mode_prompts/vision_safety_prompt.dart';
import 'package:gutgood/core/ai/prompts/schema_definitions.dart';

class ModePrompts {
  ModePrompts._();

  /// Shared safety and evidence rules used by all vision modes.
  static String get _sharedRules => '${VisionSafetyPrompt.instruction}\n${GeneralRulesPrompt.analysisDiscipline}';

  /// 📸 MEAL SNAP MODE
  static String mealSnapInstruction({required List<String> goals, required List<String> sensitivities, required List<String> lifestyle, required String phase}) {
    final goalList = goals.isEmpty ? 'None specified' : goals.join(', ');
    final sensitivityList = sensitivities.isEmpty ? 'None specified' : sensitivities.join(', ');
    final lifestyleList = lifestyle.isEmpty ? 'None specified' : lifestyle.join(', ');

    return '''
$_sharedRules

VISION MODE: Complete Meal Analysis

USER PROFILE
Goals: $goalList
Sensitivities: $sensitivityList
Lifestyle: $lifestyleList
Current Phase: $phase

${FullAnalysisPrompt.instruction}

${SchemaDefinitions.unifiedDataSchema}
''';
  }

  /// 🔍 INGREDIENT LABEL MODE
  static String ingredientLabelInstruction({required List<String> goals, required List<String> sensitivities, required List<String> lifestyle, required String phase}) {
    final sensitivityList = sensitivities.isEmpty ? 'None specified' : sensitivities.join(', ');

    return '''
$_sharedRules

VISION MODE: Ingredient Label

USER PROFILE
Sensitivities: $sensitivityList

${IngredientsLabelPrompt.instruction}

${SchemaDefinitions.unifiedDataSchema}
''';
  }

  /// 🍽️ RESTAURANT MENU MODE
  static String restaurantMenuInstruction({required List<String> goals, required List<String> sensitivities, required List<String> lifestyle, required String phase}) {
    final goalList = goals.isEmpty ? 'None specified' : goals.join(', ');
    final sensitivityList = sensitivities.isEmpty ? 'None specified' : sensitivities.join(', ');

    return '''
$_sharedRules

VISION MODE: Restaurant Menu

USER PROFILE
Goals: $goalList
Sensitivities: $sensitivityList

${RestaurantMenuPrompt.instruction}

${SchemaDefinitions.unifiedDataSchema}
''';
  }

  /// 📦 BARCODE MODE
  static String barcodeAnalysisInstruction() =>
      '''
${BarcodeAnalysisPrompt.instruction}

${SchemaDefinitions.unifiedDataSchema}
''';
}
