import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class WeeklyRecapScreen extends StatelessWidget {
  const WeeklyRecapScreen({super.key, this.insight});
  final AIInsight? insight;

  @override
  Widget build(BuildContext context) {
    final recap = insight?.weeklyRecap;

    if (insight != null) {
      unawaited(sl<AnalyticsService>().logEvent(name: 'view_weekly_recap', parameters: {'avg_score': recap?.avgScore ?? 0, 'foods_logged': recap?.foodsLogged ?? 0}));
    }

    if (insight == null) {
      return const _RecapLoadingView();
    }

    final scheme = context.appColorScheme;
    return Scaffold(
      backgroundColor: scheme.cardBackground,
      body: CustomScrollView(
        slivers: [
          const GutSliverAppBar(title: AppStrings.weeklyRecap, showBrandingIcon: false),
          SliverPadding(
            padding: EdgeInsets.all(AppSizes.p20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _RecapHeroSection(recap: recap),
                Gap.h24,
                _PerformanceGrid(recap: recap),
                Gap.h24,
                _WeeklyPulseCard(insight: insight!),
                Gap.h24,
                _PatternsHighlights(highlights: recap?.highlights ?? []),
                Gap.h40,
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecapHeroSection extends StatelessWidget {
  const _RecapHeroSection({required this.recap});
  final WeeklyRecap? recap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final score = recap?.avgScore ?? 0;
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("AVERAGE SCORE", style: context.bodyBold.copyWith(fontSize: 12.sp, letterSpacing: 0.5, color: scheme.textPrimary)),
                  Text(recap?.dateRange ?? "Last 7 Days", style: context.caption.copyWith(fontSize: 10.sp, color: scheme.textMuted)),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: scheme.cardBackground,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: scheme.border),
                ),
                child: Text(
                  recap?.scoreSub?.toUpperCase() ?? "STABLE",
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
                  painter: _GaugePainter(value: score / 100, color: scheme.textPrimary),
                ),
              ),
              Positioned(
                bottom: 15.w,
                child: Text(
                  "$score",
                  style: context.bodyBold.copyWith(fontSize: 40.sp, fontWeight: FontWeight.w900, height: 1, color: scheme.textPrimary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PerformanceGrid extends StatelessWidget {
  const _PerformanceGrid({required this.recap});
  final WeeklyRecap? recap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: "PEAK DAY",
            value: recap?.bestDay ?? "N/A",
            subtitle: "Highest Score",
            icon: AppIcons.star,
            color: AppPalette.lime,
          ),
        ),
        Gap.w20,
        Expanded(
          child: _StatCard(
            label: "LOGS",
            value: "${recap?.foodsLogged ?? 0}",
            subtitle: "Total Entries",
            icon: AppIcons.clipboardList,
            color: const Color(0xFF5D78FF),
            isDark: true,
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
    final secondaryColor = isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5);

    return Container(
      padding: EdgeInsets.all(20.w),
      height: 150.h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(32.r),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
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
                decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.2) : Colors.white, shape: BoxShape.circle),
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
          Text(value.toUpperCase(), style: context.bodyBold.copyWith(fontSize: 14.sp, color: textColor, height: 1.1), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(subtitle, style: context.caption.copyWith(fontSize: 9.sp, color: secondaryColor), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _WeeklyPulseCard extends StatelessWidget {
  const _WeeklyPulseCard({required this.insight});
  final AIInsight insight;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final profile = context.watch<ProfileNotifier>();
    final streak = profile.streak;
    final healingTrend = insight.healingTrend ?? AppStrings.optimizing;
    final description = '${AppStrings.weeklyRecapNarrative}$streak${AppStrings.narrativeDaysAndGut}$healingTrend${AppStrings.narrativeBasedOnLogs}';

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
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(color: scheme.cardBackground, shape: BoxShape.circle, border: Border.all(color: scheme.border)),
                child: Icon(AppIcons.barChart, size: 18.w, color: scheme.textPrimary),
              ),
              Gap.w12,
              Text("WEEKLY PULSE", style: context.bodyBold.copyWith(fontSize: 12.sp, letterSpacing: 0.5, color: scheme.textPrimary)),
            ],
          ),
          Gap.h16,
          Text(
            description,
            style: context.bodySm.copyWith(color: scheme.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _PatternsHighlights extends StatelessWidget {
  const _PatternsHighlights({required this.highlights});
  final List<RecapHighlight> highlights;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    if (highlights.isEmpty) return const SizedBox.shrink();

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
                decoration: BoxDecoration(color: AppPalette.lime.withOpacity(0.2), shape: BoxShape.circle),
                child: Icon(AppIcons.brain, size: 16.w, color: AppPalette.lime),
              ),
              Gap.w12,
              Text("NEW DISCOVERIES", style: context.bodyBold.copyWith(color: scheme.cardBackground, fontSize: 13.sp, letterSpacing: 0.5)),
            ],
          ),
          Gap.h20,
          ...highlights.map((h) => Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Row(
              children: [
                Icon(AppIcons.checkCircle, color: AppPalette.lime, size: 16.w),
                Gap.w12,
                Expanded(
                  child: Text(
                    h.text,
                    style: context.bodySm.copyWith(color: scheme.cardBackground.withOpacity(0.8), height: 1.2),
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

    final needlePaint = Paint()..color = color.withOpacity(0.2)..style = PaintingStyle.stroke..strokeWidth = 1.0;
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

class _RecapLoadingView extends StatelessWidget {
  const _RecapLoadingView();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appColorScheme.cardBackground,
    body: Padding(
      padding: EdgeInsets.all(AppSizes.p20),
      child: const ShimmerGridLoader(variant: ShimmerVariant.recap),
    ),
  );
}
