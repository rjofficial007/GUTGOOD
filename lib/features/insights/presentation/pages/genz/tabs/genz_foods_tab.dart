import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../genz_theme.dart';
import '../widgets/genz_tile.dart';

class GenzFoodsTab extends StatelessWidget {
  const GenzFoodsTab({super.key, required this.onNavigate});

  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                      child: const Text('hits', style: TextStyle(color: GenzColors.ink, fontFamily: 'InterTight', fontSize: 34, fontWeight: FontWeight.w900, height: 0.98, letterSpacing: -1.6)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          GenzTile(
            tone: GenzTone.ink,
            onTap: () => onNavigate('food-intel'),
            art: Positioned(
              right: -8,
              top: 8,
              child: Transform.rotate(
                angle: 0.14,
                child: Image.asset('assets/images/a-bowl.webp', width: 120, height: 120),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GenzSticker(text: 'vibe check', tone: GenzTone.orange),
                const SizedBox(height: 14),
                const Text('55%', style: TextStyle(fontSize: 92, fontWeight: FontWeight.w900, letterSpacing: -4, height: 0.82, fontFamily: 'InterTight', color: Colors.white)),
                const SizedBox(height: 8),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.6, fontFamily: 'InterTight', color: Colors.white),
                    children: [
                      TextSpan(text: 'of your foods are '),
                      TextSpan(text: 'helpful', style: TextStyle(color: GenzColors.lime)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text('11 of 20 foods agreed with your gut.', style: TextStyle(color: Colors.white.withOpacity(0.66), fontSize: 14.5, fontWeight: FontWeight.w600, fontFamily: 'InterTight')),

                // Stack Bar
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

                // Legend
                _buildLegendRow(context, GenzColors.lime, 'helpful', '55%', '11 foods'),
                const SizedBox(height: 8),
                _buildLegendRow(context, const Color(0xFF8E8EA3), 'neutral', '20%', '4 foods'),
                const SizedBox(height: 8),
                _buildLegendRow(context, GenzColors.orange, 'watch', '25%', '5 foods'),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Swap Alert
          GenzTile(
            tone: GenzTone.orange,
            onTap: () => onNavigate('swaps'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GenzSticker(text: 'swap alert', tone: GenzTone.ink),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Image.asset('assets/images/a-bloating.webp', width: 92, height: 92),
                    const SizedBox(width: 6),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: GenzColors.ink),
                      child: const Icon(LucideIcons.arrowRight, color: GenzColors.orange, size: 20),
                    ),
                    const SizedBox(width: 6),
                    Image.asset('assets/images/a-energy.webp', width: 92, height: 92),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('swap cold milk for ginger tea', style: GenzStyles.title),
                const SizedBox(height: 8),
                Text('ginger tea → steadier energy. cold milk → bloating.', style: TextStyle(color: GenzColors.ink.withOpacity(0.62), fontSize: 14.5, fontWeight: FontWeight.w600, fontFamily: 'InterTight')),
                const SizedBox(height: 16),
                Container(
                  height: 54,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: GenzColors.ink,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('find better swaps', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3, fontFamily: 'InterTight')),
                      SizedBox(width: 8),
                      Icon(LucideIcons.arrowRight, color: Colors.white, size: 20),
                    ],
                  ),
                ),
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

  Widget _buildLegendRow(BuildContext context, Color color, String label, String pct, String count) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, fontFamily: 'InterTight', color: Colors.white))),
        Text(pct, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, fontFamily: 'InterTight', color: Colors.white)),
        SizedBox(
          width: 64,
          child: Text(count, textAlign: TextAlign.right, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, fontFamily: 'InterTight', color: GenzColors.mu(context))),
        ),
      ],
    );
  }
}
