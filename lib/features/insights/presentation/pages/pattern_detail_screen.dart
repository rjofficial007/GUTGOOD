import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/models/pattern_occurrence.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';

class PatternDetailScreen extends StatelessWidget {
  const PatternDetailScreen({super.key, required this.pattern});
  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final patternName = InsightUiUtils.getPatternName(pattern.type);
    return Scaffold(
      backgroundColor: scheme.cardBackground,
      body: CustomScrollView(
        slivers: [
          GutSliverAppBar(
            title: 'PATTERN: ${patternName.toUpperCase()}',
            showBrandingIcon: false,
          ),
          SliverPadding(
            padding: EdgeInsets.all(AppSizes.p20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ScoreHeroSection(pattern: pattern),
                Gap.h24,
                _StatisticalSplitGrid(pattern: pattern),
                Gap.h24,
                _InvolvedIngredientsCard(pattern: pattern),
                Gap.h24,
                _DetailedObservationCard(pattern: pattern),
                if (pattern.occurrences.isNotEmpty) ...[
                  Gap.h24,
                  _OccurrenceTimelineSection(occurrences: pattern.occurrences),
                ],
                Gap.h24,
                _ActionPlanSection(pattern: pattern),
                Gap.h40,
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreHeroSection extends StatelessWidget {
  const _ScoreHeroSection({required this.pattern});
  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final evidence = pattern.evidenceRatio;
    
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(color: scheme.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pattern.trigger.toUpperCase(),
                      style: context.bodyBold.copyWith(fontSize: 13.sp, color: scheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "DETECTED TRIGGER",
                      style: context.caption.copyWith(fontSize: 10.sp, color: scheme.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: scheme.cardBackground,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: scheme.border),
                ),
                child: Text(
                  pattern.confidence.toUpperCase(),
                  style: context.bodyBold.copyWith(fontSize: 9.sp, color: scheme.textPrimary),
                ),
              ),
            ],
          ),
          Gap.h32,
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180.w,
                height: 120.w,
                child: CustomPaint(
                  painter: _GaugePainter(value: evidence, color: scheme.textPrimary),
                ),
              ),
              Positioned(
                bottom: 15.w,
                child: Column(
                  children: [
                    Text(
                      "${(evidence * 100).toInt()}%",
                      style: context.bodyBold.copyWith(fontSize: 40.sp, fontWeight: FontWeight.w900, height: 1, color: scheme.textPrimary),
                    ),
                    Text(
                      "Probability",
                      style: context.caption.copyWith(color: scheme.textMuted, fontSize: 10.sp),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatisticalSplitGrid extends StatelessWidget {
  const _StatisticalSplitGrid({required this.pattern});
  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: "REACTIVE",
            value: "${pattern.positiveCount}",
            subtitle: "Total hits",
            icon: AppIcons.flame,
            color: const Color(0xFFFF9898),
          ),
        ),
        Gap.w20,
        Expanded(
          child: _StatCard(
            label: "STABLE",
            value: "${pattern.negativeCount}",
            subtitle: "Asymptomatic",
            icon: AppIcons.checkCircle,
            color: AppPalette.lime,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isDark = false,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5);

    return Container(
      padding: EdgeInsets.all(20.w),
      height: 150.h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(32.r),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.white, shape: BoxShape.circle),
                child: Icon(icon, size: 16.w, color: isDark ? Colors.white : Colors.black),
              ),
              Row(
                children: [
                  Container(width: 4.w, height: 4.w, decoration: BoxDecoration(color: textColor, shape: BoxShape.circle)),
                  Gap.w4,
                  Container(width: 4.w, height: 4.w, decoration: BoxDecoration(color: textColor, shape: BoxShape.circle)),
                ],
              ),
            ],
          ),
          const Spacer(),
          Text(label, style: context.bodyBold.copyWith(fontSize: 10.sp, color: secondaryColor)),
          Text(value.toUpperCase(), style: context.bodyBold.copyWith(fontSize: 15.sp, height: 1.1, color: textColor)),
          Text(subtitle, style: context.caption.copyWith(fontSize: 9.sp, color: secondaryColor)),
        ],
      ),
    );
  }
}

class _InvolvedIngredientsCard extends StatelessWidget {
  const _InvolvedIngredientsCard({required this.pattern});
  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    if (pattern.involvedFoods.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(color: scheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.utensils, size: 18.w, color: scheme.textPrimary),
              Gap.w12,
              Text("INVOLVED INGREDIENTS", style: context.bodyBold.copyWith(fontSize: 12.sp, letterSpacing: 0.5, color: scheme.textPrimary)),
            ],
          ),
          Gap.h20,
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: pattern.involvedFoods.map((f) => Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: scheme.aiResponseBackground,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: scheme.border),
              ),
              child: Text(
                f.toUpperCase(),
                style: context.bodyBold.copyWith(fontSize: 10.sp, color: scheme.textPrimary),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _DetailedObservationCard extends StatelessWidget {
  const _DetailedObservationCard({required this.pattern});
  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(color: scheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.search, size: 18.w, color: scheme.textPrimary),
              Gap.w12,
              Text("PATTERN ANALYSIS", style: context.bodyBold.copyWith(fontSize: 12.sp, letterSpacing: 0.5, color: scheme.textPrimary)),
            ],
          ),
          Gap.h16,
          Text(
            pattern.description,
            style: context.bodySm.copyWith(color: scheme.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _OccurrenceTimelineSection extends StatelessWidget {
  const _OccurrenceTimelineSection({required this.occurrences});
  final List<PatternOccurrence> occurrences;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(color: scheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.history, size: 18.w, color: scheme.textPrimary),
              Gap.w12,
              Text("RECENT OCCURRENCES", style: context.bodyBold.copyWith(fontSize: 12.sp, letterSpacing: 0.5, color: scheme.textPrimary)),
            ],
          ),
          Gap.h24,
          ...List.generate(occurrences.length, (i) {
            final o = occurrences[i];
            final isLast = i == occurrences.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12.h),
              child: _TimelineTile(o: o),
            );
          }),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.o});
  final PatternOccurrence o;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: scheme.aiResponseBackground,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: scheme.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: scheme.elevatedSurface, 
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: scheme.border.withValues(alpha: 0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: o.imageUrl != null && o.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(imageUrl: o.imageUrl!, fit: BoxFit.cover)
                  : Icon(AppIcons.utensils, color: scheme.textPrimary, size: 20),
            ),
          ),
          Gap.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  o.mealName, 
                  style: context.bodyBold.copyWith(fontSize: 13.sp, color: scheme.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "${o.date} • ${o.reaction}", 
                  style: context.caption.copyWith(fontSize: 10.sp, color: scheme.textMuted),
                ),
              ],
            ),
          ),
          Icon(AppIcons.chevronRight, color: scheme.textMuted, size: 16.w),
        ],
      ),
    );
  }
}

class _ActionPlanSection extends StatelessWidget {
  const _ActionPlanSection({required this.pattern});
  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final steps = [pattern.recommendation ?? 'Keep monitoring your reactions', 'Log your next 3 meals with ${pattern.trigger}'];
    
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: scheme.textPrimary,
        borderRadius: BorderRadius.circular(32.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppPalette.lime.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(AppIcons.target, size: 16.w, color: AppPalette.lime),
              ),
              Gap.w12,
              Text(
                "ACTION PLAN",
                style: context.bodyBold.copyWith(color: scheme.cardBackground, fontSize: 13.sp, letterSpacing: 0.5),
              ),
            ],
          ),
          Gap.h20,
          ...steps.map((step) => Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 2.h),
                  child: Icon(AppIcons.checkCircle, color: AppPalette.lime, size: 16.w),
                ),
                Gap.w12,
                Expanded(
                  child: Text(
                    step,
                    style: context.bodySm.copyWith(color: scheme.cardBackground.withValues(alpha: 0.8), height: 1.3),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.value, required this.color});
  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 10.w);
    final radius = size.width / 2;

    final bgPaint = Paint()..color = AppPalette.gray200..style = PaintingStyle.stroke..strokeWidth = 1.5;
    final progressPaint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.5;

    for (var i = 0; i <= 60; i++) {
      final angle = math.pi + (i / 60) * math.pi;
      final isMajor = i % 10 == 0;
      final tickLen = isMajor ? 10.0 : 5.0;
      canvas.drawLine(
        Offset(center.dx + (radius - tickLen) * math.cos(angle), center.dy + (radius - tickLen) * math.sin(angle)),
        Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle)),
        bgPaint,
      );
    }

    final activeTicks = (value * 60).toInt();
    for (var i = 0; i <= activeTicks; i++) {
      final angle = math.pi + (i / 60) * math.pi;
      final isMajor = i % 10 == 0;
      final tickLen = isMajor ? 14.0 : 8.0;
      canvas.drawLine(
        Offset(center.dx + (radius - tickLen) * math.cos(angle), center.dy + (radius - tickLen) * math.sin(angle)),
        Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle)),
        progressPaint,
      );
    }

    final needlePaint = Paint()..color = color.withValues(alpha: 0.2)..style = PaintingStyle.stroke..strokeWidth = 1.0;
    final indicatorAngle = math.pi + value * math.pi;
    final dotPos = Offset(center.dx + radius * math.cos(indicatorAngle), center.dy + radius * math.sin(indicatorAngle));
    canvas.drawLine(center, dotPos, needlePaint);
    canvas.drawCircle(dotPos, 5, Paint()..color = color);
    canvas.drawCircle(dotPos, 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(center, 4, Paint()..color = AppPalette.gray100);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
