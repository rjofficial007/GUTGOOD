import 'package:flutter/material.dart';
import 'package:genz_insights/src/genz_theme.dart';
import 'package:genz_insights/src/widgets/genz_primitives.dart';
import 'package:genz_insights/src/widgets/genz_share.dart';
import 'package:genz_insights/src/widgets/genz_tile.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class GenzRecapTab extends StatelessWidget {
  const GenzRecapTab({super.key, required this.onNavigate, required this.onPlayRecap});

  final ValueChanged<String> onNavigate;
  final VoidCallback onPlayRecap;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SEP 27 – OCT 3', style: GenzStyles.eyebrow(context)),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            style: GenzStyles.h1(context),
            children: [
              const TextSpan(text: 'your week, '),
              WidgetSpan(
                child: Transform.rotate(
                  angle: -0.026,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: const BoxDecoration(color: GenzColors.lime, borderRadius: BorderRadius.all(Radius.circular(10))),
                    child: const Text(
                      'wrapped',
                      style: TextStyle(color: GenzColors.ink, fontFamily: GenzFonts.primary, fontSize: 38, fontWeight: FontWeight.w900, height: 0.98, letterSpacing: -1.8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GenzTile(
          tone: GenzTone.blue,
          onTap: () => onNavigate('score'),
          art: Positioned(
            right: -8,
            top: 8,
            child: Transform.rotate(angle: 0.14, child: const GenzArt(asset: 'assets/images/a-calendar.webp', width: 120, height: 120)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'weekly average',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontFamily: GenzFonts.primary, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.2),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '74',
                    style: TextStyle(fontSize: 104, fontWeight: FontWeight.w900, letterSpacing: -6, height: 0.82, fontFamily: GenzFonts.primary, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Text(
                      '/100',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 24, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const GenzSticker(text: '+3 vs last week', tone: GenzTone.lime),
              const SizedBox(height: 20),
              _buildEqualizer(),
              const SizedBox(height: 16),
              Row(
                children: [
                  GestureDetector(
                    onTap: onPlayRecap,
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      decoration: BoxDecoration(color: GenzColors.lime, borderRadius: BorderRadius.circular(100)),
                      child: const Row(
                        children: [
                          Icon(LucideIcons.play, size: 16, color: GenzColors.ink),
                          SizedBox(width: 6),
                          Text(
                            'play recap',
                            style: TextStyle(color: GenzColors.ink, fontSize: 13, fontWeight: FontWeight.w800, fontFamily: GenzFonts.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => copyGenzShare(context, text: 'Your week, wrapped: gut score 74, up 3 vs last week.'),
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(100)),
                      child: const Row(
                        children: [
                          Icon(LucideIcons.upload, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'share',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, fontFamily: GenzFonts.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatTile(context, GenzTone.butter, 'a-trophy.webp', 'best day', 'wed', 'score 84'),
            const SizedBox(width: 10),
            _buildStatTile(context, GenzTone.lime, 'a-bowl.webp', 'foods', '27', 'meals + scans'),
            const SizedBox(width: 10),
            _buildStatTile(context, GenzTone.lilac, 'a-sprout.webp', 'evidence', '32', 'entries'),
          ],
        ),
        const SizedBox(height: 26),
        Text('highlights', style: GenzStyles.h2(context)),
        const SizedBox(height: 10),
        _buildHighlights(context),
        const SizedBox(height: 26),
        Text('healing + triggers', style: GenzStyles.h2(context)),
        const SizedBox(height: 10),
        _buildHealingAndTriggers(context),
        const SizedBox(height: 12),
        GenzTile(
          tone: GenzTone.lilac,
          onTap: () => onNavigate('plan'),
          art: Positioned(
            right: -6,
            top: 12,
            child: Transform.rotate(angle: 0.14, child: const GenzArt(asset: 'assets/images/a-quote.webp', width: 110, height: 110)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GenzSticker(text: 'weekly insight'),
              const SizedBox(height: 14),
              const Text(
                'your best days started with a light, warm breakfast.',
                style: TextStyle(fontSize: 31, fontWeight: FontWeight.w900, letterSpacing: -1.3, height: 1, fontFamily: GenzFonts.primary, fontFamilyFallback: GenzFonts.fallback),
              ),
              const SizedBox(height: 12),
              Text(
                'wednesday’s oats and ginger tea led your week at 84.',
                style: TextStyle(color: GenzColors.ink.withValues(alpha: 0.66), fontSize: 14.5, fontWeight: FontWeight.w600, fontFamily: GenzFonts.primary),
              ),
              const SizedBox(height: 18),
              SizedBox(width: 240, child: _buildDarkAction('plan next week')),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Center(
          child: Text(
            'just vibes from your logs. not medical advice.',
            style: TextStyle(color: GenzColors.mu(context), fontSize: 12, fontWeight: FontWeight.w700, fontFamily: GenzFonts.primary),
          ),
        ),
        const SizedBox(height: 8),
      ],
    ),
  );

  Widget _buildHighlights(BuildContext context) {
    const rows = [
      _RecapHighlight('1', 'Ginger tea', 'most helpful food', '4×', 'food-ginger-tea', GenzTone.lime),
      _RecapHighlight('2', 'Cold milk', 'top trigger', '3×', 'food-cold-milk', GenzTone.orange),
      _RecapHighlight('3', 'Wednesday', 'most logged day', '9 entries', null, null),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: GenzColors.sf(context), borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++)
            GestureDetector(
              onTap: rows[index].route == null ? null : () => onNavigate(rows[index].route!),
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
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: GenzColors.sf2(context), borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            rows[index].rank,
                            style: TextStyle(color: GenzColors.tx(context), fontSize: 15, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rows[index].title,
                                style: TextStyle(color: GenzColors.tx(context), fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.4, fontFamily: GenzFonts.primary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                rows[index].subtitle,
                                style: TextStyle(color: GenzColors.mu(context), fontSize: 12.5, fontWeight: FontWeight.w600, fontFamily: GenzFonts.primary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 28,
                          padding: const EdgeInsets.symmetric(horizontal: 11),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: rows[index].tone == GenzTone.lime ? GenzColors.lime : (rows[index].tone == GenzTone.orange ? GenzColors.orange : GenzColors.sf2(context)),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            rows[index].value,
                            style: TextStyle(
                              color: rows[index].tone == null ? GenzColors.tx(context) : GenzColors.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              fontFamily: GenzFonts.primary,
                              fontFamilyFallback: GenzFonts.fallback,
                            ),
                          ),
                        ),
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

  Widget _buildHealingAndTriggers(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _buildSummaryCard(
            context,
            title: 'helps',
            tone: GenzTone.lime,
            asset: 'a-trophy.webp',
            entries: const [_RecapFood('Ginger tea', '4 good days'), _RecapFood('Masala oats', '3 good days')],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(context, title: 'watch', tone: GenzTone.pink, asset: 'a-alert.webp', entries: const [_RecapFood('Cold milk', '3 receipts')]),
        ),
      ],
    ),
  );

  Widget _buildSummaryCard(BuildContext context, {required String title, required GenzTone tone, required String asset, required List<_RecapFood> entries}) => GenzTile(
    tone: tone,
    padding: const EdgeInsets.all(16),
    borderRadius: 30,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GenzArt(asset: 'assets/images/$asset', width: 52, height: 52),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(color: GenzColors.ink, fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: -0.8, fontFamily: GenzFonts.primary),
        ),
        const SizedBox(height: 10),
        for (var index = 0; index < entries.length; index++) ...[
          GenzDashedDivider(color: GenzColors.ink.withValues(alpha: 0.25), thickness: 1.5, dashWidth: 5, gap: 4),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entries[index].food,
                  style: const TextStyle(color: GenzColors.ink, fontSize: 15, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary),
                ),
                Text(
                  entries[index].detail,
                  style: TextStyle(color: GenzColors.ink.withValues(alpha: 0.68), fontSize: 12.5, fontWeight: FontWeight.w700, fontFamily: GenzFonts.primary),
                ),
              ],
            ),
          ),
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
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary),
        ),
        const SizedBox(width: 8),
        const Icon(LucideIcons.arrowRight, color: Colors.white, size: 18),
      ],
    ),
  );

  Widget _buildStatTile(BuildContext context, GenzTone tone, String asset, String eyebrow, String value, String cap) => Expanded(
    child: GenzTile(
      tone: tone,
      height: 176,
      padding: const EdgeInsets.all(14),
      borderRadius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GenzArt(asset: 'assets/images/$asset', width: 50, height: 50),
          const SizedBox(height: 10),
          Text(
            eyebrow,
            style: TextStyle(color: GenzColors.ink.withValues(alpha: 0.62), fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.2, fontFamily: GenzFonts.primary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(color: GenzColors.ink, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -1.2, height: 1.05, fontFamily: GenzFonts.primary),
          ),
          const SizedBox(height: 2),
          Text(
            cap,
            style: TextStyle(color: GenzColors.ink.withValues(alpha: 0.62), fontSize: 12, fontWeight: FontWeight.w600, fontFamily: GenzFonts.primary),
          ),
        ],
      ),
    ),
  );

  Widget _buildEqualizer() => SizedBox(
    height: 78,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [_buildEqBar('S', 55), _buildEqBar('M', 60), _buildEqBar('T', 50), _buildEqBar('W', 80, isHi: true), _buildEqBar('T', 75), _buildEqBar('F', 70), _buildEqBar('S', 55, isLast: true)],
    ),
  );

  Widget _buildEqBar(String day, double height, {bool isHi = false, bool isLast = false}) => Expanded(
    child: Padding(
      padding: EdgeInsets.only(right: isLast ? 0 : 7),
      child: SizedBox(
        height: 78,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // The HTML equalizer lets the tallest bars extend above its
            // 78px track. Positioning them avoids a Flutter flex overflow.
            Positioned(
              left: 0,
              right: 0,
              bottom: 19,
              child: Container(
                height: height,
                decoration: BoxDecoration(color: isHi ? GenzColors.lime : Colors.white.withValues(alpha: 0.28), borderRadius: BorderRadius.circular(100)),
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
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.75), fontFamily: GenzFonts.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RecapHighlight {
  const _RecapHighlight(this.rank, this.title, this.subtitle, this.value, this.route, this.tone);
  final String rank;
  final String title;
  final String subtitle;
  final String value;
  final String? route;
  final GenzTone? tone;
}

class _RecapFood {
  const _RecapFood(this.food, this.detail);
  final String food;
  final String detail;
}
