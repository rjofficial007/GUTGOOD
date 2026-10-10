import 'package:flutter/material.dart';
import 'package:genz_insights/src/genz_theme.dart';
import 'package:genz_insights/src/widgets/genz_primitives.dart';
import 'package:genz_insights/src/widgets/genz_share.dart';
import 'package:genz_insights/src/widgets/genz_tile.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum GenzDataState { full, early, learn }

class GenzEarlyForYouView extends StatelessWidget {
  const GenzEarlyForYouView({super.key, required this.onNavigate});

  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
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
                    decoration: const BoxDecoration(color: GenzColors.lime, borderRadius: BorderRadius.all(Radius.circular(10))),
                    child: const Text(
                      'loading…',
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
          tone: GenzTone.lilac,
          onTap: () => onNavigate('score'),
          art: Positioned(
            right: -12,
            top: 10,
            child: Transform.rotate(angle: 0.14, child: const GenzArt(asset: 'assets/images/a-gauge.webp', width: 138, height: 138)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'baseline score',
                style: TextStyle(color: Color(0x9E0B0B12), fontFamily: GenzFonts.primary, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.2),
              ),
              const SizedBox(height: 10),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('72', style: GenzStyles.big),
                  SizedBox(width: 4),
                  Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text(
                      '/100',
                      style: TextStyle(color: Color(0x9E0B0B12), fontSize: 26, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const GenzSticker(text: 'starting baseline'),
              const SizedBox(height: 14),
              const Text(
                '1 day scored. log a few more to see a real trend.',
                style: TextStyle(color: Color(0x9E0B0B12), fontSize: 14.5, fontWeight: FontWeight.w600, fontFamily: GenzFonts.primary),
              ),
              const SizedBox(height: 18),
              _buildBaselineEqualizer(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => copyGenzShare(context, text: 'Baseline score 72/100. One day scored.'),
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(100)),
                      child: const Row(
                        children: [
                          Icon(LucideIcons.upload, size: 16, color: GenzColors.ink),
                          SizedBox(width: 6),
                          Text(
                            'share',
                            style: TextStyle(color: GenzColors.ink, fontSize: 13, fontWeight: FontWeight.w800, fontFamily: GenzFonts.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: GenzColors.ink, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.arrowUpRight, color: GenzColors.lilac, size: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Text('early read', style: GenzStyles.h2(context)),
        const SizedBox(height: 10),
        GenzTile(
          tone: GenzTone.ink,
          onTap: () => onNavigate('obs-milktea'),
          art: Positioned(
            right: -4,
            top: 10,
            child: Transform.rotate(angle: 0.17, child: const GenzArt(asset: 'assets/images/a-bulb.webp', width: 112, height: 112)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GenzSticker(text: 'early read', tone: GenzTone.lime),
              const SizedBox(height: 16),
              const Text(
                'milk tea at night might be messing with your sleep.',
                style: TextStyle(fontFamily: GenzFonts.primary, fontFamilyFallback: GenzFonts.fallback, fontSize: 31, fontWeight: FontWeight.w900, letterSpacing: -1.3, height: 1),
              ),
              const SizedBox(height: 12),
              Text('you reported restless sleep after logging milk tea once.', style: GenzStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.66))),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '1 of 7 days',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary),
                  ),
                  Text(
                    'low confidence',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.66), fontSize: 13, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildConfidenceDots(1, 7),
              const SizedBox(height: 18),
              _primaryAction('see the receipts'),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Text('quick hits', style: GenzStyles.h2(context)),
        const SizedBox(height: 10),
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
                    const GenzArt(asset: 'assets/images/a-sprout.webp', width: 60, height: 60),
                    const SizedBox(height: 12),
                    Text('building baseline', style: GenzStyles.eyebrow(context).copyWith(color: Colors.white.withValues(alpha: 0.78))),
                    const SizedBox(height: 2),
                    const Text(
                      '1 day',
                      style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, letterSpacing: -1.2, height: 1, fontFamily: GenzFonts.primary),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'log another day to compare.',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: GenzFonts.primary),
                    ),
                    const Spacer(),
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: GenzSticker(text: 'no trend yet', angle: -0.035),
                    ),
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
                    const GenzArt(asset: 'assets/images/a-alert.webp', width: 60, height: 60),
                    const SizedBox(height: 12),
                    Text('pattern check', style: GenzStyles.eyebrow(context).copyWith(color: const Color(0x9E0B0B12))),
                    const SizedBox(height: 2),
                    const Text(
                      'none yet',
                      style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, letterSpacing: -1.2, height: 1, fontFamily: GenzFonts.primary),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'one log isn’t enough to call it.',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: GenzFonts.primary),
                    ),
                    const Spacer(),
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: GenzSticker(text: '1 receipt', angle: -0.035),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        _buildFootnote(context),
        const SizedBox(height: 8),
      ],
    ),
  );

  Widget _buildBaselineEqualizer() {
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
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
                      height: index == 6 ? 54 : 8,
                      decoration: BoxDecoration(color: index == 6 ? GenzColors.ink : GenzColors.ink.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      days[index],
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: GenzColors.ink.withValues(alpha: 0.75), fontFamily: GenzFonts.primary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConfidenceDots(int filled, int total) => Row(
    children: [
      for (var index = 0; index < total; index++)
        Expanded(
          child: Container(
            height: 10,
            margin: EdgeInsets.only(right: index == total - 1 ? 0 : 6),
            decoration: BoxDecoration(color: index < filled ? GenzColors.lime : Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(100)),
          ),
        ),
    ],
  );

  Widget _primaryAction(String text) => Container(
    height: 54,
    width: double.infinity,
    decoration: BoxDecoration(color: GenzColors.lime, borderRadius: BorderRadius.circular(100)),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          text,
          style: const TextStyle(color: GenzColors.ink, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3, fontFamily: GenzFonts.primary),
        ),
        const SizedBox(width: 8),
        const Icon(LucideIcons.arrowRight, color: GenzColors.ink, size: 20),
      ],
    ),
  );

  Widget _buildFootnote(BuildContext context) => Center(
    child: Text(
      'just vibes from your logs. not medical advice.',
      style: TextStyle(color: GenzColors.mu(context), fontSize: 12, fontWeight: FontWeight.w700, fontFamily: GenzFonts.primary),
    ),
  );
}

class GenzEmptyStateCardView extends StatefulWidget {
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
  State<GenzEmptyStateCardView> createState() => _GenzEmptyStateCardViewState();
}

class _GenzEmptyStateCardViewState extends State<GenzEmptyStateCardView> {
  bool _quest1Done = false;
  bool _quest2Done = false;

  int get _completedCount => (_quest1Done ? 1 : 0) + (_quest2Done ? 1 : 0);

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.eyebrow.toUpperCase(), style: GenzStyles.eyebrow(context)),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            style: GenzStyles.h1(context),
            children: [
              TextSpan(text: '${widget.titleText} '),
              WidgetSpan(
                child: Transform.rotate(
                  angle: -0.026,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: const BoxDecoration(color: GenzColors.lime, borderRadius: BorderRadius.all(Radius.circular(10))),
                    child: Text(
                      widget.highlightWord,
                      style: const TextStyle(color: GenzColors.ink, fontFamily: GenzFonts.primary, fontSize: 38, fontWeight: FontWeight.w900, height: 0.98, letterSpacing: -1.8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GenzTile(
          tone: widget.tone,
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
          child: Column(
            children: [
              GenzArt(asset: 'assets/images/${widget.asset}', width: 150, height: 150),
              const SizedBox(height: 14),
              Text(
                widget.cardTitle,
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1.3, height: 1, color: GenzColors.ink, fontFamily: GenzFonts.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 270,
                child: Text(
                  widget.cardDesc,
                  style: TextStyle(color: GenzColors.ink.withValues(alpha: 0.62), fontSize: 14.5, fontWeight: FontWeight.w600, height: 1.35, fontFamily: GenzFonts.primary),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(onTap: () => showGenzToast(context, 'opens the meal scanner in the app'), child: _actionButton('scan a meal', filled: true)),
              const SizedBox(height: 10),
              GestureDetector(onTap: () => showGenzToast(context, 'opens the symptom logger in the app'), child: _actionButton('log a symptom', filled: false)),
            ],
          ),
        ),
        const SizedBox(height: 14),
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
                      Text(
                        widget.questTitle,
                        style: TextStyle(color: GenzColors.tx(context), fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: -0.6, fontFamily: GenzFonts.primary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_completedCount of 2 done',
                        style: TextStyle(color: GenzColors.mu(context), fontSize: 13, fontWeight: FontWeight.w700, fontFamily: GenzFonts.primary),
                      ),
                    ],
                  ),
                  GenzSticker(text: '${_completedCount * 10} xp', tone: GenzTone.ink, angle: 0.052),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(value: _completedCount / 2, minHeight: 12, backgroundColor: GenzColors.sf2(context), valueColor: const AlwaysStoppedAnimation<Color>(GenzColors.lime)),
              ),
              const SizedBox(height: 6),
              _buildQuestRow(widget.quest1, _quest1Done, () => _toggleQuest(0)),
              GenzDashedDivider(color: GenzColors.ln(context), thickness: 1.5),
              _buildQuestRow(widget.quest2, _quest2Done, () => _toggleQuest(1)),
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

  void _toggleQuest(int index) {
    final wasDone = index == 0 ? _quest1Done : _quest2Done;
    setState(() {
      if (index == 0) {
        _quest1Done = !wasDone;
      } else {
        _quest2Done = !wasDone;
      }
    });
    if (!wasDone && _quest1Done && _quest2Done) {
      showGenzToast(context, 'quest cleared. +20 xp');
    }
  }

  Widget _actionButton(String text, {required bool filled}) => Container(
    height: 54,
    width: double.infinity,
    decoration: BoxDecoration(
      color: filled ? GenzColors.ink : Colors.transparent,
      borderRadius: BorderRadius.circular(100),
      border: filled ? null : Border.all(color: GenzColors.ink.withValues(alpha: 0.35), width: 2),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          text,
          style: TextStyle(color: filled ? Colors.white : GenzColors.ink, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary),
        ),
        if (filled) ...[const SizedBox(width: 8), const Icon(LucideIcons.arrowRight, color: Colors.white, size: 18)],
      ],
    ),
  );

  Widget _buildQuestRow(String title, bool done, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: done ? GenzColors.lime : Colors.transparent,
              border: done ? null : Border.all(color: GenzColors.mu(context), width: 2.5),
            ),
            child: done ? const Icon(LucideIcons.check, size: 16, color: GenzColors.ink) : null,
          ),
          const SizedBox(width: 10),
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
          Text(
            '+10 xp',
            style: TextStyle(color: done ? GenzColors.lime : GenzColors.mu(context), fontSize: 12, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary),
          ),
        ],
      ),
    ),
  );
}
