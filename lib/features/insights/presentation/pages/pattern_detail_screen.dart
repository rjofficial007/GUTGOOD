import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/models/pattern_occurrence.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/image_utils.dart';
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/product_details/presentation/widgets/scan_result_widgets.dart';
import 'package:shimmer/shimmer.dart';

class PatternDetailScreen extends StatelessWidget {
  const PatternDetailScreen({super.key, required this.pattern});
  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final accentColor = InsightUiUtils.getPatternColor(pattern.type);

    return Scaffold(
      backgroundColor: scheme.cardBackground,
      body: CustomScrollView(
        slivers: [
          GutSliverAppBar(title: InsightUiUtils.getPatternName(pattern.type).toUpperCase(), centerTitle: true, showBrandingIcon: false),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSizes.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Premium Smart Alert Hero
                  DashboardEntrance(
                    delay: 50,
                    child: _SmartAlertHero(pattern: pattern, accentColor: accentColor),
                  ),
                  Gap.h16,

                  // 2. Moments We Noticed
                  if (pattern.occurrences.isNotEmpty) ...[
                    DashboardEntrance(
                      delay: 150,
                      child: _MomentsSection(occurrences: pattern.occurrences, reaction: pattern.reaction),
                    ),
                    Gap.h16,
                  ],

                  // 3. Worth Watching / Progress
                  DashboardEntrance(
                    delay: 250,
                    child: _WorthWatchingSection(pattern: pattern, accentColor: accentColor),
                  ),
                  Gap.h16,

                  // 4. Next Steps
                  DashboardEntrance(
                    delay: 350,
                    child: _NextStepsSection(pattern: pattern, accentColor: accentColor),
                  ),
                  Gap.h32,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmartAlertHero extends StatelessWidget {
  const _SmartAlertHero({required this.pattern, required this.accentColor});
  final BodyPattern pattern;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = context.appColorScheme;
    final cardBg = isDark ? AppPalette.black : scheme.textPrimary;
    const contentColor = AppPalette.white;

    return BentoCard(
      padding: EdgeInsets.zero,
      backgroundColor: cardBg,
      borderColor: contentColor.withAlpha(isDark ? 20 : 15),
      showShadow: true,
      child: Stack(
        children: [
          // 🌈 Vibrant Corner Glow
          Positioned(
            right: -60,
            top: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [accentColor.withAlpha(isDark ? 160 : 140), accentColor.withAlpha(40), Colors.transparent], stops: const [0.0, 0.4, 1.0]),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: contentColor.withAlpha(20), borderRadius: BorderRadius.circular(100)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(AppIcons.salad, size: 10, color: accentColor),
                      Gap.w4,
                      Text(
                        'SMART ALERT',
                        style: context.captionBold.copyWith(color: contentColor, fontSize: 8.sp, letterSpacing: 1.5, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                Gap.h16,
                // Title
                Text(
                  pattern.trigger.toUpperCase(),
                  style: context.displayHero.copyWith(fontSize: 22.sp, height: 1.0, color: contentColor, fontWeight: FontWeight.w900, letterSpacing: -1),
                ),
                Row(
                  children: [
                    Icon(Icons.arrow_forward_rounded, color: accentColor, size: 18.sp),
                    Gap.w4,
                    Expanded(
                      child: Text(
                        pattern.reaction.toUpperCase(),
                        style: context.displayHero.copyWith(fontSize: 22.sp, height: 1.1, color: accentColor, fontWeight: FontWeight.w900, letterSpacing: -1),
                      ),
                    ),
                  ],
                ),
                Gap.h12,
                // Description
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.55),
                  child: Text(
                    pattern.description,
                    style: context.bodySm.copyWith(color: contentColor.withAlpha(150), height: 1.4),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Gap.h16,
                // Status / Confidence
                Row(
                  children: [
                    Text(
                      '${pattern.confidence.toUpperCase()} STRENGTH',
                      style: context.headingSm.copyWith(color: accentColor, fontWeight: FontWeight.bold, fontSize: 14.sp),
                    ),
                    Gap.w6,
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: accentColor.withAlpha(100), blurRadius: 4)],
                      ),
                    ),
                    Gap.w6,
                    Text(
                      '${pattern.frequency} OCCURRENCES',
                      style: context.captionBold.copyWith(color: contentColor.withAlpha(120), fontSize: 10.sp),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  DashedLinePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashHeight = 5.0;
    const dashSpace = 3.0;
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _MomentsSection extends StatelessWidget {
  const _MomentsSection({required this.occurrences, required this.reaction});
  final List<PatternOccurrence> occurrences;
  final String reaction;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 16, color: scheme.textPrimary),
            Gap.w8,
            Text('THE MOMENTS WE NOTICED', style: context.captionBold.copyWith(color: scheme.textPrimary, letterSpacing: 0.5)),
          ],
        ),
        Gap.h4,
        Text('These meals were followed by ${reaction.toLowerCase()}.', style: context.caption.copyWith(color: scheme.textSecondary)),
        Gap.h16,
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (var i = 0; i < occurrences.length; i++) ...[_MomentCard(occurrence: occurrences[i], index: i + 1), if (i < occurrences.length - 1) Gap.w12],
            ],
          ),
        ),
      ],
    );
  }
}

class _MomentCard extends StatelessWidget {
  const _MomentCard({required this.occurrence, required this.index});
  final PatternOccurrence occurrence;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final displayImageUrl = occurrence.imageUrl ?? getDynamicImageUrl(occurrence.mealName);

    return Container(
      width: 150.w,
      decoration: BoxDecoration(
        color: scheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.borderSubtle),
        boxShadow: [BoxShadow(color: scheme.surfaceSubtle, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / Placeholder
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: CachedNetworkImage(
                  imageUrl: displayImageUrl,
                  height: 100.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: AppPalette.shimmerBase(context),
                    highlightColor: AppPalette.shimmerHighlight(context),
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (_, _, _) => Container(
                    height: 100.h,
                    width: double.infinity,
                    color: scheme.elevatedSurface,
                    child: Icon(AppIcons.utensils, color: scheme.textMuted, size: 28),
                  ),
                ),
              ),
              // Index Badge
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(color: AppPalette.white, shape: BoxShape.circle),
                  child: Center(
                    child: Text('$index', style: context.captionBold.copyWith(color: AppPalette.black, fontSize: 10)),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  occurrence.mealName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.captionBold.copyWith(color: scheme.textPrimary, fontSize: 11.sp),
                ),
                Gap.h4,
                Text(occurrence.date, style: context.captionMicro.copyWith(color: scheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorthWatchingSection extends StatelessWidget {
  const _WorthWatchingSection({required this.pattern, required this.accentColor});
  final BodyPattern pattern;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isHigh = pattern.confidence == BodyPattern.confidenceHigh;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withAlpha(10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withAlpha(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(AppIcons.target, size: 16, color: accentColor),
                    Gap.w8,
                    Text(isHigh ? 'VERIFIED PATTERN' : 'WORTH WATCHING', style: context.captionBold.copyWith(color: scheme.textPrimary, letterSpacing: 0.5)),
                  ],
                ),
                Gap.h6,
                Text(
                  isHigh
                      ? 'This association is statistically significant. Reducing ${pattern.trigger.toLowerCase()} may improve your symptoms.'
                      : '${pattern.frequency} times is enough to notice, but not enough to know for sure.',
                  style: context.caption.copyWith(color: scheme.textSecondary, height: 1.3),
                ),
              ],
            ),
          ),
          Gap.w16,
          // Mini Bar Chart
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar(16.h, accentColor.withAlpha(80)),
              Gap.w2,
              _buildBar(28.h, accentColor.withAlpha(150)),
              Gap.w2,
              _buildBar(40.h, accentColor),
              Gap.w2,
              _buildBar(52.h, accentColor.withAlpha(50), isDashed: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double height, Color color, {bool isDashed = false}) => Container(
      width: 12.w,
      height: height,
      decoration: BoxDecoration(
        color: isDashed ? Colors.transparent : color,
        borderRadius: BorderRadius.circular(4),
        border: isDashed ? Border.all(color: color, width: 1, style: BorderStyle.solid) : null,
      ),
      child: isDashed
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color, width: 1.5, style: BorderStyle.solid),
              ),
            )
          : null,
    );
}

class _NextStepsSection extends StatelessWidget {
  const _NextStepsSection({required this.pattern, required this.accentColor});
  final BodyPattern pattern;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb_outline_rounded, size: 18, color: scheme.textPrimary),
            Gap.w8,
            Text('YOUR NEXT STEPS', style: context.captionBold.copyWith(color: scheme.textPrimary, letterSpacing: 0.5)),
          ],
        ),
        Gap.h16,
        _ActionItem(icon: Icons.check_circle_outline_rounded, iconColor: Colors.teal, title: 'What you can do', subtitle: pattern.recommendation ?? 'Keep monitoring your intake.', onTap: () {}),
        Gap.h12,
        _ActionItem(icon: Icons.chat_bubble_outline_rounded, iconColor: Colors.indigo, title: 'Ask GutGood', subtitle: 'Ask about "${pattern.trigger} and ${pattern.reaction}"', onTap: () {}),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconColor.withAlpha(20), shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.bodyBold.copyWith(color: scheme.textPrimary, fontSize: 13.sp),
                  ),
                  Gap.h2,
                  Text(
                    subtitle,
                    style: context.caption.copyWith(color: scheme.textSecondary, fontSize: 11.sp),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: scheme.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
