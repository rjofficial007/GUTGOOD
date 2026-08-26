import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/date_formatter.dart';
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:gutgood/core/utils/quota_guard.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_dashboard_sections.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class InsightDetailScreen extends StatelessWidget {
  const InsightDetailScreen({super.key, required this.insight});
  final AIInsight insight;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final dateStr = DateFormatter.formatDate(insight.updatedAt);

    return Scaffold(
      backgroundColor: scheme.cardBackground,
      body: CustomScrollView(
        slivers: [
          GutSliverAppBar(title: 'SNAPSHOT: ${dateStr.toUpperCase()}', showBrandingIcon: false),
          SliverPadding(
            padding: EdgeInsets.all(AppSizes.p20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ScoreHeroSection(data: insight),
                Gap.h24,
                _StrategyGrid(data: insight),
                Gap.h24,
                _HighlightsSection(data: insight),
                Gap.h24,
                _DetailedTrendCard(
                  title: "POSITIVE PROGRESS",
                  trend: insight.healingTrend ?? "Analysis of your gut health boosters for this period.",
                  foods: insight.healingFoods,
                  color: AppPalette.lime,
                  icon: AppIcons.zap,
                  label: "Boosters",
                ),
                Gap.h20,
                _DetailedTrendCard(
                  title: "CAUTION AREAS",
                  trend: insight.triggerTrend ?? "Sensitive items identified during this analysis period.",
                  foods: insight.triggerFoods,
                  color: const Color(0xFFFF9898),
                  icon: AppIcons.alertTriangle,
                  label: "Triggers",
                ),
                Gap.h24,
                _PatternSection(patterns: insight.detectedPatterns),
                if (insight.topInsight != null) ...[
                  Gap.h24,
                  ModernSmartAlert(insight: insight.topInsight!),
                ],
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
  const _ScoreHeroSection({required this.data});
  final AIInsight data;

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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("GUT SCORE", style: context.bodyBold.copyWith(fontSize: 12.sp, letterSpacing: 0.5, color: scheme.textPrimary)),
                  Text("Historical Snapshot", style: context.caption.copyWith(fontSize: 10.sp, color: scheme.textMuted)),
                ],
              ),
              if (data.scoreDiff != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: data.scoreDiff!.startsWith('+') ? AppPalette.greenSoft : AppPalette.redSoft,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    data.scoreDiff!,
                    style: context.bodyBold.copyWith(fontSize: 9.sp, color: data.scoreDiff!.startsWith('+') ? AppPalette.green : AppPalette.red),
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
                  painter: _GaugePainter(value: data.gutScore / 100, color: scheme.textPrimary),
                ),
              ),
              Positioned(
                bottom: 15.w,
                child: Text(
                  "${data.gutScore}",
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

class _StrategyGrid extends StatelessWidget {
  const _StrategyGrid({required this.data});
  final AIInsight data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: "FOCUS",
            value: data.healingGoal ?? data.triggerSymptom ?? "Monitoring",
            subtitle: "Historical goal",
            icon: AppIcons.target,
            color: const Color(0xFF5D78FF),
            isDark: true,
          ),
        ),
        Gap.w20,
        Expanded(
          child: _StatCard(
            label: "CONFIDENCE",
            value: data.confidenceLevel,
            subtitle: "Analysis strength",
            icon: AppIcons.trendingUp,
            color: AppPalette.lime,
          ),
        ),
      ],
    );
  }
}

class _HighlightsSection extends StatelessWidget {
  const _HighlightsSection({required this.data});
  final AIInsight data;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    if (data.topHealing == null && data.topTrigger == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("SNAPSHOT HIGHLIGHTS", style: context.bodyBold.copyWith(fontSize: 11.sp, letterSpacing: 1, color: scheme.textMuted)),
        Gap.h12,
        Row(
          children: [
            if (data.topHealing != null)
              Expanded(
                child: _StatCard(
                  label: "CHAMPION",
                  value: data.topHealing!.food,
                  subtitle: data.topHealing!.effects,
                  icon: AppIcons.trophy,
                  color: AppPalette.greenSoft,
                ),
              ),
            if (data.topHealing != null && data.topTrigger != null) Gap.w12,
            if (data.topTrigger != null)
              Expanded(
                child: _StatCard(
                  label: "REACTIVE",
                  value: data.topTrigger!.food,
                  subtitle: data.topTrigger!.effects,
                  icon: AppIcons.alertCircle,
                  color: AppPalette.redSoft,
                ),
              ),
          ],
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

class _DetailedTrendCard extends StatelessWidget {
  const _DetailedTrendCard({required this.title, required this.trend, required this.foods, required this.color, required this.icon, required this.label});
  final String title;
  final String trend;
  final List<dynamic> foods;
  final Color color;
  final IconData icon;
  final String label;

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
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(icon, size: 16.w, color: scheme.textPrimary),
              ),
              Gap.w12,
              Text(title, style: context.bodyBold.copyWith(fontSize: 11.sp, letterSpacing: 0.5, color: scheme.textPrimary)),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: scheme.aiResponseBackground, 
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: scheme.border.withOpacity(0.5)),
                ),
                child: Text("${foods.length} $label", style: context.bodyBold.copyWith(fontSize: 10.sp, color: scheme.textPrimary)),
              ),
            ],
          ),
          Gap.h16,
          Text(trend, style: context.bodySm.copyWith(color: scheme.textSecondary, height: 1.4)),
          if (foods.isNotEmpty) ...[
            Gap.h20,
            SizedBox(
              height: 32.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: foods.length,
                separatorBuilder: (_, __) => Gap.w8,
                itemBuilder: (context, index) {
                  final food = foods[index];
                  final name = food is HealingFood ? food.name : (food as TriggerFood).name;
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.aiResponseBackground,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: scheme.border),
                    ),
                    child: Text(name.toUpperCase(), style: context.bodyBold.copyWith(fontSize: 10.sp, color: scheme.textPrimary)),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PatternSection extends StatelessWidget {
  const _PatternSection({required this.patterns});
  final List<BodyPattern> patterns;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    if (patterns.isEmpty) return const SizedBox.shrink();

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
              Icon(AppIcons.brain, size: 18.w, color: scheme.textPrimary),
              Gap.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("IDENTIFIED PATTERNS", style: context.bodyBold.copyWith(fontSize: 12.sp, color: scheme.textPrimary)),
                    Text("Historical findings", style: context.caption.copyWith(fontSize: 10.sp, color: scheme.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          Gap.h20,
          ...patterns.take(3).map((p) => _PatternRowItem(pattern: p)),
        ],
      ),
    );
  }
}

class _PatternRowItem extends StatelessWidget {
  const _PatternRowItem({required this.pattern});
  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.patternDetail, extra: pattern),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: scheme.aiResponseBackground,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: scheme.border.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(color: scheme.elevatedSurface, shape: BoxShape.circle, border: Border.all(color: scheme.border)),
                child: Icon(InsightUiUtils.getPatternTypeIcon(pattern.type), size: 14.w, color: scheme.textPrimary),
              ),
              Gap.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pattern.trigger.toUpperCase(), style: context.bodyBold.copyWith(fontSize: 11.sp, color: scheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(InsightUiUtils.getPatternName(pattern.type), style: context.caption.copyWith(fontSize: 9.sp, color: scheme.textMuted)),
                  ],
                ),
              ),
              Text("${pattern.frequency}x", style: context.bodyBold.copyWith(fontSize: 12.sp, color: scheme.textPrimary)),
              Gap.w8,
              Icon(Icons.chevron_right, size: 16, color: scheme.textMuted),
            ],
          ),
        ),
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
    final center = Offset(size.width / 2, size.height - 5);
    final radius = size.width / 2;
    final bgPaint = Paint()..color = AppPalette.gray200..style = PaintingStyle.stroke..strokeWidth = 1.5;
    final progressPaint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.5;

    for (var i = 0; i <= 60; i++) {
      final angle = math.pi + (i / 60) * math.pi;
      final isMajor = i % 10 == 0;
      final tickLen = isMajor ? 8.0 : 4.0;
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
      final tickLen = isMajor ? 12.0 : 6.0;
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
    canvas.drawCircle(dotPos, 4, Paint()..color = color);
    canvas.drawCircle(dotPos, 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
