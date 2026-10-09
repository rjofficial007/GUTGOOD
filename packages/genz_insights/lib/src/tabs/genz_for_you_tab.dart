import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../genz_theme.dart';
import '../widgets/genz_share.dart';
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
                      child: const Text('main character', style: TextStyle(color: GenzColors.ink, fontFamily: GenzFonts.primary, fontSize: 38, fontWeight: FontWeight.w900, height: 0.98, letterSpacing: -1.8)),
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
                child: GenzArt(asset: 'assets/images/a-gauge.webp', width: 138, height: 138),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('gut score', style: TextStyle(color: Color(0x9E0B0B12), fontFamily: GenzFonts.primary, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('78', style: GenzStyles.big),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Text('/100', style: TextStyle(color: const Color(0x9E0B0B12), fontSize: 24, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const GenzSticker(text: '+4 vs yesterday'),
                const SizedBox(height: 14),
                const Text('based on what you logged.', style: TextStyle(color: Color(0x9E0B0B12), fontSize: 14.5, fontWeight: FontWeight.w600, fontFamily: GenzFonts.primary)),
                const SizedBox(height: 18),
                _buildEqualizer(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => copyGenzShare(context, text: 'Gut score 78/100, up 4 vs yesterday.'),
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Row(
                          children: [
                            Icon(LucideIcons.upload, size: 16, color: GenzColors.ink),
                            SizedBox(width: 6),
                            Text('share', style: TextStyle(color: GenzColors.ink, fontSize: 13, fontWeight: FontWeight.w800, fontFamily: GenzFonts.primary)),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: GenzColors.ink,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.arrowUpRight, color: GenzColors.lime, size: 20),
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
                child: GenzArt(asset: 'assets/images/a-bulb.webp', width: 112, height: 112),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GenzSticker(text: 'today’s focus', tone: GenzTone.lime),
                const SizedBox(height: 16),
                const Text(
                  'dairy might be your bloating plot twist.',
                  style: TextStyle(
                    fontFamily: GenzFonts.primary,
                    fontFamilyFallback: GenzFonts.fallback,
                    fontSize: 31,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.3,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Text('bloating followed milk-based meals on 3 of the 4 days you logged them.', style: GenzStyles.caption.copyWith(color: Colors.white.withOpacity(0.66))),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('3 of 4 days', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary)),
                    Text('medium confidence', style: TextStyle(color: Colors.white.withOpacity(0.66), fontSize: 13, fontWeight: FontWeight.w900, fontFamily: GenzFonts.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildDot(true),
                    _buildDot(true),
                    _buildDot(true),
                    _buildDot(false, isLast: true),
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
                      Text('see the receipts', style: TextStyle(color: GenzColors.ink, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3, fontFamily: GenzFonts.primary)),
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
                      GenzArt(asset: 'assets/images/a-sprout.webp', width: 60, height: 60),
                      const SizedBox(height: 12),
                      Text('progress', style: GenzStyles.eyebrow(context).copyWith(color: Colors.white.withValues(alpha: 0.78))),
                      const SizedBox(height: 2),
                      const Text('+4 pts', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, letterSpacing: -1.2, height: 1, fontFamily: GenzFonts.primary)),
                      const SizedBox(height: 6),
                      const Text('fewer bloating logs after lunch.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: GenzFonts.primary)),
                      const Spacer(),
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: GenzSticker(text: 'on track', angle: -0.035),
                      ),
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
                  onTap: () => onNavigate('food-cold-milk'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GenzArt(asset: 'assets/images/a-alert.webp', width: 60, height: 60),
                      const SizedBox(height: 12),
                      Text('watch', style: GenzStyles.eyebrow(context).copyWith(color: const Color(0x9E0B0B12))),
                      const SizedBox(height: 2),
                      const Text('cold milk', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, letterSpacing: -1.2, height: 1, fontFamily: GenzFonts.primary)),
                      const SizedBox(height: 6),
                      const Text('bloating within 2 hrs of drinking it.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: GenzFonts.primary)),
                      const Spacer(),
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: GenzSticker(text: '3 receipts', angle: -0.035),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 26),
          Center(
            child: Text('just vibes from your logs. not medical advice.', style: TextStyle(color: GenzColors.mu(context), fontSize: 12, fontWeight: FontWeight.w700, fontFamily: GenzFonts.primary)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildEqualizer() => SizedBox(
        height: 78,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildEqBar('S', 36),
            _buildEqBar('M', 8, isZero: true),
            _buildEqBar('T', 50),
            _buildEqBar('W', 54),
            _buildEqBar('T', 45),
            _buildEqBar('F', 58),
            _buildEqBar('S', 68, isHi: true, isLast: true),
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
                // Preserve the HTML equalizer's upward overflow without a
                // RenderFlex overflow in Flutter.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 19,
                  child: Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: isHi ? GenzColors.ink : GenzColors.ink.withOpacity(isZero ? 0.1 : 0.2),
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
                        color: GenzColors.ink.withOpacity(0.75),
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

  Widget _buildDot(bool isOn, {bool isLast = false}) {
    return Expanded(
      child: Container(
        height: 10,
        margin: EdgeInsets.only(right: isLast ? 0 : 6),
        decoration: BoxDecoration(
          color: isOn ? GenzColors.lime : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(100),
        ),
      ),
    );
  }
}
