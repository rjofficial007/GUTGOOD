import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/widgets/analysis_card.dart';

class SmartInsightDetailScreen extends StatelessWidget {
  const SmartInsightDetailScreen({super.key, required this.insight});
  final InsightSummary insight;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Scaffold(
      backgroundColor: scheme.cardBackground,
      body: CustomScrollView(
        slivers: [
          const GutSliverAppBar(title: 'INTELLIGENCE DETAIL', showBrandingIcon: false),
          SliverPadding(
            padding: EdgeInsets.all(AppSizes.p20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _MainGaugeCard(insight: insight),
                Gap.h24,
                _StatisticalSplitRow(insight: insight),
                Gap.h24,
                _InvolvedFoodsGrid(insight: insight),
                Gap.h24,
                _DetailedObservationCard(insight: insight),
                Gap.h24,
                _ActionPlanSection(insight: insight),
                Gap.h40,
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MainGaugeCard extends StatelessWidget {
  const _MainGaugeCard({required this.insight});
  final InsightSummary insight;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final evidence = insight.evidenceRatio ?? 0.75;
    
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
                      insight.title.toUpperCase(),
                      style: context.bodyBold.copyWith(fontSize: 13.sp, color: scheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      insight.type.toUpperCase(),
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
                  (insight.strength ?? "Moderate").toUpperCase(),
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
                      style: context.bodyBold.copyWith(fontSize: 36.sp, fontWeight: FontWeight.w900, height: 1, color: scheme.textPrimary),
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

class _StatisticalSplitRow extends StatelessWidget {
  const _StatisticalSplitRow({required this.insight});
  final InsightSummary insight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: "REACTIVE",
            value: "${insight.positiveCount ?? 0}",
            subtitle: "Total hits",
            icon: AppIcons.flame,
            color: const Color(0xFFFF9898),
          ),
        ),
        Gap.w20,
        Expanded(
          child: _StatCard(
            label: "STABLE",
            value: "${insight.negativeCount ?? 0}",
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
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      height: 150.h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(32.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(icon, size: 16.w, color: Colors.black),
              ),
              Row(
                children: [
                  Container(width: 4.w, height: 4.w, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle)),
                  Gap.w4,
                  Container(width: 4.w, height: 4.w, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle)),
                ],
              ),
            ],
          ),
          const Spacer(),
          Text(label, style: context.bodyBold.copyWith(fontSize: 10.sp, color: Colors.black.withOpacity(0.5))),
          Text(value.toUpperCase(), style: context.bodyBold.copyWith(fontSize: 15.sp, height: 1.1, color: Colors.black)),
          Text(subtitle, style: context.caption.copyWith(fontSize: 9.sp, color: Colors.black.withOpacity(0.5))),
        ],
      ),
    );
  }
}

class _InvolvedFoodsGrid extends StatelessWidget {
  const _InvolvedFoodsGrid({required this.insight});
  final InsightSummary insight;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    if (insight.involvedFoods.isEmpty) return const SizedBox.shrink();

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
              Text("LINKED INGREDIENTS", style: context.bodyBold.copyWith(fontSize: 12.sp, letterSpacing: 0.5, color: scheme.textPrimary)),
            ],
          ),
          Gap.h20,
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: insight.involvedFoods.map((food) => Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: scheme.cardBackground,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: scheme.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(InsightUiUtils.getReactionIcon(food), size: 12.sp, color: scheme.textPrimary),
                  Gap.w6,
                  Text(
                    food.toUpperCase(),
                    style: context.bodyBold.copyWith(fontSize: 10.sp, color: scheme.textPrimary),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _DetailedObservationCard extends StatelessWidget {
  const _DetailedObservationCard({required this.insight});
  final InsightSummary insight;

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
              Text("DETAILED OBSERVATION", style: context.bodyBold.copyWith(fontSize: 12.sp, letterSpacing: 0.5, color: scheme.textPrimary)),
            ],
          ),
          Gap.h16,
          Text(
            insight.observation ?? insight.description,
            style: context.bodySm.copyWith(color: scheme.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _ActionPlanSection extends StatelessWidget {
  const _ActionPlanSection({required this.insight});
  final InsightSummary insight;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final steps = insight.nextSteps.isNotEmpty ? insight.nextSteps : ["Keep monitoring your reactions"];
    
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
                  color: AppPalette.lime.withOpacity(0.2),
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
                  child: Icon(Icons.check_circle, color: AppPalette.lime, size: 16.w),
                ),
                Gap.w12,
                Expanded(
                  child: Text(
                    step,
                    style: context.bodySm.copyWith(color: scheme.cardBackground.withOpacity(0.8), height: 1.3),
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
