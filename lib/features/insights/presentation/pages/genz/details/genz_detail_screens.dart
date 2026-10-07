import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../genz_theme.dart';
import '../widgets/genz_tile.dart';

class GenzDetailScreenView extends StatefulWidget {
  const GenzDetailScreenView({
    super.key,
    required this.id,
    required this.onNavigate,
  });

  final String id;
  final ValueChanged<String> onNavigate;

  @override
  State<GenzDetailScreenView> createState() => _GenzDetailScreenViewState();
}

class _GenzDetailScreenViewState extends State<GenzDetailScreenView> {
  int _foodIntelSegment = 0; // 0: all 5, 1: helps 2, 2: watch 2
  int _patternDetailSegment = 0; // 0: all, 1: watch, 2: helpful

  @override
  Widget build(BuildContext context) {
    final id = widget.id;

    if (id == 'score') return _buildScoreDetail(context);
    if (id == 'swaps') return _buildSwapsList(context);
    if (id == 'plan') return _buildPlanView(context);
    if (id == 'food-intel') return _buildFoodIntel(context);
    if (id == 'history') return _buildHistoryView(context);
    if (id == 'hist-detail') return _buildHistoryDetailView(context);
    if (id == 'synergy') return _buildSynergyDetail(context);

    if (id == 'obs-dairy') return _buildObservationDetail(context, 'dairy might be the bloating villain.', '3 of 4 days', 'medium confidence', 'top insight');
    if (id == 'obs-milktea') return _buildObservationDetail(context, 'milk tea at night might be messing with your sleep.', '1 of 7 days', 'low confidence', 'early observation');

    if (id.startsWith('pattern-')) return _buildPatternDetail(context, id);
    if (id.startsWith('swap-')) return _buildSwapItemDetail(context, id);
    if (id.startsWith('food-')) return _buildFoodDetail(context, id);
    if (id.startsWith('meal-')) return _buildMealReceiptDetail(context, id);

    return _buildScoreDetail(context);
  }

  // 1. SCORE BREAKDOWN
  Widget _buildScoreDetail(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GenzTile(
            tone: GenzTone.lime,
            art: Positioned(
              right: -12,
              top: 10,
              child: Transform.rotate(
                angle: 0.14,
                child: Image.asset('assets/images/a-gauge.webp', width: 138, height: 138),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GenzSticker(text: '+4 vs yesterday', tone: GenzTone.ink),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('78', style: GenzStyles.big),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text('/100', style: TextStyle(color: const Color(0x9E0B0B12), fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'InterTight')),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('your best score this week.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'InterTight', color: GenzColors.ink)),
                const SizedBox(height: 18),
                Text('last 7 days', style: TextStyle(color: const Color(0x9E0B0B12), fontFamily: 'InterTight', fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                const SizedBox(height: 10),
                _buildEq(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatBox('best day', 'wed 84', GenzColors.butter),
              const SizedBox(width: 10),
              _buildStatBox('foods logged', '27 items', GenzColors.lime),
              const SizedBox(width: 10),
              _buildStatBox('patterns', '6 unlocked', GenzColors.lilac),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => widget.onNavigate('plan'),
            child: Container(
              height: 54,
              width: double.infinity,
              decoration: BoxDecoration(
                color: GenzColors.lime,
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('see next week plan', style: TextStyle(color: GenzColors.ink, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3, fontFamily: 'InterTight')),
                  SizedBox(width: 8),
                  Icon(LucideIcons.arrowRight, color: GenzColors.ink, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. SWAPS LIST
  Widget _buildSwapsList(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BASED ON YOUR LAST 14 DAYS', style: GenzStyles.eyebrow(context)),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: GenzStyles.h1(context),
              children: [
                const TextSpan(text: 'swaps that might '),
                WidgetSpan(
                  child: Transform.rotate(
                    angle: -0.026,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: const BoxDecoration(
                        color: GenzColors.lime,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: const Text('help', style: TextStyle(color: GenzColors.ink, fontFamily: 'InterTight', fontSize: 34, fontWeight: FontWeight.w900, height: 0.98, letterSpacing: -1.6)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GenzTile(
            tone: GenzTone.orange,
            onTap: () => widget.onNavigate('swap-cold-milk'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GenzSticker(text: 'top pick', tone: GenzTone.ink),
                const SizedBox(height: 14),
                const Text('ginger tea for cold milk', style: GenzStyles.title),
                const SizedBox(height: 6),
                Text('our strongest match from your logs.', style: TextStyle(color: GenzColors.ink.withOpacity(0.62), fontSize: 14.5, fontWeight: FontWeight.w600, fontFamily: 'InterTight')),
                const SizedBox(height: 16),
                Container(
                  height: 48,
                  width: double.infinity,
                  decoration: BoxDecoration(color: GenzColors.ink, borderRadius: BorderRadius.circular(100)),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('see the swap', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, fontFamily: 'InterTight')),
                      SizedBox(width: 6),
                      Icon(LucideIcons.arrowRight, color: Colors.white, size: 18),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSwapRow(context, 'cold milk', 'ginger tea', 'bloating → steadier energy', 'swap-cold-milk'),
          const SizedBox(height: 10),
          _buildSwapRow(context, 'late tea', 'chamomile tea', 'restless sleep → gentler rest', 'swap-late-tea'),
          const SizedBox(height: 10),
          _buildSwapRow(context, 'skipped lunch', 'masala oats', 'headache → long-lasting fullness', 'swap-skipped-lunch'),
        ],
      ),
    );
  }

  // 3. OBS DETAILS
  Widget _buildObservationDetail(BuildContext context, String title, String tag1, String tag2, String sticker) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GenzTile(
            tone: GenzTone.ink,
            art: Positioned(
              right: -4,
              top: 10,
              child: Transform.rotate(
                angle: 0.17,
                child: Image.asset('assets/images/a-bulb.webp', width: 112, height: 112),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GenzSticker(text: sticker, tone: GenzTone.lime),
                const SizedBox(height: 16),
                Text(title, style: GenzStyles.title),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tag1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'InterTight')),
                    Text(tag2, style: TextStyle(color: Colors.white.withOpacity(0.66), fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'InterTight')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('the receipts', style: GenzStyles.h2(context)),
          const SizedBox(height: 10),
          _buildReceiptPaper([
            _buildReceiptRow('paneer pizza + cold drink', 'oct 4 · 9:10 pm', 'bloating within 2 hrs', 'watch', 'meal-paneer-pizza-+-cold-drink'),
            _buildReceiptRow('cold milk with oats', 'oct 3 · 8:05 am', 'bloating after 1 hr', 'watch', 'meal-cold-milk-with-oats'),
            _buildReceiptRow('milk tea', 'oct 1 · 4:30 pm', 'mild bloating', 'watch', 'meal-milk-tea'),
            _buildReceiptRow('no dairy', 'sep 30 · all day', 'zero symptoms', 'helpful', 'meal-no-dairy'),
          ]),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => widget.onNavigate('swap-cold-milk'),
            child: Container(
              height: 54,
              width: double.infinity,
              decoration: BoxDecoration(color: GenzColors.lime, borderRadius: BorderRadius.circular(100)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('try ginger tea instead', style: TextStyle(color: GenzColors.ink, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3, fontFamily: 'InterTight')),
                  SizedBox(width: 8),
                  Icon(LucideIcons.arrowRight, color: GenzColors.ink, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. PATTERN DETAIL
  Widget _buildPatternDetail(BuildContext context, String patternId) {
    String title = 'bloating';
    String subtitle = 'digestion';
    GenzTone tone = GenzTone.orange;
    String asset = 'a-bloating.webp';
    String trigger = 'cold milk → bloating';
    String sticker = 'watch';
    int seenCount = 4;

    if (patternId == 'pattern-energy') {
      title = 'energy';
      subtitle = 'vitality';
      tone = GenzTone.butter;
      asset = 'a-energy.webp';
      trigger = 'ginger tea → steady energy';
      sticker = 'helpful';
      seenCount = 5;
    } else if (patternId == 'pattern-fullness') {
      title = 'fullness';
      subtitle = 'satiety';
      tone = GenzTone.blue;
      asset = 'a-fullness.webp';
      trigger = 'masala oats → stays full';
      sticker = 'helpful';
      seenCount = 3;
    } else if (patternId == 'pattern-digestion') {
      title = 'digestion';
      subtitle = 'gut health';
      tone = GenzTone.lime;
      asset = 'a-digestion.webp';
      trigger = 'dal khichdi → easy digestion';
      sticker = 'helpful';
      seenCount = 4;
    } else if (patternId == 'pattern-sleep') {
      title = 'sleep';
      subtitle = 'rest & recovery';
      tone = GenzTone.lilac;
      asset = 'a-sleep.webp';
      trigger = 'late tea → poor sleep';
      sticker = 'watch';
      seenCount = 2;
    } else if (patternId == 'pattern-headache') {
      title = 'headache';
      subtitle = 'focus';
      tone = GenzTone.pink;
      asset = 'a-headache.webp';
      trigger = 'skipped lunch → headache';
      sticker = 'watch';
      seenCount = 2;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GenzTile(
            tone: tone,
            art: Positioned(
              right: -4,
              top: 20,
              child: Image.asset('assets/images/$asset', width: 130, height: 130),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GenzSticker(text: sticker, tone: GenzTone.ink),
                const SizedBox(height: 18),
                Text(title, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1.5, fontFamily: 'InterTight')),
                Text(subtitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'InterTight', color: tone == GenzTone.blue ? Colors.white.withOpacity(0.8) : GenzColors.ink.withOpacity(0.65))),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: GenzColors.ink, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(trigger, style: const TextStyle(color: GenzColors.lime, fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'InterTight')),
                      const SizedBox(width: 8),
                      Text('seen ${seenCount}×', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800, fontFamily: 'InterTight')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('the receipts', style: GenzStyles.h2(context)),
          const SizedBox(height: 10),
          _buildReceiptPaper([
            _buildReceiptRow('cold drink with pizza', 'oct 4 · 9:10 pm', 'bloating logged', 'watch', 'meal-cold-drink-with-pizza'),
            _buildReceiptRow('cold milk', 'oct 3 · 8:05 am', 'bloating logged', 'watch', 'meal-cold-milk'),
            _buildReceiptRow('milk tea', 'oct 1 · 4:30 pm', 'bloating logged', 'watch', 'meal-milk-tea'),
          ]),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => widget.onNavigate('swaps'),
            child: Container(
              height: 54,
              width: double.infinity,
              decoration: BoxDecoration(color: GenzColors.lime, borderRadius: BorderRadius.circular(100)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('find better swaps', style: TextStyle(color: GenzColors.ink, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3, fontFamily: 'InterTight')),
                  SizedBox(width: 8),
                  Icon(LucideIcons.arrowRight, color: GenzColors.ink, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. SWAP ITEM DETAIL
  Widget _buildSwapItemDetail(BuildContext context, String swapId) {
    String fromFood = 'cold milk';
    String fromReason = 'bloating followed it on 3 of 4 logs.';
    String toFood = 'ginger tea';
    String toReason = 'steadier energy on 5 of 6 logs.';

    if (swapId == 'swap-late-tea') {
      fromFood = 'late tea';
      fromReason = 'restless sleep followed it twice.';
      toFood = 'chamomile tea';
      toReason = 'caffeine-free, gentle before bed.';
    } else if (swapId == 'swap-skipped-lunch') {
      fromFood = 'skipped lunch';
      fromReason = 'headache followed it on 2 of 2 days.';
      toFood = 'masala oats';
      toReason = 'keeps you full without feeling heavy.';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: GenzColors.sf(context), borderRadius: BorderRadius.circular(28)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('INSTEAD OF', style: GenzStyles.eyebrow(context)),
                const SizedBox(height: 6),
                Text(fromFood, style: GenzStyles.h2(context)),
                const SizedBox(height: 4),
                Text(fromReason, style: TextStyle(color: GenzColors.mu(context), fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'InterTight')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: GenzColors.lime),
              child: const Icon(LucideIcons.arrowDown, color: GenzColors.ink, size: 22),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: GenzColors.lime, borderRadius: BorderRadius.circular(28)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TRY THIS', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: GenzColors.ink)),
                const SizedBox(height: 6),
                Text(toFood, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: GenzColors.ink, fontFamily: 'InterTight')),
                const SizedBox(height: 4),
                Text(toReason, style: TextStyle(color: GenzColors.ink.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'InterTight')),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => widget.onNavigate('plan'),
            child: Container(
              height: 54,
              width: double.infinity,
              decoration: BoxDecoration(color: GenzColors.sf(context), borderRadius: BorderRadius.circular(100)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('lock into next week plan', style: TextStyle(color: GenzColors.tx(context), fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'InterTight')),
                  const SizedBox(width: 8),
                  Icon(LucideIcons.check, color: GenzColors.tx(context), size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 6. FOOD DETAIL
  Widget _buildFoodDetail(BuildContext context, String foodId) {
    String title = 'ginger tea';
    String sticker = 'helps';
    GenzTone tone = GenzTone.butter;
    String asset = 'a-energy.webp';
    String summary = 'followed by steadier energy on 5 of 6 logs.';
    int loggedCount = 6;
    int goodCount = 5;
    int reactionCount = 0;
    String patternTarget = 'pattern-energy';

    if (foodId == 'food-masala-oats') {
      title = 'masala oats';
      sticker = 'helps';
      tone = GenzTone.blue;
      asset = 'a-fullness.webp';
      summary = 'easier digestion and long-lasting fullness on 4 of 5 logs.';
      loggedCount = 5;
      goodCount = 4;
      reactionCount = 0;
      patternTarget = 'pattern-fullness';
    } else if (foodId == 'food-dal-khichdi') {
      title = 'dal khichdi';
      sticker = 'neutral';
      tone = GenzTone.lime;
      asset = 'a-digestion.webp';
      summary = 'no reaction on any of your 4 logs. a gentle meal for you.';
      loggedCount = 4;
      goodCount = 4;
      reactionCount = 0;
      patternTarget = 'pattern-digestion';
    } else if (foodId == 'food-cold-milk') {
      title = 'cold milk';
      sticker = 'watch';
      tone = GenzTone.orange;
      asset = 'a-bloating.webp';
      summary = 'bloating followed it within 2 hours on 3 of 4 logs.';
      loggedCount = 4;
      goodCount = 1;
      reactionCount = 3;
      patternTarget = 'pattern-bloating';
    } else if (foodId == 'food-fried-snacks') {
      title = 'fried snacks';
      sticker = 'watch';
      tone = GenzTone.pink;
      asset = 'a-headache.webp';
      summary = 'felt sluggish after 2 of 3 logs.';
      loggedCount = 3;
      goodCount = 1;
      reactionCount = 2;
      patternTarget = 'pattern-bloating';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GenzTile(
            tone: tone,
            art: Positioned(
              right: -4,
              top: 20,
              child: Image.asset('assets/images/$asset', width: 130, height: 130),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GenzSticker(text: sticker, tone: GenzTone.ink),
                const SizedBox(height: 18),
                Text(title, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1.5, fontFamily: 'InterTight')),
                const SizedBox(height: 8),
                Text(summary, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, fontFamily: 'InterTight', color: tone == GenzTone.blue ? Colors.white.withOpacity(0.8) : GenzColors.ink.withOpacity(0.65))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatBox('logged', '${loggedCount}×', GenzColors.sf(context)),
              const SizedBox(width: 8),
              _buildStatBox('good days', '$goodCount', GenzColors.lime),
              const SizedBox(width: 8),
              _buildStatBox('reactions', '$reactionCount', GenzColors.orange),
            ],
          ),
          const SizedBox(height: 20),
          Text('linked pattern', style: GenzStyles.h2(context)),
          const SizedBox(height: 10),
          GenzTile(
            tone: tone,
            onTap: () => widget.onNavigate(patternTarget),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'InterTight')),
                      Text('view pattern details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'InterTight', color: tone == GenzTone.blue ? Colors.white.withOpacity(0.78) : GenzColors.ink.withOpacity(0.62))),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: GenzColors.ink, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.arrowRight, color: GenzColors.lime, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => widget.onNavigate('swaps'),
            child: Container(
              height: 54,
              width: double.infinity,
              decoration: BoxDecoration(color: GenzColors.lime, borderRadius: BorderRadius.circular(100)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('find better swaps', style: TextStyle(color: GenzColors.ink, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3, fontFamily: 'InterTight')),
                  SizedBox(width: 8),
                  Icon(LucideIcons.arrowRight, color: GenzColors.ink, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 7. FOOD INTELLIGENCE
  Widget _buildFoodIntel(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LAST 14 DAYS', style: GenzStyles.eyebrow(context)),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: GenzStyles.h1(context),
              children: [
                const TextSpan(text: 'food '),
                WidgetSpan(
                  child: Transform.rotate(
                    angle: -0.026,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: const BoxDecoration(
                        color: GenzColors.lime,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: const Text('intelligence', style: TextStyle(color: GenzColors.ink, fontFamily: 'InterTight', fontSize: 34, fontWeight: FontWeight.w900, height: 0.98, letterSpacing: -1.6)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildIntelSeg(0, 'all 5'),
              const SizedBox(width: 8),
              _buildIntelSeg(1, 'helps 2'),
              const SizedBox(width: 8),
              _buildIntelSeg(2, 'watch 2'),
            ],
          ),
          const SizedBox(height: 16),
          if (_foodIntelSegment == 0 || _foodIntelSegment == 1) ...[
            _buildIntelCard(context, 'ginger tea', 'helps', 'steadier energy on 5 of 6 logs', GenzColors.lime, 'food-ginger-tea'),
            const SizedBox(height: 10),
            _buildIntelCard(context, 'masala oats', 'helps', 'easier digestion & long satiety', GenzColors.lime, 'food-masala-oats'),
            const SizedBox(height: 10),
          ],
          if (_foodIntelSegment == 0) ...[
            _buildIntelCard(context, 'dal khichdi', 'neutral', 'gentle meal with no reactions', GenzColors.sf2(context), 'food-dal-khichdi'),
            const SizedBox(height: 10),
          ],
          if (_foodIntelSegment == 0 || _foodIntelSegment == 2) ...[
            _buildIntelCard(context, 'cold milk', 'watch', 'bloating on 3 of 4 logs', GenzColors.orange, 'food-cold-milk'),
            const SizedBox(height: 10),
            _buildIntelCard(context, 'fried snacks', 'watch', 'sluggishness after 2 logs', GenzColors.pink, 'food-fried-snacks'),
          ],
        ],
      ),
    );
  }

  Widget _buildIntelSeg(int idx, String label) {
    final isSelected = _foodIntelSegment == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _foodIntelSegment = idx),
        child: Container(
          height: 40,
          decoration: BoxDecoration(color: isSelected ? GenzColors.lime : GenzColors.sf(context), borderRadius: BorderRadius.circular(100)),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: isSelected ? GenzColors.ink : GenzColors.tx(context), fontSize: 13.5, fontWeight: FontWeight.w900, fontFamily: 'InterTight')),
        ),
      ),
    );
  }

  Widget _buildIntelCard(BuildContext context, String title, String tag, String desc, Color badgeBg, String route) {
    return GestureDetector(
      onTap: () => widget.onNavigate(route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: GenzColors.sf(context), borderRadius: BorderRadius.circular(22)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: TextStyle(color: GenzColors.tx(context), fontSize: 17, fontWeight: FontWeight.w900, fontFamily: 'InterTight')),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(100)),
                        child: Text(tag, style: const TextStyle(color: GenzColors.ink, fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'InterTight')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(desc, style: TextStyle(color: GenzColors.mu(context), fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'InterTight')),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: GenzColors.mu(context), size: 20),
          ],
        ),
      ),
    );
  }

  // 8. NEXT WEEK PLAN
  Widget _buildPlanView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SEP 27 – OCT 3 → NEXT WEEK', style: GenzStyles.eyebrow(context)),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: GenzStyles.h1(context),
              children: [
                const TextSpan(text: 'your plan for '),
                WidgetSpan(
                  child: Transform.rotate(
                    angle: -0.026,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: const BoxDecoration(
                        color: GenzColors.lime,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: const Text('next week', style: TextStyle(color: GenzColors.ink, fontFamily: 'InterTight', fontSize: 34, fontWeight: FontWeight.w900, height: 0.98, letterSpacing: -1.6)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GenzTile(
            tone: GenzTone.lilac,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GenzSticker(text: '3 active habits', tone: GenzTone.ink),
                const SizedBox(height: 14),
                const Text('ginger tea at breakfast', style: GenzStyles.title),
                const SizedBox(height: 6),
                Text('it led your best days this week.', style: TextStyle(color: GenzColors.ink.withOpacity(0.62), fontSize: 14.5, fontWeight: FontWeight.w600, fontFamily: 'InterTight')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('habit checklist', style: GenzStyles.h2(context)),
          const SizedBox(height: 10),
          _buildCheckItem(context, 'swap cold milk → ginger tea', '5 days targeted', true),
          const SizedBox(height: 8),
          _buildCheckItem(context, 'masala oats for lunch', '3 days targeted', true),
          const SizedBox(height: 8),
          _buildCheckItem(context, 'no tea after 8 pm', '7 days targeted', false),
        ],
      ),
    );
  }

  Widget _buildCheckItem(BuildContext context, String text, String sub, bool isChecked) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: GenzColors.sf(context), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(shape: BoxShape.circle, color: isChecked ? GenzColors.lime : GenzColors.sf2(context)),
            child: isChecked ? const Icon(LucideIcons.check, size: 16, color: GenzColors.ink) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: TextStyle(color: GenzColors.tx(context), fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'InterTight')),
                Text(sub, style: TextStyle(color: GenzColors.mu(context), fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'InterTight')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 9. HISTORY & HISTORY DETAIL
  Widget _buildHistoryView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PAST INSIGHTS', style: GenzStyles.eyebrow(context)),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: GenzStyles.h1(context),
              children: [
                const TextSpan(text: 'your insight '),
                WidgetSpan(
                  child: Transform.rotate(
                    angle: -0.026,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: const BoxDecoration(
                        color: GenzColors.lime,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: const Text('history', style: TextStyle(color: GenzColors.ink, fontFamily: 'InterTight', fontSize: 34, fontWeight: FontWeight.w900, height: 0.98, letterSpacing: -1.6)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildHistCard(context, 'Dairy may be linked to your bloating', 'Oct 5 · 8:12 AM', '78', 'obs-dairy'),
          const SizedBox(height: 12),
          _buildHistCard(context, 'Oats at breakfast → steady afternoon energy', 'Oct 3 · 6:45 PM', '66', 'synergy'),
          const SizedBox(height: 12),
          _buildHistCard(context, 'Weekly recap snapshot · Oct 3', 'Oct 3 · 9:00 AM', '66', 'hist-detail'),
        ],
      ),
    );
  }

  Widget _buildHistCard(BuildContext context, String title, String date, String score, String target) {
    return GestureDetector(
      onTap: () => widget.onNavigate(target),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: GenzColors.sf(context), borderRadius: BorderRadius.circular(24)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: GenzColors.tx(context), fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'InterTight')),
                  const SizedBox(height: 4),
                  Text(date, style: TextStyle(color: GenzColors.mu(context), fontSize: 12.5, fontWeight: FontWeight.w600, fontFamily: 'InterTight')),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: GenzColors.lime, borderRadius: BorderRadius.circular(100)),
              child: Text(score, style: const TextStyle(color: GenzColors.ink, fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'InterTight')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryDetailView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GenzTile(
            tone: GenzTone.lilac,
            onTap: () => widget.onNavigate('score'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GenzSticker(text: 'saved snapshot · oct 3', tone: GenzTone.ink),
                const SizedBox(height: 14),
                const Text('how things looked on oct 3', style: GenzStyles.title),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text('66', style: GenzStyles.big),
                    Text('/100', style: TextStyle(color: GenzColors.ink.withOpacity(0.6), fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'InterTight')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSynergyDetail(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GenzTile(
            tone: GenzTone.butter,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GenzSticker(text: 'insight · digestion', tone: GenzTone.ink),
                SizedBox(height: 14),
                Text('oats → steady energy', style: GenzStyles.title),
                SizedBox(height: 8),
                Text('oats at breakfast lined up with steadier afternoon energy.', style: TextStyle(color: GenzColors.ink, fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'InterTight')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildReceiptPaper([
            _buildReceiptRow('masala oats', 'today · 8:05 am', 'steady energy', 'helpful', 'food-masala-oats'),
            _buildReceiptRow('ginger tea', 'today · 8:05 am', 'steady energy', 'helpful', 'food-ginger-tea'),
          ]),
        ],
      ),
    );
  }

  // 10. MEAL RECEIPT DETAILS
  Widget _buildMealReceiptDetail(BuildContext context, String mealId) {
    String mealName = 'paneer pizza + cold drink';
    String timeStr = 'oct 4 · 9:10 pm';
    String vibe = 'watch';
    String symptom = 'bloating within 2 hrs';

    if (mealId == 'meal-cold-milk-with-oats' || mealId == 'meal-cold-milk') {
      mealName = 'cold milk with oats';
      timeStr = 'oct 3 · 8:05 am';
      vibe = 'watch';
      symptom = 'bloating after 1 hr';
    } else if (mealId == 'meal-milk-tea') {
      mealName = 'milk tea';
      timeStr = 'oct 1 · 4:30 pm';
      vibe = 'watch';
      symptom = 'mild bloating';
    } else if (mealId == 'meal-no-dairy') {
      mealName = 'no dairy';
      timeStr = 'sep 30 · all day';
      vibe = 'helpful';
      symptom = 'zero symptoms';
    } else if (mealId == 'meal-ginger-tea') {
      mealName = 'ginger tea';
      timeStr = 'today · 8:05 am';
      vibe = 'helpful';
      symptom = 'steady energy';
    } else if (mealId == 'meal-masala-oats') {
      mealName = 'masala oats';
      timeStr = 'today · 8:05 am';
      vibe = 'helpful';
      symptom = 'long satiety';
    } else if (mealId == 'meal-dal-khichdi') {
      mealName = 'dal khichdi';
      timeStr = 'today · 1:20 pm';
      vibe = 'helpful';
      symptom = 'easy digestion';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      child: Column(
        children: [
          _buildReceiptPaper([
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(timeStr.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: GenzColors.mu(context), fontFamily: 'InterTight')),
                  const SizedBox(height: 6),
                  Text(mealName, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -1, color: GenzColors.ink, fontFamily: 'InterTight')),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: vibe == 'helpful' ? GenzColors.lime : GenzColors.orange, borderRadius: BorderRadius.circular(100)),
                        child: Text(vibe, style: const TextStyle(color: GenzColors.ink, fontSize: 12, fontWeight: FontWeight.w900, fontFamily: 'InterTight')),
                      ),
                      const SizedBox(width: 8),
                      Text(symptom, style: TextStyle(color: GenzColors.ink.withOpacity(0.7), fontSize: 13.5, fontWeight: FontWeight.w700, fontFamily: 'InterTight')),
                    ],
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => widget.onNavigate('swaps'),
            child: Container(
              height: 54,
              width: double.infinity,
              decoration: BoxDecoration(color: GenzColors.lime, borderRadius: BorderRadius.circular(100)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('find better swaps', style: TextStyle(color: GenzColors.ink, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3, fontFamily: 'InterTight')),
                  SizedBox(width: 8),
                  Icon(LucideIcons.arrowRight, color: GenzColors.ink, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // HELPER WIDGETS
  Widget _buildStatBox(String label, String value, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: GenzColors.ink.withOpacity(0.6), fontFamily: 'InterTight')),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: GenzColors.ink, fontFamily: 'InterTight')),
          ],
        ),
      ),
    );
  }

  Widget _buildSwapRow(BuildContext context, String from, String to, String sub, String target) {
    return GestureDetector(
      onTap: () => widget.onNavigate(target),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: GenzColors.sf(context), borderRadius: BorderRadius.circular(22)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(from, style: TextStyle(color: GenzColors.tx(context), fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'InterTight')),
                      const SizedBox(width: 6),
                      Icon(LucideIcons.arrowRight, size: 14, color: GenzColors.mu(context)),
                      const SizedBox(width: 6),
                      Text(to, style: const TextStyle(color: GenzColors.lime, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'InterTight')),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(sub, style: TextStyle(color: GenzColors.mu(context), fontSize: 12.5, fontWeight: FontWeight.w600, fontFamily: 'InterTight')),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: GenzColors.mu(context), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptPaper(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GenzColors.paper,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildReceiptRow(String title, String date, String desc, String vibe, String route) {
    return GestureDetector(
      onTap: () => widget.onNavigate(route),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date.toUpperCase(), style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: GenzColors.mu(context), fontFamily: 'InterTight')),
                  const SizedBox(height: 2),
                  Text(title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: GenzColors.ink, fontFamily: 'InterTight')),
                  const SizedBox(height: 2),
                  Text(desc, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: GenzColors.ink.withOpacity(0.65), fontFamily: 'InterTight')),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: vibe == 'helpful' ? GenzColors.lime : GenzColors.orange, borderRadius: BorderRadius.circular(100)),
              child: Text(vibe, style: const TextStyle(color: GenzColors.ink, fontSize: 11.5, fontWeight: FontWeight.w900, fontFamily: 'InterTight')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEq() {
    return SizedBox(
      height: 60,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildEqBar('S', 0.45, false),
          _buildEqBar('M', 0.10, true),
          _buildEqBar('T', 0.60, false),
          _buildEqBar('W', 0.65, false),
          _buildEqBar('T', 0.55, false),
          _buildEqBar('F', 0.75, false),
          _buildEqBar('S', 0.90, false, isHi: true),
        ],
      ),
    );
  }

  Widget _buildEqBar(String day, double pct, bool isZero, {bool isHi = false}) {
    final barHeight = isZero ? 6.0 : (28.0 * pct).clamp(6.0, 28.0);
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 10,
            height: barHeight,
            decoration: BoxDecoration(
              color: isHi ? GenzColors.ink : GenzColors.ink.withValues(alpha: isZero ? 0.1 : 0.2),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(height: 4),
          Text(day, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: GenzColors.ink.withValues(alpha: 0.75), fontFamily: 'InterTight')),
        ],
      ),
    );
  }
}
