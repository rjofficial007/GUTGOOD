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
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:gutgood/core/utils/quota_guard.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_dashboard_sections.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    return Scaffold(
      backgroundColor: scheme.cardBackground,
      body: Consumer<InsightsNotifier>(
        builder: (context, notifier, _) {
          final latestInsight = notifier.latestInsight;
          final prioritizedPatterns = notifier.prioritizedPatterns;
          final isLoading = notifier.isLoading;

          if (isLoading) return const Center(child: CircularProgressIndicator());
          if (latestInsight == null) return const _NoInsightsState();

          return CustomScrollView(
            slivers: [
              GutSliverAppBar(
                title: AppStrings.insights,
                actions: [
                  IconButton(
                    icon: Icon(Icons.history, color: scheme.textPrimary),
                    onPressed: () => unawaited(context.push(AppRoutes.insightHistory)),
                  ),
                  Gap.w10,
                ],
              ),
              SliverPadding(
                padding: EdgeInsets.all(AppSizes.p20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _ScoreHeroSection(data: latestInsight),
                    Gap.h24,
                    _StrategyGrid(data: latestInsight),
                    Gap.h24,
                    _HighlightsSection(data: latestInsight),
                    Gap.h24,
                    _DetailedTrendCard(
                      title: "POSITIVE PROGRESS",
                      trend: latestInsight.healingTrend ?? "Your gut is responding well to specific nutrient-dense choices.",
                      foods: latestInsight.healingFoods,
                      color: AppPalette.lime,
                      icon: AppIcons.bowl,
                      label: "Boosters",
                    ),
                    Gap.h20,
                    _DetailedTrendCard(
                      title: "CAUTION AREAS",
                      trend: latestInsight.triggerTrend ?? "We've identified certain items that may be causing temporary sensitivity.",
                      foods: latestInsight.triggerFoods,
                      color: const Color(0xFFFF9898),
                      icon: AppIcons.pepper,
                      label: "Triggers",
                    ),
                    Gap.h24,
                    _PatternSection(patterns: prioritizedPatterns.isNotEmpty ? prioritizedPatterns : latestInsight.detectedPatterns),
                    if (latestInsight.topInsight != null) ...[
                      Gap.h24,
                      ModernSmartAlert(insight: latestInsight.topInsight!),
                    ],
                    Gap.h24,
                    _WeeklyRecapBanner(data: latestInsight),
                    Gap.h40,
                  ]),
                ),
              ),
            ],
          );
        },
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
                  Text("Daily snapshot", style: context.caption.copyWith(fontSize: 10.sp, color: scheme.textMuted)),
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
            label: "STRATEGY",
            value: data.healingGoal ?? data.triggerSymptom ?? "Monitoring",
            subtitle: "Primary focus",
            icon: AppIcons.target,
            color: const Color(0xFF5D78FF),
            isDark: true,
          ),
        ),
        Gap.w20,
        Expanded(
          child: _StatCard(
            label: "STATUS",
            value: data.confidenceLevel,
            subtitle: "Analysis level",
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
        Text("THIS WEEK'S HIGHLIGHTS", style: context.bodyBold.copyWith(fontSize: 12.sp, letterSpacing: 1, color: scheme.textMuted)),
        Gap.h12,
        Row(
          children: [
            if (data.topHealing != null)
              Expanded(
                child: _StatCard(
                  label: "CHAMPION",
                  value: data.topHealing!.food,
                  subtitle: data.topHealing!.effects,
                  icon: InsightUiUtils.getReactionIcon(data.topHealing!.emoji),
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
                  icon: InsightUiUtils.getReactionIcon(data.topTrigger!.emoji),
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
    final scheme = context.appColorScheme;
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
  const _DetailedTrendCard({
    required this.title,
    required this.trend,
    required this.foods,
    required this.color,
    required this.icon,
    required this.label,
  });

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
              Text(title, style: context.bodyBold.copyWith(fontSize: 12.sp, letterSpacing: 0.5, color: scheme.textPrimary)),
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
          Text(
            trend,
            style: context.bodySm.copyWith(color: scheme.textSecondary, height: 1.4),
          ),
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
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.aiResponseBackground,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: scheme.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          InsightUiUtils.getReactionIcon(food is HealingFood ? food.emoji : (food as TriggerFood).emoji),
                          size: 14.sp,
                          color: scheme.textPrimary,
                        ),
                        Gap.w6,
                        Text(name.toUpperCase(), style: context.bodyBold.copyWith(fontSize: 10.sp, color: scheme.textPrimary)),
                      ],
                    ),
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
                    Text("BODY PATTERNS", style: context.bodyBold.copyWith(fontSize: 12.sp, color: scheme.textPrimary)),
                    Text("Detected behaviors", style: context.caption.copyWith(fontSize: 10.sp, color: scheme.textMuted)),
                  ],
                ),
              ),
              Icon(AppIcons.chevronRight, size: 14, color: scheme.textMuted),
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
            color: scheme.cardBackground,
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
                    Text(
                      pattern.trigger.toUpperCase(),
                      style: context.bodyBold.copyWith(fontSize: 11.sp, color: scheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      InsightUiUtils.getPatternName(pattern.type),
                      style: context.caption.copyWith(fontSize: 9.sp, color: scheme.textMuted),
                    ),
                  ],
                ),
              ),
              Text(
                "${pattern.frequency}x",
                style: context.bodyBold.copyWith(fontSize: 12.sp, color: scheme.textPrimary),
              ),
              Gap.w8,
              Icon(Icons.chevron_right, size: 16, color: scheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyRecapBanner extends StatelessWidget {
  const _WeeklyRecapBanner({required this.data});
  final AIInsight data;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: scheme.textPrimary,
        borderRadius: BorderRadius.circular(28.r),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppPalette.lime.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(AppIcons.calendar, size: 20.w, color: AppPalette.lime),
          ),
          Gap.w16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "WEEKLY RECAP",
                  style: context.bodyBold.copyWith(color: scheme.cardBackground, fontSize: 13.sp),
                ),
                Text(
                  "Review your last 7 days",
                  style: context.caption.copyWith(color: scheme.cardBackground.withOpacity(0.5)),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              if (await QuotaGuard.check(context, type: QuotaType.premium)) {
                if (context.mounted) {
                  unawaited(context.push(AppRoutes.weeklyRecap, extra: data));
                }
              }
            },
            child: Text(
              "Open",
              style: context.bodyBold.copyWith(color: AppPalette.lime),
            ),
          ),
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

    final bgPaint = Paint()
      ..color = AppPalette.gray200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

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
      final isMajor = i % 10 == 0;      final tickLen = isMajor ? 14.0 : 8.0;

      final start = Offset(
        center.dx + (radius - tickLen) * math.cos(angle),
        center.dy + (radius - tickLen) * math.sin(angle),
      );
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(start, end, progressPaint);
    }

    final needlePaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final indicatorAngle = math.pi + value * math.pi;
    final dotPos = Offset(
      center.dx + radius * math.cos(indicatorAngle),
      center.dy + radius * math.sin(indicatorAngle),
    );

    canvas.drawLine(center, dotPos, needlePaint);
    canvas.drawCircle(dotPos, 4, Paint()..color = color);
    canvas.drawCircle(dotPos, 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _NoInsightsState extends StatelessWidget {
  const _NoInsightsState();

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final notifier = context.watch<InsightsNotifier>();
    final meals = notifier.totalMeals;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSizes.p40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(AppSizes.p24),
              decoration: BoxDecoration(color: scheme.elevatedSurface, shape: BoxShape.circle, border: Border.all(color: scheme.border)),
              child: Icon(AppIcons.barChart, size: 48, color: scheme.textPrimary),
            ),
            Gap.h24,
            Text(
              AppStrings.keepLoggingForPatterns,
              style: context.bodyBold.copyWith(fontSize: 18.sp, color: scheme.textPrimary),
              textAlign: TextAlign.center,
            ),
            Gap.h12,
            Text(
              AppStrings.understandBodyImpact,
              textAlign: TextAlign.center,
              style: context.caption.copyWith(color: scheme.textMuted),
            ),
            Gap.h32,
            _ProgressRow(label: "LOGS", progress: (meals / 3).clamp(0.0, 1.0), count: meals, total: 3),
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.label, required this.progress, required this.count, required this.total});
  final String label;
  final double progress;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label.toUpperCase(), style: context.eyebrow.copyWith(color: scheme.textMuted)),
            Text(
              '$count/$total',
              style: context.caption.copyWith(fontWeight: FontWeight.bold, color: scheme.textPrimary),
            ),
          ],
        ),
        Gap.h6,
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: scheme.border.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(scheme.textPrimary),
          ),
        ),
      ],
    );
  }
}
