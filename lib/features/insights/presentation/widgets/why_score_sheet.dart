import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/insight_theme.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class WhyScoreSheet extends StatelessWidget {
  const WhyScoreSheet({super.key, required this.insight});

  final AIInsight insight;

  static GutScoreRecord? resolveRecord(BuildContext context) {
    try {
      final record = context.watch<ProfileNotifier>().latestScoreRecord;
      if (record != null) return record;
    } on ProviderNotFoundException {
      // Standalone/history widgets can be hosted without ProfileNotifier.
    }
    try {
      return context.watch<InsightsNotifier>().latestScoreRecord;
    } on ProviderNotFoundException {
      return null;
    }
  }

  static int resolveScore(BuildContext context, AIInsight insight) {
    try {
      return context.watch<ProfileNotifier>().gutScore.clamp(0, 100);
    } on ProviderNotFoundException {
      // Standalone/history widgets can be hosted without ProfileNotifier.
    }
    final record = resolveRecord(context);
    if (record != null) return record.gutScore.clamp(0, 100);
    return insight.gutScore.clamp(0, 100);
  }

  static bool hasScore(BuildContext context, AIInsight insight) {
    try {
      return context.watch<ProfileNotifier>().hasGutScore;
    } on ProviderNotFoundException {
      // Standalone/history widgets can be hosted without ProfileNotifier.
    }
    return resolveRecord(context)?.hasScore ?? insight.hasGutScore;
  }

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

    final score = resolveScore(context, insight);
    final hasScore = WhyScoreSheet.hasScore(context, insight);
    final scoreRecord = resolveRecord(context);
    final sampleSizes = insight.evidence?.sampleSizes;
    final patternRefs = insight.evidence?.patternRefs ?? const <PatternRef>[];
    final recap = insight.weeklyRecap;
    final scoredDays = scoreRecord?.scoredDayCount ?? recap?.scoredDayCount ?? 0;
    final weekLabel = scoreRecord != null ? 'this week' : (recap?.dateRange ?? 'this week');
    final hasWeeklyFoods = scoreRecord == null && (recap?.foodsLogged ?? 0) > 0;
    final hasBestDay = scoreRecord == null && (recap?.bestDay?.isNotEmpty ?? false);
    final mealCount = scoreRecord?.mealsCount ?? sampleSizes?.meals ?? 0;
    final scanCount = scoreRecord?.scansCount ?? sampleSizes?.scans ?? 0;
    final symptomCount = scoreRecord?.symptomsCount ?? sampleSizes?.symptoms ?? 0;
    final hasFoodLogs = mealCount > 0 || scanCount > 0;
    final hasSymptoms = symptomCount > 0;
    final hasKnownData = hasWeeklyFoods || scoredDays > 0 || hasBestDay || hasFoodLogs || hasSymptoms || patternRefs.isNotEmpty;

    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    final badgeBg = hasScore
        ? (score >= 70 ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5)) : (isDark ? const Color(0xFF78350F) : const Color(0xFFFFFBEB)))
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9));

    final badgeTextColor = hasScore
        ? (score >= 70 ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669)) : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)))
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
                    hasScore ? '$score' : '—',
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
                      hasScore ? 'Why $score?' : 'Score unavailable',
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 18.sp, fontWeight: FontWeight.w800, color: primaryTextColor),
                    ),
                    Text(
                      hasScore ? (scoredDays == 0 ? 'Your current GutGood Score' : '$scoredDays of 7 days scored') : 'Log food scans this week to unlock a gut score',
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
                      description: 'Your weekly score is the average of daily Gut Scores on days with food scans. Each daily score starts with that day’s average scanned food quality (0–100).',
                      points: 'Base',
                      isPositive: true,
                    ),
                  ),
                  const _FactorTile(
                    factor: _ScoreFactor(
                      title: 'Symptoms',
                      description: 'Reported negative symptoms subtract 3, 6 or 9 points by severity (1–3, 4–6, 7–10), up to 30 per day. Positive reactions do not lower your score.',
                      points: 'Adjustment',
                      isPositive: false,
                    ),
                  ),
                  const _FactorTile(
                    factor: _ScoreFactor(
                      title: 'Logging activity',
                      description: 'A day with a food scan adds 2 logging points. Each daily score is kept between 0 and 100.',
                      points: 'Bonus',
                      isPositive: true,
                    ),
                  ),

                  Gap.h16,

                  if (hasKnownData) ...[
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
                  ],
                  if (hasWeeklyFoods && recap != null)
                    _FactorTile(
                      factor: _ScoreFactor(title: 'Foods logged (week)', description: '${recap.foodsLogged ?? 0} meals and scans during $weekLabel', points: 'Counted', isPositive: true),
                    ),
                  if (scoredDays > 0)
                    _FactorTile(
                      factor: _ScoreFactor(
                        title: 'Scored days',
                        description: '$scoredDays of 7 days had scans during $weekLabel (empty days are 0, not filled in)',
                        points: '$scoredDays/7',
                        isPositive: true,
                      ),
                    ),
                  if (hasBestDay && recap != null)
                    _FactorTile(
                      factor: _ScoreFactor(title: 'Best day', description: 'Highest daily gut score this week', points: recap.bestDay!, isPositive: true),
                    ),
                  if (hasFoodLogs)
                    _FactorTile(
                      factor: _ScoreFactor(
                        title: scoreRecord == null ? 'Food logs (period)' : 'Food logs (this week)',
                        description: [if (mealCount > 0) '$mealCount meal ${mealCount == 1 ? 'log' : 'logs'}', if (scanCount > 0) '$scanCount food ${scanCount == 1 ? 'scan' : 'scans'}'].join(' and '),
                        points: 'Observed',
                        isPositive: true,
                      ),
                    ),
                  if (hasSymptoms)
                    _FactorTile(
                      factor: _ScoreFactor(
                        title: scoreRecord == null ? 'Symptom logs (period)' : 'Symptom logs (this week)',
                        description: '$symptomCount symptom logs included',
                        points: 'Observed',
                        isPositive: false,
                      ),
                    ),
                  for (final ref in patternRefs.take(4))
                    _FactorTile(
                      factor: _ScoreFactor(
                        title: ref.trigger.isEmpty ? 'Observed pattern' : ref.trigger,
                        description: ref.reaction.isEmpty ? 'Matched timing observations in this analysis' : ref.reaction,
                        points: '${ref.positiveCount} matched logs',
                        isPositive: null,
                      ),
                    ),
                  if (hasKnownData) Gap.h16,

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
  final bool? isPositive;
}

class _FactorTile extends StatelessWidget {
  const _FactorTile({required this.factor});
  final _ScoreFactor factor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = factor.isPositive == true
        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
        : factor.isPositive == false
        ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706))
        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));

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
