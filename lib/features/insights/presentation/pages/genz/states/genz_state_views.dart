import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../genz_theme.dart';
import '../widgets/genz_tile.dart';

enum GenzDataState { full, early, learn }

class GenzEarlyForYouView extends StatelessWidget {
  const GenzEarlyForYouView({
    super.key,
    required this.onNavigate,
  });

  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TODAY · MON, OCT 5', style: GenzStyles.eyebrow(context)),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: GenzStyles.h1(context),
              children: [
                const TextSpan(text: 'your baseline is '),
                WidgetSpan(
                  child: Transform.rotate(
                    angle: -0.026,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: const BoxDecoration(
                        color: GenzColors.lime,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: const Text('loading…', style: TextStyle(color: GenzColors.ink, fontFamily: 'InterTight', fontSize: 34, fontWeight: FontWeight.w900, height: 0.98, letterSpacing: -1.6)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Baseline Score Tile
          GenzTile(
            tone: GenzTone.lilac,
            onTap: () => onNavigate('score'),
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
                Text('baseline score', style: TextStyle(color: const Color(0x9E0B0B12), fontFamily: 'InterTight', fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('72', style: GenzStyles.big),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text('/100', style: TextStyle(color: const Color(0x9E0B0B12), fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'InterTight')),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const GenzSticker(text: 'starting baseline', tone: GenzTone.ink),
                const SizedBox(height: 14),
                const Text('1 day scored. log a few more to see a real trend.', style: TextStyle(color: Color(0x9E0B0B12), fontSize: 14.5, fontWeight: FontWeight.w600, fontFamily: 'InterTight')),
              ],
            ),
          ),

          const SizedBox(height: 26),
          Text('early read', style: GenzStyles.h2(context)),
          const SizedBox(height: 10),

          // Early Read Tile
          GenzTile(
            tone: GenzTone.ink,
            onTap: () => onNavigate('obs-milktea'),
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
                const GenzSticker(text: 'early read', tone: GenzTone.lime),
                const SizedBox(height: 16),
                const Text('milk tea at night might be messing with your sleep.', style: GenzStyles.title),
                const SizedBox(height: 12),
                Text('you reported restless sleep after logging milk tea once.', style: GenzStyles.caption.copyWith(color: Colors.white.withOpacity(0.66))),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('1 of 7 days', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'InterTight')),
                    Text('low confidence', style: TextStyle(color: Colors.white.withOpacity(0.66), fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'InterTight')),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  height: 54,
                  width: double.infinity,
                  decoration: BoxDecoration(color: GenzColors.lime, borderRadius: BorderRadius.circular(100)),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('see the receipts', style: TextStyle(color: GenzColors.ink, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3, fontFamily: 'InterTight')),
                      SizedBox(width: 8),
                      Icon(LucideIcons.arrowRight, color: GenzColors.ink, size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),
          Text('quick hits', style: GenzStyles.h2(context)),
          const SizedBox(height: 10),

          // Quick Hits Row
          Row(
            children: [
              Expanded(
                child: GenzTile(
                  tone: GenzTone.blue,
                  height: 232,
                  padding: const EdgeInsets.all(16),
                  onTap: () => onNavigate('score'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset('assets/images/a-sprout.webp', width: 60, height: 60),
                      const SizedBox(height: 12),
                      Text('building baseline', style: GenzStyles.eyebrow(context).copyWith(color: Colors.white.withOpacity(0.78))),
                      const SizedBox(height: 2),
                      const Text('1 day', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, letterSpacing: -1.2, height: 1, fontFamily: 'InterTight')),
                      const SizedBox(height: 6),
                      const Text('log another day to compare.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'InterTight')),
                      const Spacer(),
                      const GenzSticker(text: 'no trend yet', tone: GenzTone.ink, angle: -0.035),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GenzTile(
                  tone: GenzTone.lilac,
                  height: 232,
                  padding: const EdgeInsets.all(16),
                  onTap: () => onNavigate('obs-milktea'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset('assets/images/a-alert.webp', width: 60, height: 60),
                      const SizedBox(height: 12),
                      Text('pattern check', style: GenzStyles.eyebrow(context).copyWith(color: const Color(0x9E0B0B12))),
                      const SizedBox(height: 2),
                      const Text('none yet', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, letterSpacing: -1.2, height: 1, fontFamily: 'InterTight')),
                      const SizedBox(height: 6),
                      const Text('one log isn’t enough to call it.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'InterTight')),
                      const Spacer(),
                      const GenzSticker(text: '1 receipt', tone: GenzTone.ink, angle: -0.035),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 26),
          Center(
            child: Text('just vibes from your logs. not medical advice.', style: TextStyle(color: GenzColors.mu(context), fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'InterTight')),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class GenzEmptyStateCardView extends StatelessWidget {
  const GenzEmptyStateCardView({
    super.key,
    required this.eyebrow,
    required this.titleText,
    required this.highlightWord,
    required this.tone,
    required this.asset,
    required this.cardTitle,
    required this.cardDesc,
    required this.questTitle,
    required this.quest1,
    required this.quest2,
  });

  final String eyebrow;
  final String titleText;
  final String highlightWord;
  final GenzTone tone;
  final String asset;
  final String cardTitle;
  final String cardDesc;
  final String questTitle;
  final String quest1;
  final String quest2;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow.toUpperCase(), style: GenzStyles.eyebrow(context)),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: GenzStyles.h1(context),
              children: [
                TextSpan(text: '$titleText '),
                WidgetSpan(
                  child: Transform.rotate(
                    angle: -0.026,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: const BoxDecoration(
                        color: GenzColors.lime,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: Text(highlightWord, style: const TextStyle(color: GenzColors.ink, fontFamily: 'InterTight', fontSize: 34, fontWeight: FontWeight.w900, height: 0.98, letterSpacing: -1.6)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tile
          GenzTile(
            tone: tone,
            child: Column(
              children: [
                Image.asset('assets/images/$asset', width: 140, height: 140),
                const SizedBox(height: 14),
                Text(cardTitle, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.2, color: GenzColors.ink, fontFamily: 'InterTight'), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(cardDesc, style: TextStyle(color: GenzColors.ink.withOpacity(0.7), fontSize: 14.5, fontWeight: FontWeight.w600, fontFamily: 'InterTight'), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Container(
                  height: 52,
                  width: double.infinity,
                  decoration: BoxDecoration(color: GenzColors.ink, borderRadius: BorderRadius.circular(100)),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('scan a meal', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, fontFamily: 'InterTight')),
                      SizedBox(width: 8),
                      Icon(LucideIcons.arrowRight, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Quest Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: GenzColors.sf(context), borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(questTitle, style: TextStyle(color: GenzColors.tx(context), fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'InterTight')),
                    const GenzSticker(text: '+10 xp', tone: GenzTone.lime),
                  ],
                ),
                const SizedBox(height: 12),
                _buildQuestRow(context, quest1, true),
                const SizedBox(height: 8),
                _buildQuestRow(context, quest2, false),
              ],
            ),
          ),

          const SizedBox(height: 26),
          Center(
            child: Text('just vibes from your logs. not medical advice.', style: TextStyle(color: GenzColors.mu(context), fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'InterTight')),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildQuestRow(BuildContext context, String title, bool done) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(shape: BoxShape.circle, color: done ? GenzColors.lime : GenzColors.sf2(context)),
          child: done ? const Icon(LucideIcons.check, size: 16, color: GenzColors.ink) : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: done ? GenzColors.mu(context) : GenzColors.tx(context),
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              decoration: done ? TextDecoration.lineThrough : null,
              fontFamily: 'InterTight',
            ),
          ),
        ),
      ],
    );
  }
}
