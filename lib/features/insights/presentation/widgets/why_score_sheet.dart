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
    final sampleSizes = insight.evidence?.sampleSizes;
    final patternRefs = insight.evidence?.patternRefs ?? const <PatternRef>[];

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
                decoration: BoxDecoration(color: insight.hasGutScore ? (isGood ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB)) : const Color(0xFFF1F5F9), shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    insight.hasGutScore ? '$score' : '—',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 18.sp, fontWeight: FontWeight.w800, color: insight.hasGutScore ? (isGood ? const Color(0xFF059669) : const Color(0xFFD97706)) : const Color(0xFF64748B)),
                  ),
                ),
              ),
              Gap.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.hasGutScore ? 'Why $score?' : 'Score unavailable',
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 18.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                    ),
                    Text(
                      'Based on your logged food scans and symptoms',
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

          Text('WHAT WE KNOW', style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: const Color(0xFF059669))),
          Gap.h8,
          if (sampleSizes == null && patternRefs.isEmpty)
            const Text('Detailed score evidence is not available for this record. Future reports will include the available inputs.')
          else ...[
            if (sampleSizes != null) ...[
              _FactorTile(factor: _ScoreFactor(title: 'Food logs', description: '${sampleSizes.meals} meals and ${sampleSizes.scans} scans included', points: 'Observed', isPositive: true)),
              _FactorTile(factor: _ScoreFactor(title: 'Symptom logs', description: '${sampleSizes.symptoms} symptoms included in the analysis', points: 'Observed', isPositive: false)),
            ],
            for (final ref in patternRefs.take(4))
              _FactorTile(factor: _ScoreFactor(title: ref.trigger.isEmpty ? 'Observed pattern' : ref.trigger, description: ref.reaction.isEmpty ? 'Evidence recorded in this analysis' : ref.reaction, points: '${(ref.evidenceRatio.clamp(0.0, 1.0) * 100).round()}% evidence', isPositive: ref.positiveCount > ref.negativeCount)),
          ],
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
                    'This summary shows the log counts and observed patterns available in this saved report. It does not diagnose a medical condition.',
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
