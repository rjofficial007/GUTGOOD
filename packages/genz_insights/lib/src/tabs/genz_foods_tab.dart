import 'package:flutter/material.dart';
import 'package:genz_insights/src/genz_theme.dart';
import 'package:genz_insights/src/widgets/genz_primitives.dart';
import 'package:genz_insights/src/widgets/genz_share.dart';
import 'package:genz_insights/src/widgets/genz_tile.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class GenzFoodsTab extends StatefulWidget {
  const GenzFoodsTab({super.key, required this.onNavigate});

  final ValueChanged<String> onNavigate;

  @override
  State<GenzFoodsTab> createState() => _GenzFoodsTabState();
}

class _GenzFoodsTabState extends State<GenzFoodsTab> {
  final List<bool> _questDone = [true, false, false];

  int get _completedQuests => _questDone.where((done) => done).length;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LAST 14 DAYS', style: GenzStyles.eyebrow(context)),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: GenzStyles.h1(context),
              children: [
                const TextSpan(text: 'how your food '),
                WidgetSpan(
                  child: Transform.rotate(
                    angle: -0.026,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: const BoxDecoration(
                        color: GenzColors.lime,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: const Text(
                        'hits',
                        style: TextStyle(
                          color: GenzColors.ink,
                          fontFamily: GenzFonts.primary,
                          fontFamilyFallback: GenzFonts.fallback,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          height: 0.98,
                          letterSpacing: -1.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GenzTile(
            tone: GenzTone.ink,
            onTap: () => widget.onNavigate('food-intel'),
            art: Positioned(
              right: -8,
              top: 8,
              child: Transform.rotate(
                angle: 0.14,
                child: const GenzArt(asset: 'assets/images/a-bowl.webp', width: 120, height: 120),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GenzSticker(text: 'vibe check', tone: GenzTone.lime),
                const SizedBox(height: 14),
                const Text(
                  '55%',
                  style: TextStyle(
                    fontSize: 92,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -6,
                    height: 0.82,
                    fontFamily: GenzFonts.primary,
                    fontFamilyFallback: GenzFonts.fallback,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                      fontFamily: GenzFonts.primary,
                      fontFamilyFallback: GenzFonts.fallback,
                      color: Colors.white,
                    ),
                    children: [
                      TextSpan(text: 'of your foods are '),
                      TextSpan(text: 'helpful', style: TextStyle(color: GenzColors.lime)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '11 of 20 foods agreed with your gut.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.66),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    fontFamily: GenzFonts.primary,
                    fontFamilyFallback: GenzFonts.fallback,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 18, bottom: 14),
                  child: Container(
                    height: 22,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(100)),
                    child: Row(
                      children: [
                        Expanded(flex: 55, child: Container(color: GenzColors.lime)),
                        const SizedBox(width: 3),
                        Expanded(flex: 20, child: Container(color: const Color(0xFF8E8EA3))),
                        const SizedBox(width: 3),
                        Expanded(flex: 25, child: Container(color: GenzColors.orange)),
                      ],
                    ),
                  ),
                ),
                _buildLegendRow(context, GenzColors.lime, 'helpful', '55%', '11 foods'),
                const SizedBox(height: 8),
                _buildLegendRow(context, const Color(0xFF8E8EA3), 'neutral', '20%', '4 foods'),
                const SizedBox(height: 8),
                _buildLegendRow(context, GenzColors.orange, 'watch', '25%', '5 foods'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GenzTile(
            tone: GenzTone.orange,
            onTap: () => widget.onNavigate('swaps'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GenzSticker(text: 'swap alert'),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final gap = constraints.maxWidth < 200 ? 4.0 : 6.0;
                    final arrowSize = constraints.maxWidth < 180 ? 36.0 : 44.0;
                    final artSize = ((constraints.maxWidth - arrowSize - gap * 2) / 2)
                        .clamp(24.0, 92.0)
                        .toDouble();
                    return Row(
                      children: [
                        GenzArt(asset: 'assets/images/a-bloating.webp', width: artSize, height: artSize),
                        SizedBox(width: gap),
                        Container(
                          width: arrowSize,
                          height: arrowSize,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: GenzColors.ink),
                          child: Icon(LucideIcons.arrowRight, color: GenzColors.orange, size: arrowSize * 0.45),
                        ),
                        SizedBox(width: gap),
                        GenzArt(asset: 'assets/images/a-energy.webp', width: artSize, height: artSize),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                const Text('swap cold milk for ginger tea', style: GenzStyles.title),
                const SizedBox(height: 8),
                Text(
                  'ginger tea → steadier energy. cold milk → bloating.',
                  style: TextStyle(
                    color: GenzColors.ink.withValues(alpha: 0.62),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    fontFamily: GenzFonts.primary,
                    fontFamilyFallback: GenzFonts.fallback,
                  ),
                ),
                const SizedBox(height: 16),
                _darkButton('find better swaps'),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text('helps vs watch', style: GenzStyles.h2(context)),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildSignalCard(
                    title: 'helps',
                    tone: GenzTone.lime,
                    asset: 'a-trophy.webp',
                    entries: const [
                      _FoodSignal('Ginger tea', 'steadier energy', 'food-ginger-tea'),
                      _FoodSignal('Masala oats', 'easier digestion', 'food-masala-oats'),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSignalCard(
                    title: 'watch',
                    tone: GenzTone.pink,
                    asset: 'a-alert.webp',
                    entries: const [
                      _FoodSignal('Cold milk', 'bloating', 'food-cold-milk'),
                      _FoodSignal('Fried snacks', 'sluggish', 'food-fried-snacks'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('the leaderboard', style: GenzStyles.h2(context)),
              Text(
                'ranked by gut effect',
                style: TextStyle(color: GenzColors.mu(context), fontSize: 11, fontWeight: FontWeight.w700, fontFamily: GenzFonts.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildLeaderboard(),
          const SizedBox(height: 26),
          Text('receipts', style: GenzStyles.h2(context)),
          const SizedBox(height: 10),
          _buildRecentImpacts(),
          const SizedBox(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('side quests', style: GenzStyles.h2(context)),
              Text('next steps', style: TextStyle(color: GenzColors.mu(context), fontSize: 11, fontWeight: FontWeight.w700, fontFamily: GenzFonts.primary)),
            ],
          ),
          const SizedBox(height: 10),
          _buildQuests(),
          const SizedBox(height: 26),
          _buildFootnote(context),
          const SizedBox(height: 8),
        ],
      ),
    );

  Widget _buildSignalCard({
    required String title,
    required GenzTone tone,
    required String asset,
    required List<_FoodSignal> entries,
  }) => GenzTile(
        tone: tone,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GenzArt(asset: 'assets/images/$asset', width: 56, height: 56),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: GenzColors.ink, fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: -0.8, fontFamily: GenzFonts.primary)),
            const SizedBox(height: 12),
            for (final entry in entries) ...[
              GenzDashedDivider(color: GenzColors.ink.withValues(alpha: 0.25), thickness: 1.5, dashWidth: 5, gap: 4),
              GestureDetector(
                onTap: () => widget.onNavigate(entry.route),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.name, style: const TextStyle(color: GenzColors.ink, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: -0.3, fontFamily: GenzFonts.primary)),
                      Text(entry.effect, style: TextStyle(color: GenzColors.ink.withValues(alpha: 0.68), fontSize: 12.5, fontWeight: FontWeight.w700, fontFamily: GenzFonts.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );

  Widget _buildLeaderboard() {
    const rows = [
      _LeaderboardEntry('1', 'Ginger tea', 'logged 6× · steadier energy', 'W', 'food-ginger-tea'),
      _LeaderboardEntry('2', 'Masala oats', 'logged 5× · easier digestion', 'W', 'food-masala-oats'),
      _LeaderboardEntry('3', 'Dal khichdi', 'logged 4× · no reaction', 'mid', 'food-dal-khichdi'),
      _LeaderboardEntry('4', 'Cold milk', 'logged 4× · bloating', 'L', 'food-cold-milk'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: GenzColors.sf(context), borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++)
            GestureDetector(
              onTap: () => widget.onNavigate(rows[index].route),
              child: Column(
                children: [
                  if (index > 0) GenzDashedDivider(color: GenzColors.ln(context), thickness: 1.5),
                  Padding(
                    padding: EdgeInsets.only(top: index == 0 ? 0 : 12, bottom: index == rows.length - 1 ? 0 : 12),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(color: GenzColors.sf2(context), borderRadius: BorderRadius.circular(12)),
                          alignment: Alignment.center,
                          child: Text(rows[index].rank, style: TextStyle(color: GenzColors.tx(context), fontSize: 15, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(rows[index].name, style: TextStyle(color: GenzColors.tx(context), fontSize: 16, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary)),
                              const SizedBox(height: 2),
                              Text(rows[index].detail, style: TextStyle(color: GenzColors.mu(context), fontSize: 12.5, fontWeight: FontWeight.w600, fontFamily: GenzFonts.primary)),
                            ],
                          ),
                        ),
                        _vibeBadge(rows[index].vibe),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentImpacts() {
    const rows = [
      _ImpactEntry('mid', 'Today · 1:20 PM', 'Dal khichdi', 'No reaction after 3 hours', 'meal-dal-khichdi'),
      _ImpactEntry('L', 'Yesterday · 9:10 PM', 'Cold milk', 'Bloating after about 90 minutes', 'meal-cold-milk'),
      _ImpactEntry('W', 'Oct 3 · 8:05 AM', 'Ginger tea', 'Steady energy through the morning', 'meal-ginger-tea'),
    ];
    return PhysicalShape(
      clipper: const GenzReceiptClipper(),
      color: GenzColors.paper,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 26),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('RECENT IMPACTS', style: TextStyle(color: GenzColors.ink, fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 1.4, fontFamily: GenzFonts.primary)),
                  Text('LAST 3 DAYS', style: TextStyle(color: GenzColors.ink, fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 1.4, fontFamily: GenzFonts.primary)),
                ],
              ),
            ),
            GenzDashedDivider(color: GenzColors.ink.withValues(alpha: 0.25), thickness: 2, dashWidth: 5, gap: 4),
            for (var index = 0; index < rows.length; index++)
              GestureDetector(
                onTap: () => widget.onNavigate(rows[index].route),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(padding: const EdgeInsets.only(top: 2), child: _vibeBadge(rows[index].vibe, onPaper: true)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(rows[index].date.toUpperCase(), style: TextStyle(color: GenzColors.ink.withValues(alpha: 0.5), fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1, fontFamily: GenzFonts.primary)),
                                const SizedBox(height: 2),
                                Text(rows[index].food, style: const TextStyle(color: GenzColors.ink, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.4, fontFamily: GenzFonts.primary)),
                                const SizedBox(height: 2),
                                Text(rows[index].reaction, style: TextStyle(color: GenzColors.ink.withValues(alpha: 0.62), fontSize: 13, fontWeight: FontWeight.w600, fontFamily: GenzFonts.primary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (index < rows.length - 1)
                      GenzDashedDivider(color: GenzColors.ink.withValues(alpha: 0.16), thickness: 2, dashWidth: 5, gap: 4),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuests() {
    final xp = _completedQuests * 10;
    return Container(
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
                  Text('next steps', style: TextStyle(color: GenzColors.tx(context), fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: -0.6, fontFamily: GenzFonts.primary)),
                  Text('$_completedQuests of 3 done', style: TextStyle(color: GenzColors.mu(context), fontSize: 13, fontWeight: FontWeight.w700, fontFamily: GenzFonts.primary)),
                ],
              ),
              GenzSticker(text: '$xp xp', tone: GenzTone.ink, angle: 0.05),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: _completedQuests / 3,
              minHeight: 12,
              backgroundColor: GenzColors.sf2(context),
              valueColor: const AlwaysStoppedAnimation<Color>(GenzColors.lime),
            ),
          ),
          const SizedBox(height: 6),
          _buildQuestRow(0, 'log your lunch today'),
          GenzDashedDivider(color: GenzColors.ln(context), thickness: 1.5),
          _buildQuestRow(1, 'try ginger tea instead of cold milk'),
          GenzDashedDivider(color: GenzColors.ln(context), thickness: 1.5),
          _buildQuestRow(2, 'note any symptoms after dinner'),
        ],
      ),
    );
  }

  Widget _buildQuestRow(int index, String title) {
    final done = _questDone[index];
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        final wasDone = _questDone[index];
        setState(() => _questDone[index] = !wasDone);
        if (!wasDone && _completedQuests == _questDone.length) {
          showGenzToast(context, 'quest cleared. +${_questDone.length * 10} xp');
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
                color: done ? GenzColors.lime : GenzColors.sf2(context),
                border: done ? null : Border.all(color: GenzColors.mu(context), width: 2.5),
              ),
              child: done ? const Icon(LucideIcons.check, size: 16, color: GenzColors.ink) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: done ? GenzColors.mu(context) : GenzColors.tx(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  decoration: done ? TextDecoration.lineThrough : null,
                  fontFamily: GenzFonts.primary,
                  fontFamilyFallback: GenzFonts.fallback,
                ),
              ),
            ),
            Text('+10 xp', style: TextStyle(color: done ? GenzColors.lime : GenzColors.mu(context), fontSize: 12, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendRow(BuildContext context, Color color, String label, String pct, String count) => Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, fontFamily: GenzFonts.primary, color: Colors.white))),
        Text(pct, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, fontFamily: GenzFonts.primary, color: Colors.white)),
        SizedBox(
          width: 56,
          child: Text(count, textAlign: TextAlign.right, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, fontFamily: GenzFonts.primary, color: GenzColors.mu(context))),
        ),
      ],
    );

  Widget _darkButton(String text) => Container(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(color: GenzColors.ink, borderRadius: BorderRadius.circular(100)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3, fontFamily: GenzFonts.primary)),
            const SizedBox(width: 8),
            const Icon(LucideIcons.arrowRight, color: Colors.white, size: 20),
          ],
        ),
      );

  Widget _vibeBadge(String value, {bool onPaper = false}) {
    final isHelpful = value == 'W';
    final isWatch = value == 'L';
    final background = isHelpful
        ? GenzColors.lime
        : (isWatch
            ? GenzColors.orange
            : (onPaper ? const Color(0x140B0B12) : GenzColors.sf2(context)));
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(100)),
      child: Text(
        value,
        style: TextStyle(
          color: value == 'mid' && !onPaper ? GenzColors.tx(context) : GenzColors.ink,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          fontFamily: GenzFonts.primary,
          fontFamilyFallback: GenzFonts.fallback,
        ),
      ),
    );
  }

  Widget _buildFootnote(BuildContext context) => Center(
        child: Text('just vibes from your logs. not medical advice.', style: TextStyle(color: GenzColors.mu(context), fontSize: 12, fontWeight: FontWeight.w700, fontFamily: GenzFonts.primary)),
      );
}

class _FoodSignal {
  const _FoodSignal(this.name, this.effect, this.route);
  final String name;
  final String effect;
  final String route;
}

class _LeaderboardEntry {
  const _LeaderboardEntry(this.rank, this.name, this.detail, this.vibe, this.route);
  final String rank;
  final String name;
  final String detail;
  final String vibe;
  final String route;
}

class _ImpactEntry {
  const _ImpactEntry(this.vibe, this.date, this.food, this.reaction, this.route);
  final String vibe;
  final String date;
  final String food;
  final String reaction;
  final String route;
}
