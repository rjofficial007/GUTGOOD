import 'package:flutter/material.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/product_details/presentation/widgets/scan_result_widgets.dart';

class SmallInsightMetricCard extends StatelessWidget {
  const SmallInsightMetricCard({super.key, required this.label, required this.value, required this.unit, required this.icon, required this.accentColor});
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Adaptive Theme Colors (Mirroring SuperPhysicalGoalCard style)
    final cardBg = isDark ? AppPalette.darkCard : scheme.cardBackground;
    final cardBorder = isDark ? AppPalette.white.withAlpha(20) : scheme.borderSubtle;
    final unitColor = isDark ? AppPalette.white.withAlpha(153) : scheme.textSecondary;
    final labelColor = isDark ? AppPalette.white.withAlpha(102) : scheme.textMuted;

    return BentoCard(
      padding: EdgeInsets.zero,
      height: 120.h,
      backgroundColor: cardBg,
      borderColor: cardBorder,
      borderRadius: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 🌊 Large Icon with Liquid Fill effect
            Positioned(
              right: -10,
              bottom: -15,
              child: Opacity(
                opacity: isDark ? 0.6 : 0.3,
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (rect) => LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [accentColor, accentColor, accentColor.withAlpha(isDark ? 40 : 80), accentColor.withAlpha(isDark ? 40 : 80)],
                    stops: const [0.0, 0.65, 0.65, 1.0],
                  ).createShader(rect),
                  child: Icon(icon, size: 80.h),
                ),
              ),
            ),

            // 📝 Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: context.displayHero.copyWith(color: accentColor, fontSize: 24.sp, letterSpacing: -1, fontWeight: FontWeight.w900, height: 1),
                  ),
                  Text(
                    unit.toUpperCase(),
                    style: context.captionBold.copyWith(color: unitColor, fontSize: 8.sp, letterSpacing: 0.5),
                  ),
                  const Spacer(),
                  Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.captionMicro.copyWith(color: labelColor, fontWeight: FontWeight.w900, fontSize: 7.sp, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
