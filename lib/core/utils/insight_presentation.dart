/// P2-10: thin presentation mapping for insights, owned by Dart.
///
/// The LLM emits data only (no emoji/icon/color keys — see `InsightsPrompt`
/// rule 5). These resolvers fill visuals deterministically so stored docs and
/// future readers never depend on model-invented presentation.
class InsightPresentation {
  InsightPresentation._();

  /// Keyword → emoji, first match wins (order matters: specific before
  /// generic). Falls back to [defaultFoodEmoji] for unknown foods.
  static const _foodEmoji = <List<String>>[
    ['pizza', '🍕'],
    ['burger', '🍔'],
    ['fries', '🍟'],
    ['sushi', '🍣'],
    ['salad', '🥗'],
    ['oat', '🥣'],
    ['cereal', '🥣'],
    ['porridge', '🥣'],
    ['milk', '🥛'],
    ['cheese', '🧀'],
    ['yogurt', '🍦'],
    ['curd', '🍚'],
    ['egg', '🥚'],
    ['chicken', '🍗'],
    ['fish', '🐟'],
    ['paneer', '🧀'],
    ['dal', '🍲'],
    ['soup', '🍲'],
    ['khichdi', '🍲'],
    ['rice', '🍚'],
    ['biryani', '🍚'],
    ['roti', '🫓'],
    ['paratha', '🫓'],
    ['bread', '🍞'],
    ['pasta', '🍝'],
    ['noodle', '🍜'],
    ['maggie', '🍜'],
    ['sandwich', '🥪'],
    ['taco', '🌮'],
    ['wrap', '🌯'],
    ['strawberry', '🍓'],
    ['fruit', '🍓'],
    ['berry', '🫐'],
    ['banana', '🍌'],
    ['apple', '🍎'],
    ['mango', '🥭'],
    ['vegetable', '🥦'],
    ['veggie', '🥗'],
    ['broccoli', '🥦'],
    ['carrot', '🥕'],
    ['potato', '🥔'],
    ['nut', '🥜'],
    ['almond', '🥜'],
    ['chocolate', '🍫'],
    ['cake', '🍰'],
    ['ice cream', '🍨'],
    ['coffee', '☕'],
    ['tea', '🍵'],
    ['chai', '🍵'],
    ['juice', '🧃'],
    ['drink', '🥤'],
    ['beverage', '🥤'],
    ['soda', '🥤'],
    ['cola', '🥤'],
    ['water', '💧'],
    ['honey', '🍯'],
  ];

  static const String defaultFoodEmoji = '🍽️';

  /// Deterministic food emoji for [foodName] (case-insensitive substring).
  static String emojiForFood(String foodName) {
    final lower = foodName.toLowerCase();
    for (final entry in _foodEmoji) {
      if (lower.contains(entry[0])) return entry[1];
    }
    return defaultFoodEmoji;
  }
}
