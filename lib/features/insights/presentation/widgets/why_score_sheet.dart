import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/insight_theme.dart';
import 'package:gutgood/core/utils/responsive.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = context.appColorScheme;

    final score = insight.gutScore.clamp(0, 100);
    final isGood = score >= 70;
    final sampleSizes = insight.evidence?.sampleSizes;
    final patternRefs = insight.evidence?.patternRefs ?? const <PatternRef>[];
    final recap = insight.weeklyRecap;
    final trend = recap?.gutScoreTrend ?? const <int>[];
    final scoredDays = trend.where((s) => s > 0).length;

    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    final badgeBg = insight.hasGutScore
        ? (isGood ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5)) : (isDark ? const Color(0xFF78350F) : const Color(0xFFFFFBEB)))
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9));

    final badgeTextColor = insight.hasGutScore
        ? (isGood ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669)) : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)))
        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));

    final primaryTextColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
      decoration: BoxDecoration(
        color: isDark ? scheme.cardBackground : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.w)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 24.w,
            offset: const Offset(0, -4),
          ),
        ],
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
              decoration: BoxDecoration(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2.h)),
            ),
          ),
          Gap.h16,

          // Header
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(color: badgeBg, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    insight.hasGutScore ? '$score' : '—',
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 18.sp, fontWeight: FontWeight.w800, color: badgeTextColor),
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
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 18.sp, fontWeight: FontWeight.w800, color: primaryTextColor),
                    ),
                    Text(
                      insight.hasGutScore ? (recap?.scoreSub ?? 'Based on your logged food scans and symptoms this week') : 'Log food scans this week to unlock a gut score',
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.5.sp, color: secondaryTextColor, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(LucideIcons.x, size: 20, color: secondaryTextColor),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Gap.h16,

          // Scrollable Body Content
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HOW IT\'S CALCULATED',
                    style: TextStyle(
                      fontFamily: InsightTheme.fontFamily,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: isDark ? const Color(0xFF818CF8) : const Color(0xFF6366F1),
                    ),
                  ),
                  Gap.h8,
                  const _FactorTile(
                    factor: _ScoreFactor(
                      title: 'Food Scan Quality',
                      description: 'Average quality score (0–100) from your scanned foods based on ingredients, Nutri-Score & processing level.',
                      points: 'Base',
                      isPositive: true,
                    ),
                  ),

                  Gap.h16,

                  Text(
                    'WHAT WE KNOW',
                    style: TextStyle(
                      fontFamily: InsightTheme.fontFamily,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                    ),
                  ),
                  Gap.h8,
                  if (recap != null) ...[
                    _FactorTile(
                      factor: _ScoreFactor(title: 'Weekly foods logged', description: '${recap.foodsLogged ?? 0} meals and scans in the last 7 days', points: 'Counted', isPositive: true),
                    ),
                    _FactorTile(
                      factor: _ScoreFactor(
                        title: 'Scored days',
                        description: scoredDays == 0 ? 'No days with food scans yet — empty days stay at 0' : '$scoredDays of 7 days had scans (empty days are 0, not filled in)',
                        points: scoredDays == 0 ? '—' : '$scoredDays/7',
                        isPositive: scoredDays > 0,
                      ),
                    ),
                    if (recap.bestDay != null && recap.bestDay!.isNotEmpty)
                      _FactorTile(
                        factor: _ScoreFactor(title: 'Best day', description: 'Highest daily gut score this week', points: recap.bestDay!, isPositive: true),
                      ),
                  ],
                  if (sampleSizes == null && patternRefs.isEmpty && recap == null)
                    Text(
                      'Detailed score evidence is not available for this record. Future reports will include the available inputs.',
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.sp, color: secondaryTextColor),
                    )
                  else ...[
                    if (sampleSizes != null) ...[
                      _FactorTile(
                        factor: _ScoreFactor(title: 'Food logs (period)', description: '${sampleSizes.meals} meals and ${sampleSizes.scans} scans included', points: 'Observed', isPositive: true),
                      ),
                      _FactorTile(
                        factor: _ScoreFactor(title: 'Symptom logs (period)', description: '${sampleSizes.symptoms} symptoms included in the analysis', points: 'Observed', isPositive: false),
                      ),
                    ],
                    for (final ref in patternRefs.take(4))
                      _FactorTile(
                        factor: _ScoreFactor(
                          title: ref.trigger.isEmpty ? 'Observed pattern' : ref.trigger,
                          description: ref.reaction.isEmpty ? 'Evidence recorded in this analysis' : ref.reaction,
                          points: '${(ref.evidenceRatio.clamp(0.0, 1.0) * 100).round()}% evidence',
                          isPositive: ref.positiveCount > ref.negativeCount,
                        ),
                      ),
                  ],
                  Gap.h16,

                  // Transparency note
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14.w),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(LucideIcons.shieldCheck, size: 16.w, color: secondaryTextColor),
                        Gap.w8,
                        Expanded(
                          child: Text(
                            'Daily scores only appear on days you scanned food. Days with no scans stay at 0 — we never invent a baseline. This does not diagnose a medical condition.',
                            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, color: secondaryTextColor, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Gap.h12,
                ],
              ),
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = factor.isPositive ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669)) : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706));

    final primaryTextColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            margin: EdgeInsets.only(top: 5.h),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Gap.w10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  factor.title,
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 13.sp, fontWeight: FontWeight.w700, color: primaryTextColor),
                ),
                Text(
                  factor.description,
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, color: secondaryTextColor, height: 1.35),
                ),
              ],
            ),
          ),
          Text(
            factor.points,
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
