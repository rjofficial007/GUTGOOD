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
import 'package:gutgood/features/product_details/presentation/widgets/scan_result_widgets.dart';

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
                  DashboardEntrance(delay: 150, child: _PotentialTriggerCard(mealId: symptom.lastMealFirestoreId)),
                  Gap.h12,
                  DashboardEntrance(delay: 200, child: _SymptomNotesSection(notes: symptom.notes ?? '')),
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
    if (severity <= 3) return AppPalette.greenPastel;
    if (severity <= 7) return AppPalette.purplePastel;
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
          // Left Panel: Image or Wallet Card
          Container(
            width: 176.h,
            height: 176.h,
            decoration: BoxDecoration(color: severityColor, borderRadius: BorderRadius.circular(16)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  if (symptom.imageUrl != null && symptom.imageUrl!.isNotEmpty)
                    Positioned.fill(
                      child: Image.network(
                        symptom.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(color: severityColor),
                      ),
                    ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppPalette.black.withAlpha(153), borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        AppStrings.severityLabel.toUpperCase(),
                        style: context.captionTiny.copyWith(color: AppPalette.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(color: AppPalette.black.withAlpha(179), borderRadius: BorderRadius.circular(12)),
                      child: Text('$severity/10', style: context.labelBold.copyWith(color: AppPalette.white)),
                    ),
                  ),
                ],
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
                Text(AppStrings.symptomAnalysis, style: context.captionBold.copyWith(color: scheme.textSecondary)),
                Gap.h4,
                Text(
                  symptom.symptom.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.headingSm.copyWith(color: scheme.textPrimary, fontWeight: FontWeight.w900),
                ),
                if (symptom.foodName != null && symptom.foodName!.isNotEmpty) ...[
                  Gap.h4,
                  Text(
                    'After ${symptom.foodName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.captionBold.copyWith(color: scheme.textPrimary, fontWeight: FontWeight.w700),
                  ),
                ],
                Gap.h8,
                Text(DateFormatter.formatFull(symptom.createdAt), style: context.captionBold.copyWith(color: scheme.textSecondary)),
                Gap.h12,
                Row(
                  children: [
                    Icon(AppIcons.info, size: 12.sp, color: scheme.textMuted),
                    Gap.w6,
                    Text(AppStrings.loggedVia(symptom.source?.toUpperCase() ?? AppStrings.chatSource), style: context.captionBold.copyWith(color: scheme.textMuted)),
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
    final metrics = [
      if (symptom.foodName != null && symptom.foodName!.isNotEmpty) _MetricData('Food', symptom.foodName!.toUpperCase(), 'MEAL'),
      if (symptom.energyLevel != null) _MetricData('Energy', '${symptom.energyLevel}/10', 'LEVEL'),
      if (symptom.mood != null) _MetricData('Mood', symptom.mood!.toUpperCase(), 'STATE'),
      if (symptom.sleep != null) _MetricData('Sleep', symptom.sleep!.toUpperCase(), 'QUALITY'),
      if (symptom.foodName == null || symptom.foodName!.isEmpty) _MetricData('Source', symptom.source?.toUpperCase() ?? AppStrings.manualLabel, 'ORIGIN'),
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
  _MetricData(this.label, this.value, this.unit);
  final String label;
  final String value;
  final String unit;
}

class _SmallMetricCard extends StatelessWidget {
  const _SmallMetricCard({required this.label, required this.value, required this.unit, required this.icon});
  final String label;
  final String value;
  final String unit;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return BentoCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      borderRadius: 10,
      height: 100.h,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 10.sp, color: scheme.textSecondary),
              Gap.w4,
              Text(label.toUpperCase(), style: context.captionBold.copyWith(color: scheme.textSecondary)),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.labelBold.copyWith(color: scheme.textPrimary),
          ),
          Gap.h2,
          Text(unit, style: context.captionMicro.copyWith(color: scheme.textMuted)),
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
      padding: const EdgeInsets.all(24),
      backgroundColor: scheme.elevatedSurface,
      child: Stack(
        children: [
          Positioned(right: 0, top: 0, child: Icon(Icons.format_quote_rounded, color: scheme.textMuted.withAlpha(51), size: 48)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.reactionMemo, style: context.captionBold.copyWith(color: scheme.textSecondary)),
              Gap.h16,
              Text(
                notes.isEmpty ? 'NO ADDITIONAL OBSERVATIONS LOGGED' : notes,
                style: context.label.copyWith(color: scheme.textPrimary, height: 1.6, fontWeight: FontWeight.w600, fontStyle: notes.isEmpty ? FontStyle.normal : FontStyle.italic),
              ),
              Gap.h16,
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 2,
                    decoration: BoxDecoration(color: scheme.textMuted.withAlpha(127), borderRadius: BorderRadius.circular(2)),
                  ),
                  Gap.w8,
                  Text(AppStrings.userObservation, style: context.captionTiny.copyWith(color: scheme.textMuted)),
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
  final String? mealId;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BentoCard(
      padding: const EdgeInsets.all(20),
      backgroundColor: isDark ? AppPalette.purple.withAlpha(26) : AppPalette.purplePastel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BentoCardHeader(
            title: AppStrings.expertAnalysis,
            icon: AppIcons.sparkles,
            textColor: isDark ? AppPalette.purplePastel.withAlpha(153) : AppPalette.black.withAlpha(153),
            iconColor: isDark ? AppPalette.purplePastel.withAlpha(102) : AppPalette.black.withAlpha(102),
          ),
          Gap.h24,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: isDark ? AppPalette.white.withAlpha(26) : AppPalette.black.withAlpha(26), shape: BoxShape.circle),
                    child: Icon(AppIcons.utensils, color: isDark ? scheme.textPrimary : AppPalette.black, size: 14),
                  ),
                  Gap.w10,
                  Text(AppStrings.potentialTrigger, style: context.labelBold.copyWith(color: isDark ? scheme.textPrimary : AppPalette.black)),
                ],
              ),
              Gap.h12,
              Text(
                mealId == null ? 'NO POTENTIAL TRIGGERS IDENTIFIED FOR THIS REACTION' : 'A meal logged shortly before this reaction is being analyzed for potential sensitivities.',
                style: context.label.copyWith(
                  color: isDark ? scheme.textPrimary : AppPalette.black,
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                  fontStyle: mealId == null ? FontStyle.normal : FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
