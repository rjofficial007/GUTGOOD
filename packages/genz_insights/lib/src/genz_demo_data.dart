import 'package:genz_insights/src/widgets/genz_tile.dart';

class GenzReceiptData {
  const GenzReceiptData({
    required this.title,
    required this.date,
    required this.description,
    required this.vibe,
    required this.route,
  });

  final String title;
  final String date;
  final String description;
  final String vibe;
  final String route;
}

class GenzPatternDetailData {
  const GenzPatternDetailData({
    required this.title,
    required this.subtitle,
    required this.classification,
    required this.tone,
    required this.asset,
    required this.trigger,
    required this.seenCount,
    required this.confidence,
    required this.receipts,
    required this.tips,
    required this.isHelpful,
  });

  final String title;
  final String subtitle;
  final String classification;
  final GenzTone tone;
  final String asset;
  final String trigger;
  final int seenCount;
  final String confidence;
  final List<GenzReceiptData> receipts;
  final List<String> tips;
  final bool isHelpful;
}

class GenzFoodDetailData {
  const GenzFoodDetailData({
    required this.title,
    required this.sticker,
    required this.tone,
    required this.asset,
    required this.summary,
    required this.logged,
    required this.statLabel,
    required this.statValue,
    required this.lastLogged,
    required this.receipts,
    required this.patternId,
    required this.patternLabel,
    required this.patternTone,
    required this.patternAsset,
    required this.isWatch,
  });

  final String title;
  final String sticker;
  final GenzTone tone;
  final String asset;
  final String summary;
  final String logged;
  final String statLabel;
  final String statValue;
  final String lastLogged;
  final List<GenzReceiptData> receipts;
  final String patternId;
  final String patternLabel;
  final GenzTone patternTone;
  final String patternAsset;
  final bool isWatch;
}

class GenzSwapDetailData {
  const GenzSwapDetailData({
    required this.fromFood,
    required this.fromReason,
    required this.toFood,
    required this.toReason,
    required this.benefit,
    required this.tasks,
    required this.fromAsset,
    required this.toAsset,
  });

  final String fromFood;
  final String fromReason;
  final String toFood;
  final String toReason;
  final String benefit;
  final List<String> tasks;
  final String fromAsset;
  final String toAsset;
}

class GenzMealDetailData {
  const GenzMealDetailData({
    required this.mealName,
    required this.date,
    required this.vibe,
    required this.reactionVibe,
    required this.reaction,
    required this.asset,
    required this.foodAsset,
    this.foodId,
    this.foodTone = GenzTone.lime,
  });

  final String mealName;
  final String date;
  final String vibe;
  final String reactionVibe;
  final String reaction;
  final String asset;
  final String foodAsset;
  final String? foodId;
  final GenzTone foodTone;
}

const Map<String, GenzPatternDetailData> genzPatternDetails = {
  'pattern-bloating': GenzPatternDetailData(
    title: 'bloating',
    subtitle: 'digestion',
    classification: 'watch',
    tone: GenzTone.orange,
    asset: 'a-bloating.webp',
    trigger: 'cold milk → bloating',
    seenCount: 4,
    confidence: 'medium',
    receipts: [
      GenzReceiptData(title: 'Cold drink with pizza', date: 'Oct 4 · 9:10 PM', description: 'Bloating after about 2 hours', vibe: 'watch', route: 'meal-cold-drink-with-pizza'),
      GenzReceiptData(title: 'Cold milk', date: 'Oct 3 · 8:05 AM', description: 'Bloating after about 90 minutes', vibe: 'watch', route: 'meal-cold-milk'),
      GenzReceiptData(title: 'Milk tea', date: 'Oct 1 · 4:30 PM', description: 'Mild bloating after 1 hour', vibe: 'watch', route: 'meal-milk-tea'),
    ],
    tips: [
      'Try ginger tea or warm water instead of cold milk.',
      'Leave about 2 hours between milk-based foods and sleep.',
      'Log how you feel 1–2 hours after meals.',
    ],
    isHelpful: false,
  ),
  'pattern-energy': GenzPatternDetailData(
    title: 'energy',
    subtitle: 'vitality',
    classification: 'helpful',
    tone: GenzTone.butter,
    asset: 'a-energy.webp',
    trigger: 'ginger tea → steady energy',
    seenCount: 5,
    confidence: 'high',
    receipts: [
      GenzReceiptData(title: 'Ginger tea', date: 'Today · 8:05 AM', description: 'Steady energy until lunch', vibe: 'helpful', route: 'meal-ginger-tea'),
      GenzReceiptData(title: 'Ginger tea', date: 'Oct 3 · 8:05 AM', description: 'Steady energy through the morning', vibe: 'helpful', route: 'meal-ginger-tea'),
      GenzReceiptData(title: 'Ginger tea', date: 'Oct 1 · 7:50 AM', description: 'No mid-morning dip', vibe: 'helpful', route: 'meal-ginger-tea'),
    ],
    tips: [
      'Keep ginger tea in your morning routine.',
      'Pair it with a light breakfast like masala oats.',
    ],
    isHelpful: true,
  ),
  'pattern-fullness': GenzPatternDetailData(
    title: 'fullness',
    subtitle: 'satiety',
    classification: 'helpful',
    tone: GenzTone.blue,
    asset: 'a-fullness.webp',
    trigger: 'masala oats → stays full',
    seenCount: 3,
    confidence: 'medium',
    receipts: [
      GenzReceiptData(title: 'Masala oats', date: 'Today · 8:05 AM', description: 'Full until lunch', vibe: 'helpful', route: 'meal-masala-oats'),
      GenzReceiptData(title: 'Masala oats', date: 'Oct 2 · 8:20 AM', description: 'No snacking before noon', vibe: 'helpful', route: 'meal-masala-oats'),
      GenzReceiptData(title: 'Masala oats', date: 'Sep 29 · 8:00 AM', description: 'Comfortably full', vibe: 'helpful', route: 'meal-masala-oats'),
    ],
    tips: [
      'Masala oats keep you full without feeling heavy.',
      'Add a protein side when you have a long morning.',
    ],
    isHelpful: true,
  ),
  'pattern-digestion': GenzPatternDetailData(
    title: 'digestion',
    subtitle: 'gut health',
    classification: 'helpful',
    tone: GenzTone.lime,
    asset: 'a-digestion.webp',
    trigger: 'dal khichdi → easy digestion',
    seenCount: 4,
    confidence: 'medium',
    receipts: [
      GenzReceiptData(title: 'Dal khichdi', date: 'Today · 1:20 PM', description: 'No discomfort after 3 hours', vibe: 'helpful', route: 'meal-dal-khichdi'),
      GenzReceiptData(title: 'Dal khichdi', date: 'Oct 2 · 1:00 PM', description: 'Easy digestion', vibe: 'helpful', route: 'meal-dal-khichdi'),
      GenzReceiptData(title: 'Dal khichdi', date: 'Sep 30 · 1:30 PM', description: 'Light and comfortable', vibe: 'helpful', route: 'meal-dal-khichdi'),
    ],
    tips: [
      'Dal khichdi is a gentle lunch choice for you.',
      'Keep curd to a small portion at the same meal.',
    ],
    isHelpful: true,
  ),
  'pattern-sleep': GenzPatternDetailData(
    title: 'sleep',
    subtitle: 'rest & recovery',
    classification: 'watch',
    tone: GenzTone.lilac,
    asset: 'a-sleep.webp',
    trigger: 'late tea → poor sleep',
    seenCount: 2,
    confidence: 'low',
    receipts: [
      GenzReceiptData(title: 'Late tea', date: 'Oct 4 · 10:30 PM', description: 'Restless sleep reported', vibe: 'watch', route: 'meal-late-tea'),
      GenzReceiptData(title: 'Late tea', date: 'Oct 1 · 10:00 PM', description: 'Woke up twice', vibe: 'watch', route: 'meal-late-tea'),
    ],
    tips: [
      'Switch to caffeine-free tea after 6 PM.',
      'Finish your last drink 2 hours before bed.',
    ],
    isHelpful: false,
  ),
  'pattern-headache': GenzPatternDetailData(
    title: 'headache',
    subtitle: 'focus',
    classification: 'watch',
    tone: GenzTone.pink,
    asset: 'a-headache.webp',
    trigger: 'skipped lunch → headache',
    seenCount: 2,
    confidence: 'low',
    receipts: [
      GenzReceiptData(title: 'Skipped lunch', date: 'Oct 2 · 4:30 PM', description: 'Headache by late afternoon', vibe: 'watch', route: 'meal-skipped-lunch'),
      GenzReceiptData(title: 'Skipped lunch', date: 'Sep 29 · 5:00 PM', description: 'Headache and low focus', vibe: 'watch', route: 'meal-skipped-lunch'),
    ],
    tips: [
      'Eat something light by 2 PM, even on busy days.',
      'Drink water through the day.',
    ],
    isHelpful: false,
  ),
};

const Map<String, GenzFoodDetailData> genzFoodDetails = {
  'food-ginger-tea': GenzFoodDetailData(
    title: 'ginger tea', sticker: 'helps', tone: GenzTone.lime, asset: 'a-energy.webp',
    summary: 'followed by steadier energy on 5 of 6 logs.', logged: '6×', statLabel: 'good days', statValue: '5 of 6', lastLogged: 'today',
    receipts: [
      GenzReceiptData(title: 'Ginger tea', date: 'Today · 8:05 AM', description: 'Steady energy until lunch', vibe: 'helpful', route: 'meal-ginger-tea'),
      GenzReceiptData(title: 'Ginger tea', date: 'Oct 3 · 8:05 AM', description: 'Steady energy', vibe: 'helpful', route: 'meal-ginger-tea'),
      GenzReceiptData(title: 'Ginger tea', date: 'Oct 1 · 7:50 AM', description: 'No mid-morning dip', vibe: 'helpful', route: 'meal-ginger-tea'),
    ],
    patternId: 'pattern-energy', patternLabel: 'Energy · Vitality', patternTone: GenzTone.butter, patternAsset: 'a-energy.webp', isWatch: false,
  ),
  'food-masala-oats': GenzFoodDetailData(
    title: 'masala oats', sticker: 'helps', tone: GenzTone.lime, asset: 'a-fullness.webp',
    summary: 'easier digestion and long-lasting fullness on 4 of 5 logs.', logged: '5×', statLabel: 'good days', statValue: '4 of 5', lastLogged: 'today',
    receipts: [
      GenzReceiptData(title: 'Masala oats', date: 'Today · 8:05 AM', description: 'Full until lunch', vibe: 'helpful', route: 'meal-masala-oats'),
      GenzReceiptData(title: 'Masala oats', date: 'Oct 2 · 8:20 AM', description: 'No snacking before noon', vibe: 'helpful', route: 'meal-masala-oats'),
    ],
    patternId: 'pattern-fullness', patternLabel: 'Fullness · Satiety', patternTone: GenzTone.blue, patternAsset: 'a-fullness.webp', isWatch: false,
  ),
  'food-dal-khichdi': GenzFoodDetailData(
    title: 'dal khichdi', sticker: 'neutral', tone: GenzTone.blue, asset: 'a-digestion.webp',
    summary: 'no reaction on any of your 4 logs. a gentle meal for you.', logged: '4×', statLabel: 'reactions', statValue: 'none', lastLogged: 'today',
    receipts: [
      GenzReceiptData(title: 'Dal khichdi', date: 'Today · 1:20 PM', description: 'No reaction after 3 hours', vibe: 'mid', route: 'meal-dal-khichdi'),
      GenzReceiptData(title: 'Dal khichdi', date: 'Oct 2 · 1:00 PM', description: 'Easy digestion', vibe: 'mid', route: 'meal-dal-khichdi'),
    ],
    patternId: 'pattern-digestion', patternLabel: 'Digestion · Gut Health', patternTone: GenzTone.lime, patternAsset: 'a-digestion.webp', isWatch: false,
  ),
  'food-cold-milk': GenzFoodDetailData(
    title: 'cold milk', sticker: 'watch', tone: GenzTone.pink, asset: 'a-bloating.webp',
    summary: 'bloating followed it within 2 hours on 3 of 4 logs.', logged: '4×', statLabel: 'reactions', statValue: '3 of 4', lastLogged: 'yesterday',
    receipts: [
      GenzReceiptData(title: 'Cold milk', date: 'Yesterday · 9:10 PM', description: 'Bloating after about 90 minutes', vibe: 'watch', route: 'meal-cold-milk'),
      GenzReceiptData(title: 'Cold milk', date: 'Oct 3 · 8:05 AM', description: 'Bloating after 90 minutes', vibe: 'watch', route: 'meal-cold-milk'),
      GenzReceiptData(title: 'Cold milk', date: 'Oct 1 · 4:30 PM', description: 'No reaction', vibe: 'mid', route: 'meal-cold-milk'),
    ],
    patternId: 'pattern-bloating', patternLabel: 'Bloating · Digestion', patternTone: GenzTone.orange, patternAsset: 'a-bloating.webp', isWatch: true,
  ),
  'food-fried-snacks': GenzFoodDetailData(
    title: 'fried snacks', sticker: 'watch', tone: GenzTone.pink, asset: 'a-alert.webp',
    summary: 'felt sluggish after 2 of 3 logs.', logged: '3×', statLabel: 'reactions', statValue: '2 of 3', lastLogged: 'Oct 2',
    receipts: [
      GenzReceiptData(title: 'Fried snacks', date: 'Oct 2 · 5:00 PM', description: 'Sluggish for the evening', vibe: 'watch', route: 'meal-fried-snacks'),
      GenzReceiptData(title: 'Fried snacks', date: 'Sep 29 · 4:30 PM', description: 'Heavy feeling', vibe: 'watch', route: 'meal-fried-snacks'),
    ],
    patternId: 'pattern-bloating', patternLabel: 'Bloating · Digestion', patternTone: GenzTone.orange, patternAsset: 'a-bloating.webp', isWatch: true,
  ),
};

const Map<String, GenzSwapDetailData> genzSwapDetails = {
  'swap-cold-milk': GenzSwapDetailData(
    fromFood: 'cold milk',
    fromReason: 'bloating followed it on 3 of 4 logs.',
    toFood: 'ginger tea',
    toReason: 'steadier energy on 5 of 6 logs.',
    benefit: 'fewer bloating logs',
    fromAsset: 'a-bloating.webp',
    toAsset: 'a-energy.webp',
    tasks: [
      'swap your morning cold milk for ginger tea.',
      'keep it up for 3 days.',
      'log how you feel after breakfast.',
    ],
  ),
  'swap-late-tea': GenzSwapDetailData(
    fromFood: 'late tea',
    fromReason: 'restless sleep followed it twice.',
    toFood: 'chamomile tea',
    toReason: 'caffeine-free, so it is gentler before bed.',
    benefit: 'calmer evenings',
    fromAsset: 'a-sleep.webp',
    toAsset: 'a-sleep.webp',
    tasks: [
      'switch to chamomile after 6 pm.',
      'finish your last drink 2 hours before bed.',
      'note how you slept the next morning.',
    ],
  ),
  'swap-skipped-lunch': GenzSwapDetailData(
    fromFood: 'skipped lunch',
    fromReason: 'headache followed it on 2 of 2 days.',
    toFood: 'masala oats',
    toReason: 'keeps you full without feeling heavy.',
    benefit: 'steady focus',
    fromAsset: 'a-headache.webp',
    toAsset: 'a-fullness.webp',
    tasks: [
      'keep a light meal ready by 2 pm.',
      'add water alongside it.',
      'log your focus in the evening.',
    ],
  ),
};

const Map<String, GenzMealDetailData> genzMealDetails = {
  'meal-paneer-pizza-+-cold-drink': GenzMealDetailData(mealName: 'Paneer pizza + cold drink', date: 'Oct 4 · 9:10 PM', vibe: 'L', reactionVibe: 'L', reaction: 'Bloating after about 2 hours', asset: 'a-bloating.webp', foodAsset: 'a-bloating.webp'),
  'meal-cold-milk-with-oats': GenzMealDetailData(mealName: 'Cold milk with oats', date: 'Oct 3 · 8:05 AM', vibe: 'L', reactionVibe: 'L', reaction: 'Bloating after about 90 minutes', asset: 'a-bloating.webp', foodAsset: 'a-bloating.webp'),
  'meal-milk-tea': GenzMealDetailData(mealName: 'Milk tea', date: 'Oct 1 · 4:30 PM', vibe: 'L', reactionVibe: 'L', reaction: 'Mild bloating after 1 hour', asset: 'a-bloating.webp', foodAsset: 'a-bloating.webp'),
  'meal-no-dairy': GenzMealDetailData(mealName: 'No dairy', date: 'Sep 30 · all day', vibe: 'W', reactionVibe: 'W', reaction: 'No bloating logged', asset: 'a-energy.webp', foodAsset: 'a-energy.webp'),
  'meal-cold-drink-with-pizza': GenzMealDetailData(mealName: 'Cold drink with pizza', date: 'Oct 4 · 9:10 PM', vibe: 'L', reactionVibe: 'L', reaction: 'Bloating after about 2 hours', asset: 'a-bloating.webp', foodAsset: 'a-bloating.webp'),
  'meal-cold-milk': GenzMealDetailData(mealName: 'Cold milk', date: 'Oct 3 · 8:05 AM', vibe: 'L', reactionVibe: 'L', reaction: 'Bloating after about 90 minutes', asset: 'a-bloating.webp', foodAsset: 'a-bloating.webp', foodId: 'food-cold-milk', foodTone: GenzTone.pink),
  'meal-ginger-tea': GenzMealDetailData(mealName: 'Ginger tea', date: 'Today · 8:05 AM', vibe: 'W', reactionVibe: 'W', reaction: 'Steady energy until lunch', asset: 'a-energy.webp', foodAsset: 'a-energy.webp', foodId: 'food-ginger-tea', foodTone: GenzTone.lime),
  'meal-masala-oats': GenzMealDetailData(mealName: 'Masala oats', date: 'Today · 8:05 AM', vibe: 'W', reactionVibe: 'W', reaction: 'Full until lunch', asset: 'a-energy.webp', foodAsset: 'a-fullness.webp', foodId: 'food-masala-oats', foodTone: GenzTone.lime),
  'meal-dal-khichdi': GenzMealDetailData(mealName: 'Dal khichdi', date: 'Today · 1:20 PM', vibe: 'W', reactionVibe: 'W', reaction: 'No discomfort after 3 hours', asset: 'a-energy.webp', foodAsset: 'a-digestion.webp', foodId: 'food-dal-khichdi', foodTone: GenzTone.lime),
  'meal-late-tea': GenzMealDetailData(mealName: 'Late tea', date: 'Oct 4 · 10:30 PM', vibe: 'L', reactionVibe: 'L', reaction: 'Restless sleep reported', asset: 'a-bloating.webp', foodAsset: 'a-bloating.webp'),
  'meal-skipped-lunch': GenzMealDetailData(mealName: 'Skipped lunch', date: 'Oct 2 · 4:30 PM', vibe: 'L', reactionVibe: 'L', reaction: 'Headache by late afternoon', asset: 'a-bloating.webp', foodAsset: 'a-bloating.webp'),
  'meal-fried-snacks': GenzMealDetailData(mealName: 'Fried snacks', date: 'Oct 2 · 5:00 PM', vibe: 'L', reactionVibe: 'L', reaction: 'Sluggish for the evening', asset: 'a-bloating.webp', foodAsset: 'a-alert.webp', foodId: 'food-fried-snacks', foodTone: GenzTone.pink),
};
