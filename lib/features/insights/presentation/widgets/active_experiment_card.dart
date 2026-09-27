import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class ActiveExperimentCard extends StatelessWidget {
  const ActiveExperimentCard({super.key, required this.experiment});

  final GutExperiment experiment;

  @override
  Widget build(BuildContext context) {
    final v2 = context.v2Theme;
    final isCheckedIn = experiment.isCheckedInToday();
    final todayCheckIn = experiment.todayCheckIn();
    final isCompleted = experiment.isCompleted;

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: v2.card,
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF10B981).withValues(alpha: 0.35)
              : const Color(0xFFF59E0B).withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCompleted ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.06),
            blurRadius: 16.w,
            offset: Offset(0, 4.w),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Accent Bar
            Container(
              height: 4.h,
              color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Eyebrow + Day Counter + Menu
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: isCompleted ? context.insightColor(const Color(0xFFECFDF5)) : context.insightColor(const Color(0xFFFFFBEB)),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCompleted ? LucideIcons.checkCircle2 : LucideIcons.flaskConical,
                              size: 12.w,
                              color: isCompleted ? const Color(0xFF059669) : const Color(0xFFD97706),
                            ),
                            Gap.w4,
                            Text(
                              isCompleted ? 'TEST COMPLETED' : 'ACTIVE 7-DAY TEST',
                              style: TextStyle(
                                fontFamily: InsightV2Theme.fontFamily,
                                fontSize: 9.5.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: isCompleted ? const Color(0xFF059669) : const Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Day ${experiment.currentDayNumber} of ${experiment.targetDays}',
                        style: TextStyle(
                          fontFamily: InsightV2Theme.fontFamily,
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w700,
                          color: v2.textSecondary,
                        ),
                      ),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: Icon(LucideIcons.ellipsisVertical, size: 16.w, color: v2.textTertiary),
                        onSelected: (val) {
                          if (val == 'cancel') {
                            _showCancelDialog(context);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'cancel',
                            child: Row(
                              children: [
                                Icon(LucideIcons.xCircle, size: 16, color: Color(0xFFEF4444)),
                                SizedBox(width: 8),
                                Text('End Experiment', style: TextStyle(color: Color(0xFFEF4444))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Gap.h8,

                  // Title
                  Text(
                    experiment.title,
                    style: TextStyle(
                      fontFamily: InsightV2Theme.fontFamily,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: v2.textPrimary,
                      letterSpacing: -0.3,
                      height: 1.25,
                    ),
                  ),
                  Gap.h4,

                  // Hypothesis / Motivation
                  Text(
                    experiment.hypothesis,
                    style: TextStyle(
                      fontFamily: InsightV2Theme.fontFamily,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: v2.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  Gap.h12,

                  // 7-Day Visual Progress Track
                  Row(
                    children: List.generate(experiment.targetDays, (index) {
                      final dayNum = index + 1;
                      final isCurrent = dayNum == experiment.currentDayNumber;

                      return Expanded(
                        child: Container(
                          height: 6.h,
                          margin: EdgeInsets.symmetric(horizontal: 2.w),
                          decoration: BoxDecoration(
                            color: dayNum < experiment.currentDayNumber
                                ? const Color(0xFF10B981)
                                : isCurrent
                                    ? (isCheckedIn ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                                    : v2.borderSubtle,
                            borderRadius: BorderRadius.circular(3.h),
                          ),
                        ),
                      );
                    }),
                  ),
                  Gap.h12,

                  // State 1: Test Completed Outcome
                  if (isCompleted) ...[
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: context.insightColor(const Color(0xFFF0FDF4)),
                        borderRadius: BorderRadius.circular(14.w),
                        border: Border.all(color: context.insightColor(const Color(0xFFDCFCE7))),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.trophy, size: 20.w, color: const Color(0xFF059669)),
                          Gap.w10,
                          Expanded(
                            child: Text(
                              experiment.completedOutcome ??
                                  'Great work! You finished the 7-day challenge. Check your GutScore to see the improvement.',
                              style: TextStyle(
                                fontFamily: InsightV2Theme.fontFamily,
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w600,
                                color: context.insightColor(const Color(0xFF166534)),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Gap.h8,
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.w)),
                          side: BorderSide(color: v2.border),
                        ),
                        onPressed: () {
                          context.read<InsightsNotifier>().cancelActiveExperiment();
                        },
                        child: Text(
                          'Dismiss Test',
                          style: TextStyle(
                            fontFamily: InsightV2Theme.fontFamily,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: v2.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ] else if (isCheckedIn) ...[
                    // State 2: Already Checked In Today
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: context.insightColor(const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(12.w),
                        border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0))),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            todayCheckIn?.adhered == true ? LucideIcons.checkCircle : LucideIcons.info,
                            size: 18.w,
                            color: todayCheckIn?.adhered == true ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          ),
                          Gap.w8,
                          Expanded(
                            child: Text(
                              todayCheckIn?.adhered == true
                                  ? 'Day ${experiment.currentDayNumber} logged: You stayed on track! Keep it up.'
                                  : 'Day ${experiment.currentDayNumber} logged: Slip recorded. Every day of data helps us learn!',
                              style: TextStyle(
                                fontFamily: InsightV2Theme.fontFamily,
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w600,
                                color: v2.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // State 3: Needs Daily Check-In
                    Text(
                      'Daily check-in for Day ${experiment.currentDayNumber}: Did you follow the plan today?',
                      style: TextStyle(
                        fontFamily: InsightV2Theme.fontFamily,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: v2.textPrimary,
                      ),
                    ),
                    Gap.h8,
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(vertical: 10.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.w)),
                            ),
                            icon: const Icon(LucideIcons.check, size: 16),
                            label: Text(
                              'Yes, Stayed on Plan',
                              style: TextStyle(
                                fontFamily: InsightV2Theme.fontFamily,
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              context.read<InsightsNotifier>().recordDailyCheckIn(
                                    adhered: true,
                                    hadSymptoms: false,
                                  );
                            },
                          ),
                        ),
                        Gap.w8,
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: v2.textSecondary,
                              padding: EdgeInsets.symmetric(vertical: 10.h),
                              side: BorderSide(color: v2.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.w)),
                            ),
                            icon: const Icon(LucideIcons.alertCircle, size: 16),
                            label: Text(
                              'Had a Slip',
                              style: TextStyle(
                                fontFamily: InsightV2Theme.fontFamily,
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              context.read<InsightsNotifier>().recordDailyCheckIn(
                                    adhered: false,
                                    hadSymptoms: true,
                                  );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('End 7-Day Test early?'),
        content: const Text(
          'Are you sure you want to cancel this gut test? Your logged days will still count toward pattern analysis.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Testing'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<InsightsNotifier>().cancelActiveExperiment();
            },
            child: const Text('End Test'),
          ),
        ],
      ),
    );
  }
}
