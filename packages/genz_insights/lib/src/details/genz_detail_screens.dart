import 'package:flutter/material.dart';
import 'package:genz_insights/src/genz_demo_data.dart';
import 'package:genz_insights/src/genz_theme.dart';
import 'package:genz_insights/src/widgets/genz_primitives.dart';
import 'package:genz_insights/src/widgets/genz_share.dart';
import 'package:genz_insights/src/widgets/genz_tile.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  final Map<String, bool> _addedToPlan = <String, bool>{};
  final Map<String, List<bool>> _swapQuestDone = <String, List<bool>>{};
  bool _allPlanAdded = false;

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

    if (id == 'obs-dairy') return _buildObservationDetail(context, isMilkTea: false);
    if (id == 'obs-milktea') return _buildObservationDetail(context, isMilkTea: true);

    if (id.startsWith('pattern-')) return _buildPatternDetail(context, id);
    if (id.startsWith('swap-')) return _buildSwapItemDetail(context, id);
    if (id.startsWith('food-')) return _buildFoodDetail(context, id);
    if (id.startsWith('meal-')) return _buildMealReceiptDetail(context, id);

    return _buildScoreDetail(context);
  }

  // 1. SCORE BREAKDOWN
  Widget _buildScoreDetail(BuildContext context) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: GenzTile(
              tone: GenzTone.lime,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
              art: Positioned(
                right: -14,
                top: 16,
                child: Transform.rotate(angle: 0.14, child: const GenzArt(asset: 'assets/images/a-gauge.webp', width: 150, height: 150)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const GenzSticker(text: '+4 vs yesterday'),
                  const SizedBox(height: 14),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(color: GenzColors.ink, fontFamily: GenzFonts.primary, fontWeight: FontWeight.w900),
                      children: [
                        TextSpan(text: '78', style: TextStyle(fontSize: 96, letterSpacing: -5, height: 0.82)),
                        TextSpan(text: '/100', style: TextStyle(fontSize: 26, letterSpacing: -1, color: Color(0x8C0B0B12))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('your best score this week.', style: TextStyle(color: GenzColors.ink, fontSize: 14.5, fontWeight: FontWeight.w600, fontFamily: GenzFonts.primary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
          Text('last 7 days', style: GenzStyles.h2(context)),
          const SizedBox(height: 10),
          GenzTile(
            tone: GenzTone.ink,
            padding: const EdgeInsets.all(18),
            child: _buildEq(),
          ),
          const SizedBox(height: 26),
          Text('what shapes it', style: GenzStyles.h2(context)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: GenzColors.sf(context), borderRadius: BorderRadius.circular(28)),
            child: Column(
              children: [
                _buildScoreFactor(context, 'symptoms', 82, 'fewer bloating logs this week.'),
                _buildScoreFactor(context, 'food quality', 76, 'more helpful foods than watch foods.'),
                _buildScoreFactor(context, 'consistency', 71, 'you logged on 6 of 7 days.'),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text('what moved it', style: GenzStyles.h2(context)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: GenzColors.sf(context), borderRadius: BorderRadius.circular(28)),
            child: Column(
              children: [
                _buildScoreMover(context, '+3', 'no bloating logged on sunday', true, isFirst: true),
                _buildScoreMover(context, '+2', 'ginger tea at breakfast', true),
                _buildScoreMover(context, '−1', 'late dinner on friday', false, isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 26),
          _buildFootnote(context, 'your score reflects how you logged feeling. it isn’t a medical score.'),
        ],
      ),
    );

  // 2. SWAPS LIST
  Widget _buildSwapsList(BuildContext context) => SingleChildScrollView(
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
                      child: const Text('help', style: TextStyle(color: GenzColors.ink, fontFamily: GenzFonts.primary, fontSize: 38, fontWeight: FontWeight.w900, height: 0.98, letterSpacing: -1.8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GenzTile(
            tone: GenzTone.orange,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            onTap: () => widget.onNavigate('swap-cold-milk'),
            art: Positioned(
              right: -14,
              top: 16,
              child: Transform.rotate(
                angle: 0.14,
                child: const GenzArt(asset: 'assets/images/a-alert.webp', width: 130, height: 130),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GenzSticker(text: 'top pick'),
                const SizedBox(height: 14),
                const SizedBox(
                  width: 210,
                  child: Text('ginger tea for cold milk', style: TextStyle(fontSize: 31, fontWeight: FontWeight.w900, letterSpacing: -1.3, height: 1, fontFamily: GenzFonts.primary)),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 210,
                  child: Text('our strongest match from your logs.', style: TextStyle(color: GenzColors.ink.withValues(alpha: 0.62), fontSize: 14.5, fontWeight: FontWeight.w600, fontFamily: GenzFonts.primary)),
                ),
                const SizedBox(height: 16),
                SizedBox(width: 190, child: _buildDarkAction('see why')),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text('all swaps', style: GenzStyles.h2(context)),
          const SizedBox(height: 10),
          _buildSwapRow(context, 'Best match', 'cold milk → ginger tea', 'fewer bloating logs · steadier energy', 'a-bloating.webp', 'swap-cold-milk', best: true),
          const SizedBox(height: 12),
          _buildSwapRow(context, 'Good option', 'late tea → chamomile tea', 'calmer evenings · better sleep', 'a-sleep.webp', 'swap-late-tea'),
          const SizedBox(height: 12),
          _buildSwapRow(context, 'Quick fix', 'skipped lunch → masala oats', 'steady focus · fewer headaches', 'a-headache.webp', 'swap-skipped-lunch'),
          const SizedBox(height: 26),
          _buildFootnote(context, 'swap ideas come from your own logs. not medical advice.'),
        ],
      ),
    );

  // 3. OBSERVATION DETAILS
  Widget _buildObservationDetail(BuildContext context, {required bool isMilkTea}) {
    final title = isMilkTea
        ? 'milk tea at night might be messing with your sleep.'
        : 'dairy might be the bloating villain.';
    final count = isMilkTea ? '1 of 7 days' : '3 of 4 days';
    final confidence = isMilkTea ? 'low confidence' : 'medium confidence';
    final receiptRows = isMilkTea
        ? <Widget>[
            _buildReceiptRow('Milk tea', 'Oct 4 · 10:30 PM', 'Restless sleep reported', 'watch', 'meal-late-tea', isLast: true),
          ]
        : <Widget>[
            _buildReceiptRow('Paneer pizza + cold drink', 'Oct 4 · 9:10 PM', 'Bloating after about 2 hours', 'watch', 'meal-paneer-pizza-+-cold-drink'),
            _buildReceiptRow('Cold milk with oats', 'Oct 3 · 8:05 AM', 'Bloating after about 90 minutes', 'watch', 'meal-cold-milk-with-oats'),
            _buildReceiptRow('Milk tea', 'Oct 1 · 4:30 PM', 'Mild bloating after 1 hour', 'watch', 'meal-milk-tea'),
            _buildReceiptRow('No dairy', 'Sep 30 · all day', 'No bloating logged', 'helpful', 'meal-no-dairy', isLast: true),
          ];
    final tips = isMilkTea
        ? const <String>[
            'Note your bedtime and how you slept tomorrow.',
            'Try caffeine-free tea after 6 PM for a few days.',
          ]
        : const <String>[
            'Try a 3-day break from cold milk and see how you feel.',
            'Leave about 2 hours between milk-based foods and sleep.',
            'Log how you feel 1–2 hours after meals.',
          ];

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
              child: Transform.rotate(angle: 0.17, child: const GenzArt(asset: 'assets/images/a-bulb.webp', width: 118, height: 118)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GenzSticker(text: isMilkTea ? 'early observation' : 'top insight', tone: GenzTone.lime, angle: -0.035),
                const SizedBox(height: 14),
                SizedBox(width: 236, child: Text(title, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1.3, height: 1, fontFamily: GenzFonts.primary))),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(count, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary)),
                    Text(confidence, style: TextStyle(color: Colors.white.withValues(alpha: 0.66), fontSize: 13, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                _buildConfidenceDots(isMilkTea ? 1 : 3, isMilkTea ? 7 : 4),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text('the receipts', style: GenzStyles.h2(context)),
          const SizedBox(height: 10),
          _buildReceiptPaper([
            _buildReceiptHeader('logged timeline', 'meals + symptoms'),
            ...receiptRows,
          ]),
          const SizedBox(height: 26),
          Text('what you can try', style: GenzStyles.h2(context)),
          const SizedBox(height: 10),
          _buildTips(tips),
          const SizedBox(height: 18),
          if (isMilkTea)
            GestureDetector(
              onTap: () => showGenzToast(context, 'opens the symptom logger in the app'),
              child: _buildActionButton('log tonight’s sleep', filled: true),
            )
          else ...[
            GestureDetector(
              onTap: () => widget.onNavigate('swap-cold-milk'),
              child: _buildActionButton('try ginger tea instead', filled: true),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => showGenzToast(context, 'opens the symptom logger in the app'),
              child: _buildActionButton('log a symptom', filled: false),
            ),
            const SizedBox(height: 18),
            Text('related', style: GenzStyles.h2(context)),
            const SizedBox(height: 10),
            _buildFoodLink(context, 'pattern', 'Bloating · Digestion', 'pattern-bloating', GenzTone.orange, asset: 'a-bloating.webp'),
          ],
          const SizedBox(height: 26),
          _buildFootnote(
            context,
            isMilkTea
                ? 'one observation is not enough to confirm a pattern. log a few more nights.'
                : 'this is an observation, not a diagnosis. more logs make it more reliable.',
          ),
        ],
      ),
    );
  }

  // 4. PATTERN DETAIL
  Widget _buildPatternDetail(BuildContext context, String patternId) {
    final data = genzPatternDetails[patternId] ?? genzPatternDetails['pattern-bloating']!;
    final added = _addedToPlan[patternId] ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GenzTile(
            tone: data.tone,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            art: Positioned(
              right: -14,
              top: 16,
              child: Transform.rotate(
                angle: 0.14,
                child: GenzArt(asset: 'assets/images/${data.asset}', width: 170, height: 170),
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GenzSticker(text: data.classification),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: 190,
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -1.5, height: 1, fontFamily: GenzFonts.primary),
                        children: [
                          TextSpan(text: '${data.title}\n'),
                          TextSpan(
                            text: data.subtitle,
                            style: TextStyle(color: data.tone == GenzTone.blue ? Colors.white.withValues(alpha: 0.55) : GenzColors.ink.withValues(alpha: 0.55)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 190,
                    child: Text(
                      data.trigger,
                      style: TextStyle(
                        color: data.tone == GenzTone.blue ? Colors.white.withValues(alpha: 0.78) : GenzColors.ink.withValues(alpha: 0.62),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        fontFamily: GenzFonts.primary,
                        fontFamilyFallback: GenzFonts.fallback,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMetricBox(context, 'seen', '${data.seenCount}×'),
              const SizedBox(width: 8),
              _buildMetricBox(context, 'window', '14 days'),
              const SizedBox(width: 10),
              _buildMetricBox(context, 'confidence', data.confidence),
            ],
          ),
          const SizedBox(height: 26),
          Text('the receipts', style: GenzStyles.h2(context)),
          const SizedBox(height: 10),
          _buildReceiptPaper([
            _buildReceiptHeader('evidence', 'logged by you'),
            for (var index = 0; index < data.receipts.length; index++)
              _buildReceiptRow(
                data.receipts[index].title,
                data.receipts[index].date,
                data.receipts[index].description,
                data.receipts[index].vibe,
                data.receipts[index].route,
                isLast: index == data.receipts.length - 1,
              ),
          ]),
          const SizedBox(height: 26),
          Text('what might help', style: GenzStyles.h2(context)),
          const SizedBox(height: 8),
          _buildTips(data.tips),
          const SizedBox(height: 18),
          if (data.isHelpful)
            GestureDetector(
              onTap: () {
                final nextValue = !added;
                setState(() => _addedToPlan[patternId] = nextValue);
                showGenzToast(context, nextValue ? 'locked in. you’re doing it' : 'removed from your plan');
              },
              child: _buildActionButton(added ? 'added to your plan ✓' : 'add to next steps', filled: true, icon: LucideIcons.plus),
            )
          else
            GestureDetector(
              onTap: () => widget.onNavigate('swaps'),
              child: _buildActionButton('find better swaps', filled: true),
            ),
          const SizedBox(height: 26),
          _buildFootnote(context, 'patterns are observations from your logs. not medical advice.'),
        ],
      ),
    );
  }

  // 5. SWAP ITEM DETAIL
  Widget _buildSwapItemDetail(BuildContext context, String swapId) {
    final data = genzSwapDetails[swapId] ?? genzSwapDetails['swap-cold-milk']!;
    final tasks = _swapQuestDone.putIfAbsent(swapId, () => List<bool>.filled(data.tasks.length, false));
    final completed = tasks.where((done) => done).length;
    final added = _addedToPlan[swapId] ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GenzTile(
            tone: GenzTone.pink,
            padding: const EdgeInsets.all(20),
            art: Positioned(
              right: -8,
              top: 10,
              child: Transform.rotate(
                angle: 0.14,
                child: GenzArt(asset: 'assets/images/${data.fromAsset}', width: 130, height: 130),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GenzSticker(text: 'instead of'),
                const SizedBox(height: 12),
                Text(data.fromFood, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1.5, fontFamily: GenzFonts.primary)),
                const SizedBox(height: 8),
                SizedBox(width: 200, child: Text(data.fromReason, style: TextStyle(color: GenzColors.ink.withValues(alpha: 0.62), fontSize: 14.5, fontWeight: FontWeight.w600, height: 1.35, fontFamily: GenzFonts.primary))),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -16),
            child: Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: GenzColors.ink,
                  shape: BoxShape.circle,
                  border: Border.all(color: GenzColors.scaffoldBg(context), width: 4),
                ),
                child: const Icon(LucideIcons.arrowDown, color: GenzColors.lime, size: 22),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -16),
            child: GenzTile(
              tone: GenzTone.lime,
              padding: const EdgeInsets.all(20),
              art: Positioned(
                right: -8,
                top: 10,
                child: Transform.rotate(
                  angle: 0.14,
                  child: GenzArt(asset: 'assets/images/${data.toAsset}', width: 130, height: 130),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const GenzSticker(text: 'try this', tone: GenzTone.ink),
                  const SizedBox(height: 12),
                  Text(data.toFood, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1.5, fontFamily: GenzFonts.primary)),
                  const SizedBox(height: 8),
                  SizedBox(width: 200, child: Text(data.toReason, style: TextStyle(color: GenzColors.ink.withValues(alpha: 0.62), fontSize: 14.5, fontWeight: FontWeight.w600, height: 1.35, fontFamily: GenzFonts.primary))),
                  const SizedBox(height: 12),
                  GenzSticker(text: data.benefit, angle: -0.035),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text('side quests', style: GenzStyles.h2(context)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: GenzColors.sf(context), borderRadius: BorderRadius.circular(28)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('how to try it', style: TextStyle(color: GenzColors.tx(context), fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: -0.6, fontFamily: GenzFonts.primary)),
                        Padding(padding: const EdgeInsets.only(top: 2), child: Text('$completed of ${data.tasks.length} done', style: TextStyle(color: GenzColors.mu(context), fontSize: 13, fontWeight: FontWeight.w700, fontFamily: GenzFonts.primary))),
                      ],
                    ),
                    GenzSticker(text: '${completed * 10} xp', tone: GenzTone.ink, angle: 0.05),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: completed / data.tasks.length,
                    minHeight: 10,
                    backgroundColor: GenzColors.sf2(context),
                    valueColor: const AlwaysStoppedAnimation<Color>(GenzColors.lime),
                  ),
                ),
                const SizedBox(height: 6),
                for (var index = 0; index < data.tasks.length; index++) ...[
                  if (index > 0) GenzDashedDivider(color: GenzColors.ln(context), thickness: 1.5),
                  GestureDetector(
                    onTap: () {
                      final wasDone = tasks[index];
                      setState(() => tasks[index] = !wasDone);
                      if (!wasDone && tasks.every((done) => done)) {
                        showGenzToast(context, 'quest cleared. +${tasks.length * 10} xp');
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: tasks[index] ? GenzColors.lime : GenzColors.sf2(context),
                              border: tasks[index] ? null : Border.all(color: GenzColors.mu(context), width: 2.5),
                            ),
                            child: tasks[index] ? const Icon(LucideIcons.check, color: GenzColors.ink, size: 16) : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              data.tasks[index],
                              style: TextStyle(
                                color: tasks[index] ? GenzColors.mu(context) : GenzColors.tx(context),
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                decoration: tasks[index] ? TextDecoration.lineThrough : null,
                                fontFamily: GenzFonts.primary,
                                fontFamilyFallback: GenzFonts.fallback,
                              ),
                            ),
                          ),
                          Text('+10 xp', style: TextStyle(color: tasks[index] ? GenzColors.lime : GenzColors.mu(context), fontSize: 11.5, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () {
              final nextValue = !added;
              setState(() => _addedToPlan[swapId] = nextValue);
              showGenzToast(context, nextValue ? 'locked in. you’re doing it' : 'removed from your plan');
            },
            child: _buildActionButton(added ? 'added to your plan ✓' : 'add to my plan', filled: true, icon: LucideIcons.plus),
          ),
          const SizedBox(height: 26),
          _buildFootnote(context, 'swap ideas come from your own logs. not medical advice.'),
        ],
      ),
    );
  }

  // 6. FOOD DETAIL
  Widget _buildFoodDetail(BuildContext context, String foodId) {
    final data = genzFoodDetails[foodId] ?? genzFoodDetails['food-ginger-tea']!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GenzTile(
            tone: data.tone,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            art: Positioned(
              right: -14,
              top: 16,
              child: Transform.rotate(
                angle: 0.14,
                child: GenzArt(asset: 'assets/images/${data.asset}', width: 150, height: 150),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GenzSticker(text: data.sticker),
                const SizedBox(height: 14),
                SizedBox(width: 200, child: Text(data.title, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -1.5, height: 1, fontFamily: GenzFonts.primary))),
                const SizedBox(height: 10),
                SizedBox(width: 200, child: Text(data.summary, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, height: 1.35, fontFamily: GenzFonts.primary, color: data.tone == GenzTone.blue ? Colors.white.withValues(alpha: 0.78) : GenzColors.ink.withValues(alpha: 0.62)))),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildMetricBox(context, 'logged', data.logged),
              const SizedBox(width: 10),
              _buildMetricBox(context, data.statLabel, data.statValue),
              const SizedBox(width: 10),
              _buildMetricBox(context, 'last', data.lastLogged),
            ],
          ),
          const SizedBox(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('your logs', style: GenzStyles.h2(context)),
              Text('newest first', style: TextStyle(color: GenzColors.mu(context), fontSize: 11, fontWeight: FontWeight.w700, fontFamily: GenzFonts.primary)),
            ],
          ),
          const SizedBox(height: 10),
          _buildReceiptPaper([
            _buildReceiptHeader('your logs', 'newest first'),
            for (var index = 0; index < data.receipts.length; index++)
              _buildReceiptRow(
                data.receipts[index].title,
                data.receipts[index].date,
                data.receipts[index].description,
                data.receipts[index].vibe,
                data.receipts[index].route,
                isLast: index == data.receipts.length - 1,
              ),
          ]),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () {
              if (data.isWatch) {
                widget.onNavigate('swaps');
              } else {
                showGenzToast(context, 'opens the meal logger in the app');
              }
            },
            child: _buildActionButton(data.isWatch ? 'find better swaps' : 'log this food', filled: true),
          ),
          const SizedBox(height: 26),
          Text('related pattern', style: GenzStyles.h2(context)),
          const SizedBox(height: 10),
          _buildFoodLink(context, 'pattern', data.patternLabel, data.patternId, data.patternTone, asset: data.patternAsset),
          const SizedBox(height: 26),
          _buildFootnote(context, 'based on your logs. not medical advice.'),
        ],
      ),
    );
  }

  // 7. FOOD INTELLIGENCE
  Widget _buildFoodIntel(BuildContext context) => SingleChildScrollView(
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
                      decoration: const BoxDecoration(color: GenzColors.lime, borderRadius: BorderRadius.all(Radius.circular(10))),
                      child: const Text('intelligence', style: TextStyle(color: GenzColors.ink, fontFamily: GenzFonts.primary, fontSize: 38, fontWeight: FontWeight.w900, height: 0.98, letterSpacing: -1.8)),
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
          const SizedBox(height: 14),
          if (_foodIntelSegment == 0 || _foodIntelSegment == 1) ...[
            _buildIntelCard(context, 'ginger tea', 'W', 'followed by steadier energy on 5 of 6 logs.', 'a-energy.webp', 'food-ginger-tea'),
            const SizedBox(height: 12),
            _buildIntelCard(context, 'masala oats', 'W', 'easier digestion and long-lasting fullness on 4 of 5 logs.', 'a-fullness.webp', 'food-masala-oats'),
            const SizedBox(height: 12),
          ],
          if (_foodIntelSegment == 0) ...[
            _buildIntelCard(context, 'dal khichdi', 'mid', 'no reaction on any of your 4 logs. a gentle meal for you.', 'a-digestion.webp', 'food-dal-khichdi'),
            const SizedBox(height: 12),
          ],
          if (_foodIntelSegment == 0 || _foodIntelSegment == 2) ...[
            _buildIntelCard(context, 'cold milk', 'L', 'bloating followed it within 2 hours on 3 of 4 logs.', 'a-bloating.webp', 'food-cold-milk'),
            const SizedBox(height: 12),
            _buildIntelCard(context, 'fried snacks', 'L', 'felt sluggish after 2 of 3 logs.', 'a-alert.webp', 'food-fried-snacks'),
          ],
          const SizedBox(height: 26),
          _buildFootnote(context, 'just vibes from your logs. not medical advice.'),
        ],
      ),
    );

  Widget _buildIntelSeg(int idx, String label) {
    final isSelected = _foodIntelSegment == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _foodIntelSegment = idx),
        child: Container(
          height: 42,
          decoration: BoxDecoration(color: isSelected ? GenzColors.lime : GenzColors.sf(context), borderRadius: BorderRadius.circular(100)),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: isSelected ? GenzColors.ink : GenzColors.tx(context), fontSize: 14, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary)),
        ),
      ),
    );
  }

  Widget _buildIntelCard(BuildContext context, String title, String vibe, String description, String asset, String route) {
    final badgeColor = vibe == 'W' ? GenzColors.lime : (vibe == 'mid' ? GenzColors.sf2(context) : GenzColors.orange);
    return GestureDetector(
      onTap: () => widget.onNavigate(route),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: GenzColors.sf(context), borderRadius: BorderRadius.circular(28)),
        child: Row(
          children: [
            GenzArt(asset: 'assets/images/$asset', width: 54, height: 54),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: GenzColors.tx(context), fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -0.5, fontFamily: GenzFonts.primary)),
                  const SizedBox(height: 2),
                  Text(description, style: TextStyle(color: GenzColors.mu(context), fontSize: 12.5, fontWeight: FontWeight.w700, fontFamily: GenzFonts.primary)),
                ],
              ),
            ),
            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(100)),
              child: Text(vibe, style: TextStyle(color: vibe == 'mid' ? GenzColors.tx(context) : GenzColors.ink, fontSize: 12, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary)),
            ),
          ],
        ),
      ),
    );
  }

  // 8. NEXT WEEK PLAN
  Widget _buildPlanView(BuildContext context) => SingleChildScrollView(
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
                      decoration: const BoxDecoration(color: GenzColors.lime, borderRadius: BorderRadius.all(Radius.circular(10))),
                      child: const Text('next week', style: TextStyle(color: GenzColors.ink, fontFamily: GenzFonts.primary, fontSize: 38, fontWeight: FontWeight.w900, height: 0.98, letterSpacing: -1.8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildPlanRecommendation(context, 'ginger tea at breakfast', 'it led your best days this week.', 'keep', 'a-energy.webp', GenzTone.lime),
          const SizedBox(height: 12),
          _buildPlanRecommendation(context, 'a 3-day break from cold milk', 'see whether bloating eases.', 'try', 'a-digestion.webp', GenzTone.lilac),
          const SizedBox(height: 12),
          _buildPlanRecommendation(context, 'tea after 6 PM', 'restless sleep followed it twice.', 'limit', 'a-sleep.webp', GenzTone.orange),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              final nextValue = !_allPlanAdded;
              setState(() => _allPlanAdded = nextValue);
              showGenzToast(context, nextValue ? 'locked in. you’re doing it' : 'removed from your plan');
            },
            child: _buildActionButton(_allPlanAdded ? 'all added ✓' : 'add all to my plan', filled: true, icon: LucideIcons.plus),
          ),
          const SizedBox(height: 26),
          _buildFootnote(context, 'a plan built from your own logs. not medical advice.'),
        ],
      ),
    );

  // 9. HISTORY & HISTORY DETAIL
  Widget _buildHistoryView(BuildContext context) => SingleChildScrollView(
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
                      decoration: const BoxDecoration(color: GenzColors.lime, borderRadius: BorderRadius.all(Radius.circular(10))),
                      child: const Text('history', style: TextStyle(color: GenzColors.ink, fontFamily: GenzFonts.primary, fontSize: 38, fontWeight: FontWeight.w900, height: 0.98, letterSpacing: -1.8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildHistCard(context, 'Dairy may be linked to your bloating', 'Oct 5 · 8:12 AM', '78', 'a-bloating.webp', GenzColors.lime, 'obs-dairy'),
          _buildHistCard(context, 'Ginger tea supports calmer digestion', 'Oct 4 · 7:40 PM', '74', 'a-energy.webp', GenzColors.lime, 'synergy'),
          _buildHistCard(context, 'Late dinners may be affecting your sleep', 'Oct 3 · 9:05 AM', '66', 'a-sleep.webp', GenzColors.butter, 'hist-detail'),
          _buildHistCard(context, 'Gut score analysis', 'Oct 2 · 8:30 AM', '58', 'a-digestion.webp', GenzColors.orange, 'hist-detail'),
          const SizedBox(height: 26),
          _buildFootnote(context, 'tap one to see it as it was that day.'),
        ],
      ),
    );

  Widget _buildHistCard(BuildContext context, String title, String date, String score, String asset, Color ringColor, String target) {
    final scoreValue = int.parse(score);
    return GestureDetector(
      onTap: () => widget.onNavigate(target),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: GenzColors.sf(context), borderRadius: BorderRadius.circular(28)),
        child: Row(
          children: [
            GenzArt(asset: 'assets/images/$asset', width: 56, height: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: GenzColors.tx(context), fontSize: 16, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary)),
                  const SizedBox(height: 3),
                  Text(date, style: TextStyle(color: GenzColors.mu(context), fontSize: 12.5, fontWeight: FontWeight.w700, fontFamily: GenzFonts.primary)),
                ],
              ),
            ),
            SizedBox(
              width: 54,
              height: 54,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: scoreValue / 100,
                      strokeWidth: 6,
                      backgroundColor: GenzColors.sf2(context),
                      valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: GenzColors.sf(context), shape: BoxShape.circle),
                    child: Text(score, style: TextStyle(color: GenzColors.tx(context), fontSize: 15, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryDetailView(BuildContext context) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SAVED SNAPSHOT · OCT 3', style: GenzStyles.eyebrow(context)),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: GenzStyles.h1(context),
              children: [
                const TextSpan(text: 'how things looked on '),
                WidgetSpan(
                  child: Transform.rotate(
                    angle: -0.026,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: const BoxDecoration(color: GenzColors.lime, borderRadius: BorderRadius.all(Radius.circular(10))),
                      child: const Text('oct 3', style: TextStyle(color: GenzColors.ink, fontFamily: GenzFonts.primary, fontSize: 38, fontWeight: FontWeight.w900, height: 0.98, letterSpacing: -1.8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GenzTile(
            tone: GenzTone.lilac,
            onTap: () => widget.onNavigate('score'),
            art: const Positioned(right: -12, top: 10, child: GenzArt(asset: 'assets/images/a-gauge.webp', width: 138, height: 138)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('gut score', style: TextStyle(color: GenzColors.ink.withValues(alpha: 0.62), fontFamily: GenzFonts.primary, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('66', style: GenzStyles.big),
                    Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('/100', style: TextStyle(color: GenzColors.ink.withValues(alpha: 0.6), fontSize: 24, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary))),
                  ],
                ),
                const SizedBox(height: 14),
                const GenzSticker(text: '+2 vs yesterday'),
                const SizedBox(height: 14),
                const Text('based on your logs up to this day.', style: TextStyle(color: Color(0x9E0B0B12), fontSize: 14.5, fontWeight: FontWeight.w600, fontFamily: GenzFonts.primary)),
                const SizedBox(height: 18),
                _buildSnapshotEqualizer(),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => copyGenzShare(context, text: 'Saved gut score snapshot for Oct 3: 66/100, up 2 vs yesterday.'),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(100)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.upload, size: 16, color: GenzColors.ink),
                        SizedBox(width: 6),
                        Text('share', style: TextStyle(color: GenzColors.ink, fontSize: 13, fontWeight: FontWeight.w800, fontFamily: GenzFonts.primary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text('top insight', style: GenzStyles.h2(context)),
          const SizedBox(height: 10),
          GenzTile(
            tone: GenzTone.ink,
            onTap: () => showGenzToast(context, 'opens the saved observation'),
            art: Positioned(right: -4, top: 10, child: Transform.rotate(angle: 0.14, child: const GenzArt(asset: 'assets/images/a-sleep.webp', width: 110, height: 110))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GenzSticker(text: 'top insight', tone: GenzTone.lime),
                const SizedBox(height: 14),
                const Text('late dinners might be messing with your sleep.', style: GenzStyles.title),
                const SizedBox(height: 10),
                Text('restless sleep followed dinners after 9 PM on 2 of 3 nights.', style: GenzStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.66))),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('2 of 3 days', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary)),
                    Text('low confidence', style: TextStyle(color: Colors.white.withValues(alpha: 0.66), fontSize: 13, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                _buildConfidenceDots(2, 3),
              ],
            ),
          ),
          const SizedBox(height: 26),
          _buildFootnote(context, 'snapshots keep your score window as of that date.'),
        ],
      ),
    );

  Widget _buildSnapshotEqualizer() {
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    const heights = [22.0, 8.0, 32.0, 27.0, 36.0, 40.0, 8.0];
    return SizedBox(
      height: 78,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var index = 0; index < days.length; index++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == days.length - 1 ? 0 : 7),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: double.infinity,
                      height: heights[index],
                      decoration: BoxDecoration(
                        color: index == 5
                            ? GenzColors.ink
                            : GenzColors.ink.withValues(alpha: index == 1 || index == 6 ? 0.1 : 0.2),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      days[index],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: GenzColors.ink.withValues(alpha: 0.75),
                        fontFamily: GenzFonts.primary,
                        fontFamilyFallback: GenzFonts.fallback,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSynergyDetail(BuildContext context) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GenzTile(
            tone: GenzTone.lime,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            art: Positioned(
              right: -14,
              top: 16,
              child: Transform.rotate(
                angle: 0.14,
                child: const GenzArt(asset: 'assets/images/a-energy.webp', width: 150, height: 150),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GenzSticker(text: 'insight · digestion'),
                SizedBox(height: 14),
                SizedBox(
                  width: 210,
                  child: Text('oats → steady energy', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1.5, fontFamily: GenzFonts.primary)),
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: 210,
                  child: Text('oats at breakfast lined up with steadier afternoon energy.', style: TextStyle(color: GenzColors.ink, fontSize: 14.5, fontWeight: FontWeight.w600, fontFamily: GenzFonts.primary)),
                ),
                SizedBox(height: 14),
                GenzSticker(text: '3× seen', tone: GenzTone.ink),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMetricBox(context, 'evidence', '72%'),
              const SizedBox(width: 10),
              _buildMetricBox(context, 'logged', '3×'),
              const SizedBox(width: 10),
              _buildMetricBox(context, 'positive', '3'),
            ],
          ),
          const SizedBox(height: 26),
          Text('what we noticed', style: GenzStyles.h2(context)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: GenzColors.sf(context), borderRadius: BorderRadius.circular(28)),
            child: Text(
              'oats at breakfast lined up with steadier afternoon energy in 3 logged weeks.',
              style: TextStyle(color: GenzColors.tx(context), fontSize: 15, fontWeight: FontWeight.w700, height: 1.4, fontFamily: GenzFonts.primary),
            ),
          ),
          const SizedBox(height: 26),
          Text('foods involved', style: GenzStyles.h2(context)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: GenzColors.sf(context), borderRadius: BorderRadius.circular(28)),
            child: Column(
              children: [
                _buildSynergyFoodRow(context, 'Masala oats', 'a-fullness.webp', 'food-masala-oats', isFirst: true),
                GenzDashedDivider(color: GenzColors.ln(context), thickness: 1.5),
                _buildSynergyFoodRow(context, 'Ginger tea', 'a-energy.webp', 'food-ginger-tea', isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const GenzTile(
            tone: GenzTone.butter,
            padding: EdgeInsets.all(18),
            borderRadius: 26,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GenzSticker(text: 'your next step'),
                SizedBox(height: 12),
                Text('keep oats as your default breakfast this week.', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.8, fontFamily: GenzFonts.primary)),
              ],
            ),
          ),
          const SizedBox(height: 26),
          _buildFootnote(context, 'observed from your own logs. not medical advice.'),
        ],
      ),
    );

  // 10. MEAL RECEIPT DETAILS
  Widget _buildMealReceiptDetail(BuildContext context, String mealId) {
    final data = genzMealDetails[mealId] ?? genzMealDetails['meal-paneer-pizza-+-cold-drink']!;
    final isHelpful = data.vibe == 'W';
    final isNeutral = data.vibe == 'mid';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GenzTile(
            tone: isHelpful ? GenzTone.lime : (isNeutral ? GenzTone.blue : GenzTone.pink),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            art: Positioned(
              right: -14,
              top: 16,
              child: Transform.rotate(
                angle: 0.14,
                child: GenzArt(asset: 'assets/images/${data.asset}', width: 130, height: 130),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GenzSticker(text: data.vibe),
                const SizedBox(height: 14),
                SizedBox(
                  width: 210,
                  child: Text(data.mealName.toLowerCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.3, fontFamily: GenzFonts.primary)),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 210,
                  child: Text(data.date.toLowerCase(), style: TextStyle(color: GenzColors.ink.withValues(alpha: 0.62), fontSize: 14.5, fontWeight: FontWeight.w600, fontFamily: GenzFonts.primary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildReceiptPaper([
            _buildReceiptHeader('what happened', 'from your log'),
            _buildMealTimelineRow(context, 'mid', data.date, data.mealName, 'Meal logged'),
            GenzDashedDivider(color: GenzColors.ink.withValues(alpha: 0.16), thickness: 2, dashWidth: 5, gap: 4),
            _buildMealTimelineRow(context, data.reactionVibe, 'Afterwards', 'Reaction', data.reaction),
          ]),
          if (data.foodId != null) ...[
            const SizedBox(height: 26),
            Text('food', style: GenzStyles.h2(context)),
            const SizedBox(height: 10),
            _buildFoodLink(context, 'food', data.mealName, data.foodId!, data.foodTone, asset: data.foodAsset),
          ],
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () => showGenzToast(context, 'opens the log editor in the app'),
            child: _buildActionButton('edit this log', filled: false),
          ),
          const SizedBox(height: 26),
          _buildFootnote(context, 'based on what you logged. not medical advice.'),
        ],
      ),
    );
  }

  Widget _buildMealTimelineRow(BuildContext context, String vibe, String date, String title, String description) {
    final helpful = vibe == 'W';
    final neutral = vibe == 'mid';
    final background = helpful ? GenzColors.lime : (neutral ? const Color(0x140B0B12) : GenzColors.orange);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(100)),
            child: Text(vibe, style: const TextStyle(color: GenzColors.ink, fontSize: 12, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date.toUpperCase(), style: TextStyle(color: GenzColors.ink.withValues(alpha: 0.5), fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1, fontFamily: GenzFonts.primary)),
                const SizedBox(height: 2),
                Text(title, style: const TextStyle(color: GenzColors.ink, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary)),
                if (description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(description, style: TextStyle(color: GenzColors.ink.withValues(alpha: 0.62), fontSize: 13, fontWeight: FontWeight.w600, fontFamily: GenzFonts.primary)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // SHARED DETAIL HELPERS
  Widget _buildScoreFactor(BuildContext context, String label, int score, String detail) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: TextStyle(color: GenzColors.tx(context), fontSize: 15, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary)),
                Text('$score', style: TextStyle(color: GenzColors.tx(context), fontSize: 15, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 16,
                backgroundColor: GenzColors.sf2(context),
                valueColor: const AlwaysStoppedAnimation<Color>(GenzColors.lime),
              ),
            ),
            const SizedBox(height: 6),
            Text(detail, style: TextStyle(color: GenzColors.mu(context), fontSize: 12.5, fontWeight: FontWeight.w600, fontFamily: GenzFonts.primary)),
          ],
        ),
      );

  Widget _buildScoreMover(BuildContext context, String amount, String title, bool helpful, {bool isFirst = false, bool isLast = false}) => Column(
        children: [
          if (!isFirst) GenzDashedDivider(color: GenzColors.ln(context), thickness: 1.5),
          Padding(
            padding: EdgeInsets.only(top: isFirst ? 0 : 12, bottom: isLast ? 0 : 12),
            child: Row(
              children: [
                Container(
                  constraints: const BoxConstraints(minWidth: 44),
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: helpful ? GenzColors.lime : GenzColors.orange, borderRadius: BorderRadius.circular(100)),
                  child: Text(amount, style: const TextStyle(color: GenzColors.ink, fontSize: 12, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: TextStyle(color: GenzColors.tx(context), fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: -0.4, fontFamily: GenzFonts.primary))),
              ],
            ),
          ),
        ],
      );

  Widget _buildMetricBox(BuildContext context, String label, String value) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(color: GenzColors.sf(context), borderRadius: BorderRadius.circular(22)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: TextStyle(color: GenzColors.mu(context), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1, fontFamily: GenzFonts.primary)),
              const SizedBox(height: 6),
              Text(value, style: TextStyle(color: GenzColors.tx(context), fontSize: 23, fontWeight: FontWeight.w900, letterSpacing: -1, fontFamily: GenzFonts.primary)),
            ],
          ),
        ),
      );

  Widget _buildConfidenceDots(int filled, int total) => Row(
        children: [
          for (var index = 0; index < total; index++)
            Expanded(
              child: Container(
                height: 10,
                margin: EdgeInsets.only(right: index == total - 1 ? 0 : 6),
                decoration: BoxDecoration(
                  color: index < filled ? GenzColors.lime : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
        ],
      );

  Widget _buildTips(List<String> tips) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: GenzColors.sf(context), borderRadius: BorderRadius.circular(28)),
        child: Column(
          children: [
            for (var index = 0; index < tips.length; index++) ...[
              if (index > 0) GenzDashedDivider(color: GenzColors.ln(context), thickness: 1.5),
              Padding(
                padding: EdgeInsets.only(top: index == 0 ? 0 : 12, bottom: index == tips.length - 1 ? 0 : 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: GenzColors.lime, borderRadius: BorderRadius.circular(10)),
                      child: Text('${index + 1}', style: const TextStyle(color: GenzColors.ink, fontSize: 13, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(tips[index], style: TextStyle(color: GenzColors.tx(context), fontSize: 15, fontWeight: FontWeight.w700, height: 1.35, fontFamily: GenzFonts.primary))),
                  ],
                ),
              ),
            ],
          ],
        ),
      );

  Widget _buildActionButton(String label, {required bool filled, IconData icon = LucideIcons.arrowRight}) => Container(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          color: filled ? GenzColors.lime : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: filled ? null : Border.all(color: GenzColors.ln(context), width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(color: filled ? GenzColors.ink : GenzColors.tx(context), fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3, fontFamily: GenzFonts.primary)),
            if (filled) ...[
              const SizedBox(width: 8),
              Icon(icon, color: GenzColors.ink, size: 18),
            ],
          ],
        ),
      );

  Widget _buildDarkAction(String label) => Container(
        height: 48,
        width: double.infinity,
        decoration: BoxDecoration(color: GenzColors.ink, borderRadius: BorderRadius.circular(100)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary)),
            const SizedBox(width: 8),
            const Icon(LucideIcons.arrowRight, color: Colors.white, size: 18),
          ],
        ),
      );

  Widget _buildPlanRecommendation(BuildContext context, String title, String description, String label, String asset, GenzTone tone) => GenzTile(
        tone: tone,
        padding: const EdgeInsets.all(16),
        borderRadius: 26,
        child: Row(
          children: [
            GenzArt(asset: 'assets/images/$asset', width: 62, height: 62),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: -0.8, fontFamily: GenzFonts.primary)),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(color: GenzColors.ink.withValues(alpha: 0.62), fontSize: 13, fontWeight: FontWeight.w600, height: 1.35, fontFamily: GenzFonts.primary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GenzSticker(text: label, angle: 0.052),
          ],
        ),
      );

  Widget _buildFoodLink(BuildContext context, String eyebrow, String title, String target, GenzTone tone, {required String asset}) => GenzTile(
        tone: tone,
        onTap: () => widget.onNavigate(target),
        padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
        borderRadius: 26,
        child: Row(
          children: [
            GenzArt(asset: 'assets/images/$asset', width: 56, height: 56),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(eyebrow, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.1, color: _detailToneForeground(tone).withValues(alpha: 0.6), fontFamily: GenzFonts.primary)),
                  const SizedBox(height: 2),
                  Text(title, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: -0.6, color: _detailToneForeground(tone), fontFamily: GenzFonts.primary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: _detailToneForeground(tone), shape: BoxShape.circle),
              child: Icon(LucideIcons.arrowUpRight, color: _detailToneBackground(tone), size: 18),
            ),
          ],
        ),
      );

  Widget _buildSynergyFoodRow(BuildContext context, String title, String asset, String target, {bool isFirst = false, bool isLast = false}) => GestureDetector(
        onTap: () => widget.onNavigate(target),
        child: Padding(
          padding: EdgeInsets.only(top: isFirst ? 0 : 12, bottom: isLast ? 0 : 12),
          child: Row(
            children: [
              GenzArt(asset: 'assets/images/$asset', width: 40, height: 40),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: TextStyle(color: GenzColors.tx(context), fontSize: 16, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary))),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: GenzColors.lime, shape: BoxShape.circle),
                child: const Icon(LucideIcons.arrowUpRight, color: GenzColors.ink, size: 18),
              ),
            ],
          ),
        ),
      );

  Widget _buildFootnote(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Center(
          child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: GenzColors.mu(context), fontSize: 12, fontWeight: FontWeight.w700, fontFamily: GenzFonts.primary)),
        ),
      );

  Color _detailToneBackground(GenzTone tone) => switch (tone) {
        GenzTone.lime => GenzColors.lime,
        GenzTone.pink => GenzColors.pink,
        GenzTone.blue => GenzColors.blue,
        GenzTone.orange => GenzColors.orange,
        GenzTone.lilac => GenzColors.lilac,
        GenzTone.butter => GenzColors.butter,
        GenzTone.ink => GenzColors.lime,
      };

  Color _detailToneForeground(GenzTone tone) => tone == GenzTone.blue || tone == GenzTone.ink ? Colors.white : GenzColors.ink;

  // Shared presentation helpers.
  Widget _buildSwapRow(BuildContext context, String badge, String title, String subtitle, String asset, String target, {bool best = false}) => GestureDetector(
      onTap: () => widget.onNavigate(target),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: GenzColors.sf(context), borderRadius: BorderRadius.circular(28)),
        child: Row(
          children: [
            GenzArt(asset: 'assets/images/$asset', width: 62, height: 62),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.rotate(
                    angle: -0.035,
                    alignment: Alignment.centerLeft,
                    child: GenzSticker(text: badge, tone: best ? GenzTone.lime : null, angle: 0),
                  ),
                  const SizedBox(height: 8),
                  Text(title, style: TextStyle(color: GenzColors.tx(context), fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.6, height: 1.1, fontFamily: GenzFonts.primary)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: TextStyle(color: GenzColors.mu(context), fontSize: 12.5, fontWeight: FontWeight.w700, fontFamily: GenzFonts.primary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: GenzColors.lime, shape: BoxShape.circle),
              child: const Icon(LucideIcons.arrowUpRight, color: GenzColors.ink, size: 16),
            ),
          ],
        ),
      ),
    );

  Widget _buildReceiptPaper(List<Widget> children) => PhysicalShape(
        clipper: const GenzReceiptClipper(),
        color: GenzColors.paper,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 26),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      );

  Widget _buildReceiptHeader(String leading, String trailing) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(leading.toUpperCase(), style: const TextStyle(color: GenzColors.ink, fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 1.4, fontFamily: GenzFonts.primary)),
                Text(trailing.toUpperCase(), style: const TextStyle(color: GenzColors.ink, fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 1.4, fontFamily: GenzFonts.primary)),
              ],
            ),
          ),
          GenzDashedDivider(color: GenzColors.ink.withValues(alpha: 0.25), thickness: 2, dashWidth: 5, gap: 4),
        ],
      );

  Widget _buildReceiptRow(String title, String date, String desc, String vibe, String route, {bool isLast = false}) {
    final displayVibe = vibe == 'watch' ? 'L' : (vibe == 'helpful' ? 'W' : vibe);
    final badgeColor = displayVibe == 'W' ? GenzColors.lime : (displayVibe == 'mid' ? const Color(0x140B0B12) : GenzColors.orange);
    return Column(
      children: [
        GestureDetector(
          onTap: () => widget.onNavigate(route),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(100)),
                  child: Text(displayVibe, style: const TextStyle(color: GenzColors.ink, fontSize: 12, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(date.toUpperCase(), style: const TextStyle(color: Color(0x800B0B12), fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1, fontFamily: GenzFonts.primary)),
                      const SizedBox(height: 2),
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.4, color: GenzColors.ink, fontFamily: GenzFonts.primary)),
                      const SizedBox(height: 2),
                      Text(desc, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0x9E0B0B12), fontFamily: GenzFonts.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isLast) GenzDashedDivider(color: GenzColors.ink.withValues(alpha: 0.16), thickness: 2, dashWidth: 5, gap: 4),
      ],
    );
  }

  Widget _buildEq() => SizedBox(
        height: 78,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildEqBar('S', 40),
            _buildEqBar('M', 8, isZero: true),
            _buildEqBar('T', 55),
            _buildEqBar('W', 60),
            _buildEqBar('T', 50),
            _buildEqBar('F', 65),
            _buildEqBar('S', 75, isHi: true, isLast: true),
          ],
        ),
      );

  Widget _buildEqBar(String day, double height, {bool isZero = false, bool isHi = false, bool isLast = false}) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: isLast ? 0 : 7),
          child: SizedBox(
            height: 78,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 19,
                  child: Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: isHi ? GenzColors.lime : Colors.white.withValues(alpha: isZero ? 0.1 : 0.28),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 13,
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.75),
                        fontFamily: GenzFonts.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
