import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class WhyScoreSheet extends StatelessWidget {
  const WhyScoreSheet({super.key, required this.insight});

  final AIInsight insight;

  static void show(BuildContext context, AIInsight insight) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WhyScoreSheet(insight: insight),
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = insight.gutScore.clamp(0, 100);
    final isGood = score >= 70;

    final positiveFactors = <_ScoreFactor>[
      if (insight.healingFoods.isNotEmpty)
        _ScoreFactor(title: '${insight.healingFoods.first.name} & supportive foods', description: '${insight.healingFoods.length} gut-soothing items logged', points: '+12', isPositive: true)
      else if (insight.evidence != null && insight.evidence!.sampleSizes.meals > 0)
        _ScoreFactor(title: 'Active meal tracking', description: '${insight.evidence!.sampleSizes.meals} meals logged for analysis', points: '+10', isPositive: true),
      if (score >= 50) _ScoreFactor(title: 'Gut health score baseline', description: 'Current baseline score is $score/100', points: '+$score', isPositive: true),
    ];

    final negativeFactors = <_ScoreFactor>[
      if (insight.triggerFoods.isNotEmpty) _ScoreFactor(title: '${insight.triggerFoods.first.name} observation', description: 'Associated with digestive discomfort', points: '-6', isPositive: false),
      if (insight.triggerSymptom != null && insight.triggerSymptom!.isNotEmpty)
        _ScoreFactor(title: '${insight.triggerSymptom} tracking', description: 'Symptom patterns being monitored by AI', points: '-4', isPositive: false),
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.w)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 24.w, offset: const Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 38.w,
              height: 4.h,
              decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2.h)),
            ),
          ),
          Gap.h16,

          // Header
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(color: isGood ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB), shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    '$score',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 18.sp, fontWeight: FontWeight.w800, color: isGood ? const Color(0xFF059669) : const Color(0xFFD97706)),
                  ),
                ),
              ),
              Gap.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why $score?',
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 18.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                    ),
                    Text(
                      'Base 50 baseline + evidence-backed adjustments',
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.5.sp, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 20, color: Color(0xFF64748B)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Gap.h20,

          // Positive Factors
          Text(
            'HELPING YOUR SCORE',
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: const Color(0xFF059669)),
          ),
          Gap.h8,
          ...positiveFactors.map((f) => _FactorTile(factor: f)),
          Gap.h16,

          // Negative Deductions
          Text(
            'AREAS FOR RECOVERY',
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: const Color(0xFFEF4444)),
          ),
          Gap.h8,
          ...negativeFactors.map((f) => _FactorTile(factor: f)),
          Gap.h20,

          // Transparency note
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14.w),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.shieldCheck, size: 16.w, color: const Color(0xFF64748B)),
                Gap.w8,
                Expanded(
                  child: Text(
                    'Your score recalibrates dynamically every 24 hours based on 30-day meal frequency, causality windows, and symptoms.',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: const Color(0xFF64748B), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreFactor {
  const _ScoreFactor({required this.title, required this.description, required this.points, required this.isPositive});

  final String title;
  final String description;
  final String points;
  final bool isPositive;
}

class _FactorTile extends StatelessWidget {
  const _FactorTile({required this.factor});

  final _ScoreFactor factor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 5.h),
    child: Row(
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(color: factor.isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444), shape: BoxShape.circle),
        ),
        Gap.w10,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                factor.title,
                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
              ),
              Text(
                factor.description,
                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: const Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
          decoration: BoxDecoration(color: factor.isPositive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(100)),
          child: Text(
            factor.points,
            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: factor.isPositive ? const Color(0xFF059669) : const Color(0xFFDC2626)),
          ),
        ),
      ],
    ),
  );
}
