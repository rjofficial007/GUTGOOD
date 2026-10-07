import 'package:flutter/material.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/features/insights/presentation/pages/genz/widgets/genz_story_viewer.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../genz_theme.dart';
import '../widgets/genz_tile.dart';

class GenzRecapTab extends StatelessWidget {
  const GenzRecapTab({super.key, required this.onNavigate});

  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                      decoration: const BoxDecoration(
                        color: GenzColors.lime,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: const Text('wrapped', style: TextStyle(color: GenzColors.ink, fontFamily: 'InterTight', fontSize: 34, fontWeight: FontWeight.w900, height: 0.98, letterSpacing: -1.6)),
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
              child: Transform.rotate(
                angle: 0.14,
                child: Image.asset('assets/images/a-calendar.webp', width: 120, height: 120),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('weekly average', style: TextStyle(color: Colors.white.withOpacity(0.78), fontFamily: 'InterTight', fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('74', style: TextStyle(fontSize: 84, fontWeight: FontWeight.w900, letterSpacing: -4, height: 0.82, fontFamily: 'InterTight', color: Colors.white)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text('/100', style: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'InterTight')),
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
                      onTap: () {
                        GenzStoryViewer.show(context, 'week', const [
                          GenzStorySlide(
                            label: 'weekly recap',
                            title: 'score 74',
                            subtitle: 'your gut had a main character week.',
                            artAsset: 'a-calendar.webp',
                            tone: GenzTone.blue,
                            ctaText: 'see the score',
                            ctaRoute: AppRoutes.smartInsightDetail,
                          ),
                        ]);
                      },
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        decoration: BoxDecoration(
                          color: GenzColors.lime,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Row(
                          children: [
                            Icon(LucideIcons.play, size: 16, color: GenzColors.ink),
                            SizedBox(width: 6),
                            Text('play recap', style: TextStyle(color: GenzColors.ink, fontSize: 13, fontWeight: FontWeight.w800, fontFamily: 'InterTight')),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Row(
                        children: [
                          Icon(LucideIcons.share, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text('share', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, fontFamily: 'InterTight')),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Stats Row
          Row(
            children: [
              _buildStatTile(context, GenzTone.butter, 'a-trophy.webp', 'best day', 'wed', 'score 84', 'history'),
              const SizedBox(width: 10),
              _buildStatTile(context, GenzTone.lime, 'a-bowl.webp', 'foods', '27', 'meals + scans', 'food-intel'),
              const SizedBox(width: 10),
              _buildStatTile(context, GenzTone.lilac, 'a-sprout.webp', 'evidence', '32', 'entries', 'history'),
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

  Widget _buildStatTile(BuildContext context, GenzTone tone, String asset, String eyebrow, String value, String cap, String target) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onNavigate(target),
        child: Container(
          height: 176,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _getColor(tone),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset('assets/images/$asset', width: 50, height: 50),
              const SizedBox(height: 10),
              Text(eyebrow, style: TextStyle(color: GenzColors.ink.withOpacity(0.62), fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.2, fontFamily: 'InterTight')),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: GenzColors.ink, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -1.2, height: 1.05, fontFamily: 'InterTight')),
              const SizedBox(height: 2),
              Text(cap, style: TextStyle(color: GenzColors.ink.withOpacity(0.62), fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'InterTight')),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColor(GenzTone tone) {
    switch(tone) {
      case GenzTone.butter: return GenzColors.butter;
      case GenzTone.lime: return GenzColors.lime;
      case GenzTone.lilac: return GenzColors.lilac;
      default: return GenzColors.lime;
    }
  }

  Widget _buildEqualizer() {
    return SizedBox(
      height: 78,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildEqBar('S', 0.55, false),
          _buildEqBar('M', 0.60, false),
          _buildEqBar('T', 0.50, false),
          _buildEqBar('W', 0.85, false, isHi: true),
          _buildEqBar('T', 0.75, false),
          _buildEqBar('F', 0.70, false),
          _buildEqBar('S', 0.55, false),
        ],
      ),
    );
  }

  Widget _buildEqBar(String day, double pct, bool isZero, {bool isHi = false}) {
    final barHeight = isZero ? 6.0 : (34.0 * pct).clamp(6.0, 34.0);
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 10,
            height: barHeight,
            decoration: BoxDecoration(
              color: isHi ? GenzColors.lime : Colors.white.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            day,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              color: Colors.white.withValues(alpha: 0.75),
              fontFamily: 'InterTight',
            ),
          ),
        ],
      ),
    );
  }
}
