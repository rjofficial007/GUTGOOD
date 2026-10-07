import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../genz_theme.dart';
import '../widgets/genz_tile.dart';

class GenzPatternItem {
  const GenzPatternItem({
    required this.id,
    required this.tone,
    required this.sticker,
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.seenCount,
    required this.isEven,
  });

  final String id;
  final GenzTone tone;
  final String sticker;
  final String asset;
  final String title;
  final String subtitle;
  final int seenCount;
  final bool isEven;
}

class GenzPatternsTab extends StatefulWidget {
  const GenzPatternsTab({super.key, required this.onNavigate});

  final ValueChanged<String> onNavigate;

  @override
  State<GenzPatternsTab> createState() => _GenzPatternsTabState();
}

class _GenzPatternsTabState extends State<GenzPatternsTab> {
  int _selectedSegment = 0; // 0: all 6, 1: watch 3, 2: helpful 3

  static const List<GenzPatternItem> _allPatterns = [
    GenzPatternItem(id: 'pattern-bloating', tone: GenzTone.orange, sticker: 'watch', asset: 'a-bloating.webp', title: 'bloating', subtitle: 'digestion', seenCount: 4, isEven: true),
    GenzPatternItem(id: 'pattern-energy', tone: GenzTone.butter, sticker: 'helpful', asset: 'a-energy.webp', title: 'energy', subtitle: 'vitality', seenCount: 5, isEven: false),
    GenzPatternItem(id: 'pattern-fullness', tone: GenzTone.blue, sticker: 'helpful', asset: 'a-fullness.webp', title: 'fullness', subtitle: 'satiety', seenCount: 3, isEven: true),
    GenzPatternItem(id: 'pattern-digestion', tone: GenzTone.lime, sticker: 'helpful', asset: 'a-digestion.webp', title: 'digestion', subtitle: 'gut health', seenCount: 4, isEven: false),
    GenzPatternItem(id: 'pattern-sleep', tone: GenzTone.lilac, sticker: 'watch', asset: 'a-sleep.webp', title: 'sleep', subtitle: 'rest & recovery', seenCount: 2, isEven: true),
    GenzPatternItem(id: 'pattern-headache', tone: GenzTone.pink, sticker: 'watch', asset: 'a-headache.webp', title: 'headache', subtitle: 'focus', seenCount: 2, isEven: false),
  ];

  List<GenzPatternItem> get _filteredPatterns {
    if (_selectedSegment == 1) {
      return _allPatterns.where((p) => p.sticker == 'watch').toList();
    } else if (_selectedSegment == 2) {
      return _allPatterns.where((p) => p.sticker == 'helpful').toList();
    }
    return _allPatterns;
  }

  @override
  Widget build(BuildContext context) {
    final patterns = _filteredPatterns;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PATTERNS', style: GenzStyles.eyebrow(context)),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: GenzStyles.h1(context),
              children: [
                const TextSpan(text: '6 patterns '),
                WidgetSpan(
                  child: Transform.rotate(
                    angle: -0.026,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: const BoxDecoration(
                        color: GenzColors.lime,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: const Text('unlocked', style: TextStyle(color: GenzColors.ink, fontFamily: 'InterTight', fontSize: 34, fontWeight: FontWeight.w900, height: 0.98, letterSpacing: -1.6)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Segmented Control
          Row(
            children: [
              _buildSegment(0, 'all 6'),
              const SizedBox(width: 8),
              _buildSegment(1, 'watch 3'),
              const SizedBox(width: 8),
              _buildSegment(2, 'helpful 3'),
            ],
          ),
          const SizedBox(height: 14),

          // Pattern Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: patterns.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.65, // ~165/258
            ),
            itemBuilder: (context, index) {
              final item = patterns[index];
              return _buildPatternCard(context, item);
            },
          ),

          const SizedBox(height: 26),
          Center(
            child: Text('tap a card to see the receipts.', style: TextStyle(color: GenzColors.mu(context), fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'InterTight')),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSegment(int index, String label) {
    final isSelected = _selectedSegment == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSegment = index),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: isSelected ? GenzColors.lime : GenzColors.sf(context),
            borderRadius: BorderRadius.circular(100),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'InterTight',
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: isSelected ? GenzColors.ink : GenzColors.tx(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatternCard(BuildContext context, GenzPatternItem item) {
    return GenzTile(
      tone: item.tone,
      padding: const EdgeInsets.all(16),
      onTap: () => widget.onNavigate(item.id),
      art: Positioned(
        right: -2,
        top: 46,
        child: Transform.rotate(
          angle: item.isEven ? -0.1 : 0.1, // ~ +/- 6 degrees
          child: Image.asset('assets/images/${item.asset}', width: 112, height: 112),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GenzSticker(text: item.sticker, tone: GenzTone.ink),
          const Spacer(),
          Text(item.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1, height: 1, fontFamily: 'InterTight')),
          const SizedBox(height: 3),
          Text(item.subtitle, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: item.tone == GenzTone.blue ? Colors.white.withOpacity(0.78) : GenzColors.ink.withOpacity(0.62), fontFamily: 'InterTight')),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: item.tone == GenzTone.blue ? Colors.white : GenzColors.ink,
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.arrowRight, color: item.tone == GenzTone.blue ? GenzColors.blue : _getToneColor(item.tone), size: 16),
              ),
              const SizedBox(width: 8),
              Text('seen ${item.seenCount}×', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, fontFamily: 'InterTight')),
            ],
          ),
        ],
      ),
    );
  }

  Color _getToneColor(GenzTone tone) {
    switch (tone) {
      case GenzTone.lime: return GenzColors.lime;
      case GenzTone.pink: return GenzColors.pink;
      case GenzTone.blue: return GenzColors.blue;
      case GenzTone.orange: return GenzColors.orange;
      case GenzTone.lilac: return GenzColors.lilac;
      case GenzTone.butter: return GenzColors.butter;
      case GenzTone.ink: return GenzColors.lime;
    }
  }
}
