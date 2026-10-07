import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../genz_theme.dart';
import '../widgets/genz_tile.dart';

class GenzForYouTab extends StatelessWidget {
  const GenzForYouTab({super.key, required this.onNavigate});

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
                const TextSpan(text: 'your gut’s having a '),
                WidgetSpan(
                  child: Transform.rotate(
                    angle: -0.026, // -1.5 degrees
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: const BoxDecoration(
                        color: GenzColors.lime,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: const Text('main character', style: TextStyle(color: GenzColors.ink, fontFamily: 'InterTight', fontSize: 34, fontWeight: FontWeight.w900, height: 0.98, letterSpacing: -1.6)),
                    ),
                  ),
                ),
                const TextSpan(text: ' week'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Gut Score Tile
          GenzTile(
            tone: GenzTone.lime,
            onTap: () => onNavigate('score'),
            art: Positioned(
              right: -12,
              top: 10,
              child: Transform.rotate(
                angle: 0.14, // 8 deg
                child: Image.asset('assets/images/a-gauge.webp', width: 138, height: 138),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('gut score', style: TextStyle(color: Color(0x9E0B0B12), fontFamily: 'InterTight', fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                const SizedBox(height: 10),
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
                const SizedBox(height: 14),
                const GenzSticker(text: '+4 vs yesterday', tone: GenzTone.ink),
                const SizedBox(height: 14),
                const Text('based on what you logged.', style: TextStyle(color: Color(0x9E0B0B12), fontSize: 14.5, fontWeight: FontWeight.w600, fontFamily: 'InterTight')),
                const SizedBox(height: 18),
                _buildEqualizer(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Row(
                        children: [
                          Icon(LucideIcons.share, size: 16, color: GenzColors.ink),
                          SizedBox(width: 6),
                          Text('share', style: TextStyle(color: GenzColors.ink, fontSize: 13, fontWeight: FontWeight.w800, fontFamily: 'InterTight')),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: GenzColors.ink,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.arrowRight, color: GenzColors.lime, size: 20),
                    ),
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 26),
          Text('right now', style: GenzStyles.h2(context)),
          const SizedBox(height: 10),

          // Right Now Tile
          GenzTile(
            tone: GenzTone.ink,
            onTap: () => onNavigate('obs-dairy'),
            art: Positioned(
              right: -4,
              top: 10,
              child: Transform.rotate(
                angle: 0.17, // 10 deg
                child: Image.asset('assets/images/a-bulb.webp', width: 112, height: 112),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GenzSticker(text: 'today’s focus', tone: GenzTone.lime),
                const SizedBox(height: 16),
                const Text('dairy might be your bloating plot twist.', style: GenzStyles.title),
                const SizedBox(height: 12),
                Text('bloating followed milk-based meals on 3 of the 4 days you logged them.', style: GenzStyles.caption.copyWith(color: Colors.white.withOpacity(0.66))),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('3 of 4 days', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'InterTight')),
                    Text('medium confidence', style: TextStyle(color: Colors.white.withOpacity(0.66), fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'InterTight')),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildDot(true),
                    _buildDot(true),
                    _buildDot(true),
                    _buildDot(false),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  height: 54,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: GenzColors.lime,
                    borderRadius: BorderRadius.circular(100),
                  ),
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
                      Text('progress', style: GenzStyles.eyebrow(context).copyWith(color: Colors.white.withValues(alpha: 0.78))),
                      const SizedBox(height: 2),
                      const Text('+4 pts', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, letterSpacing: -1.2, height: 1, fontFamily: 'InterTight')),
                      const SizedBox(height: 6),
                      const Text('fewer bloating logs after lunch.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'InterTight')),
                      const Spacer(),
                      const GenzSticker(text: 'on track', tone: GenzTone.ink, angle: -0.035),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GenzTile(
                  tone: GenzTone.pink,
                  height: 232,
                  padding: const EdgeInsets.all(16),
                  onTap: () => onNavigate('swap-cold-milk'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset('assets/images/a-alert.webp', width: 60, height: 60),
                      const SizedBox(height: 12),
                      Text('watch', style: GenzStyles.eyebrow(context).copyWith(color: const Color(0x9E0B0B12))),
                      const SizedBox(height: 2),
                      const Text('cold milk', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, letterSpacing: -1.2, height: 1, fontFamily: 'InterTight')),
                      const SizedBox(height: 6),
                      const Text('bloating within 2 hrs of drinking it.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'InterTight')),
                      const Spacer(),
                      const GenzSticker(text: '3 receipts', tone: GenzTone.ink, angle: -0.035),
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

  Widget _buildEqualizer() {
    return SizedBox(
      height: 78,
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
    final barHeight = isZero ? 6.0 : (34.0 * pct).clamp(6.0, 34.0);
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
          Text(
            day,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              color: GenzColors.ink.withValues(alpha: 0.75),
              fontFamily: 'InterTight',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(bool isOn) {
    return Expanded(
      child: Container(
        height: 10,
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: isOn ? GenzColors.lime : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(100),
        ),
      ),
    );
  }
}
