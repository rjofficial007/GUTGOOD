import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/date_formatter.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import '../widgets/scan_result_widgets.dart';

class SymptomDetailScreen extends StatelessWidget {
  const SymptomDetailScreen({super.key, required this.symptom});
  final SymptomLog symptom;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final severity = symptom.severity ?? 0;
    final severityColor = _getSeverityColor(context, severity);

    return Scaffold(
      backgroundColor: scheme.cardBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const GutSliverAppBar(title: AppStrings.symptoms, centerTitle: true),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashboardEntrance(
                    delay: 50,
                    child: _SymptomHeroSection(symptom: symptom, severityColor: severityColor),
                  ),
                  Gap.h12,
                  DashboardEntrance(delay: 100, child: _SymptomStatsGrid(symptom: symptom)),
                  Gap.h12,
                  DashboardEntrance(
                    delay: 200,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (symptom.lastMealFirestoreId != null)
                          Expanded(child: _PotentialTriggerCard(mealId: symptom.lastMealFirestoreId!)),
                        if (symptom.notes != null && symptom.notes!.isNotEmpty) ...[
                          if (symptom.lastMealFirestoreId != null) Gap.w12,
                          Expanded(child: _SymptomNotesSection(notes: symptom.notes!)),
                        ],
                      ],
                    ),
                  ),
                  Gap.h40,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Color _getSeverityColor(BuildContext context, int severity) {
    if (severity <= 3) return const Color(0xFFB4F1B4);
    if (severity <= 7) return const Color(0xFFC4B5FD);
    return AppPalette.red;
  }
}

class _SymptomHeroSection extends StatelessWidget {
  const _SymptomHeroSection({required this.symptom, required this.severityColor});
  final SymptomLog symptom;
  final Color severityColor;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final severity = symptom.severity ?? 0;

    return BentoCard(
      padding: const EdgeInsets.all(12),
      height: 200.h,
      backgroundColor: scheme.cardBackground,
      child: Row(
        children: [
          // Left Panel: The "Wallet Card" aesthetic
          AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(color: severityColor, borderRadius: BorderRadius.circular(16)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Text(
                        'SEVERITY',
                        style: TextStyle(color: Colors.black.withValues(alpha: 0.4), fontSize: 7.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]),
                      ),
                    ),
                    Positioned(
                      bottom: -10,
                      left: 8,
                      child: Text(
                        '$severity',
                        style: TextStyle(color: Colors.black, fontSize: 72.sp, fontWeight: FontWeight.w900, letterSpacing: -5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Gap.w16,
          // Right Panel: Narrative & Identity
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'SYMPTOM ANALYSIS',
                  style: TextStyle(color: scheme.textSecondary, fontSize: 8.5.sp, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                ),
                Gap.h4,
                Text(
                  symptom.symptom.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.bodyBold.copyWith(
                    color: scheme.textPrimary,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: -0.8,
                  ),
                ),
                Gap.h8,
                Text(
                  DateFormatter.formatFull(symptom.createdAt),
                  style: context.caption.copyWith(
                    color: scheme.textSecondary,
                    fontSize: 10.5.sp,
                    height: 1.4,
                    letterSpacing: -0.1,
                  ),
                ),
                Gap.h12,
                Row(
                  children: [
                    Icon(AppIcons.info, size: 12.sp, color: scheme.textMuted),
                    Gap.w6,
                    Text(
                      'LOGGED VIA ${symptom.source?.toUpperCase() ?? 'CHAT'}',
                      style: context.caption.copyWith(
                        color: scheme.textMuted,
                        fontWeight: FontWeight.w900,
                        fontSize: 8.sp,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Gap.w4,
        ],
      ),
    );
  }
}

class _SymptomStatsGrid extends StatelessWidget {
  const _SymptomStatsGrid({required this.symptom});
  final SymptomLog symptom;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    final metrics = [
      if (symptom.energyLevel != null) _MetricData('Energy', '${symptom.energyLevel}/10', 'LEVEL'),
      if (symptom.mood != null) _MetricData('Mood', symptom.mood!.toUpperCase(), 'STATE'),
      if (symptom.sleep != null) _MetricData('Sleep', symptom.sleep!.toUpperCase(), 'QUALITY'),
      _MetricData('Source', symptom.source?.toUpperCase() ?? 'MANUAL', 'ORIGIN'),
    ];

    return Row(
      children: metrics.asMap().entries.map((entry) {
        final i = entry.key;
        final data = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == metrics.length - 1 ? 0 : 12.w),
            child: _SmallMetricCard(
              label: data.label,
              value: data.value,
              unit: data.unit,
              icon: switch (data.label.toLowerCase()) {
                'energy' => AppIcons.zap,
                'mood' => AppIcons.smile,
                'sleep' => AppIcons.moon,
                _ => AppIcons.info,
              },
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MetricData {
  final String label, value, unit;
  _MetricData(this.label, this.value, this.unit);
}

class _SmallMetricCard extends StatelessWidget {
  const _SmallMetricCard({required this.label, required this.value, required this.unit, required this.icon});
  final String label, value, unit;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return BentoCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      borderRadius: 20,
      height: 100.h,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 10.sp, color: scheme.textSecondary),
              Gap.w4,
              Text(
                label.toUpperCase(),
                style: TextStyle(fontSize: 8.sp, fontWeight: FontWeight.w900, color: scheme.textSecondary, letterSpacing: 0.5),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.headingSm.copyWith(fontWeight: FontWeight.w900, fontSize: 16.sp, color: scheme.textPrimary),
          ),
          Gap.h2,
          Text(unit, style: TextStyle(fontSize: 6.sp, fontWeight: FontWeight.w800, color: scheme.textMuted)),
        ],
      ),
    );
  }
}

class _SymptomNotesSection extends StatelessWidget {
  const _SymptomNotesSection({required this.notes});
  final String notes;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return BentoCard(
      height: 240.h,
      padding: const EdgeInsets.all(24),
      backgroundColor: scheme.elevatedSurface,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Icon(Icons.format_quote_rounded, color: scheme.textMuted.withValues(alpha: 0.2), size: 48),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'REACTION MEMO',
                style: context.caption.copyWith(
                  color: scheme.textSecondary,
                  fontWeight: FontWeight.w900,
                  fontSize: 9.sp,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                notes,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: context.body.copyWith(
                  color: scheme.textPrimary,
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 2,
                    decoration: BoxDecoration(color: scheme.textMuted.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2)),
                  ),
                  Gap.w8,
                  Text(
                    'USER OBSERVATION',
                    style: context.caption.copyWith(color: scheme.textMuted, fontSize: 7.sp, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PotentialTriggerCard extends StatelessWidget {
  const _PotentialTriggerCard({required this.mealId});
  final String mealId;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return BentoCard(
      height: 240.h,
      padding: const EdgeInsets.all(20),
      backgroundColor: const Color(0xFFC4B5FD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EXPERT ANALYSIS',
                style: context.caption.copyWith(
                  color: Colors.black.withOpacity(0.6),
                  fontWeight: FontWeight.w900,
                  fontSize: 9.sp,
                  letterSpacing: 1.2,
                ),
              ),
              const Icon(AppIcons.sparkles, color: Colors.black45, size: 14),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(AppIcons.utensils, color: Colors.black, size: 14),
                  ),
                  Gap.w10,
                  Text(
                    'POTENTIAL TRIGGER',
                    style: context.bodyBold.copyWith(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13.sp),
                  ),
                ],
              ),
              Gap.h12,
              Text(
                'A meal logged shortly before this reaction is being analyzed for potential sensitivities.',
                style: context.body.copyWith(
                  color: Colors.black,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  fontSize: 12.5.sp,
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
