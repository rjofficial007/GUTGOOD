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
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p24, vertical: AppSizes.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashboardEntrance(
                    delay: 50,
                    child: _SymptomHeader(symptom: symptom, severityColor: severityColor),
                  ),
                  Gap.h32,
                  DashboardEntrance(delay: 100, child: _SymptomStatsGrid(symptom: symptom)),
                  if (symptom.notes != null && symptom.notes!.isNotEmpty) ...[Gap.h32, DashboardEntrance(delay: 150, child: _SymptomNotesSection(notes: symptom.notes!))],
                  if (symptom.lastMealFirestoreId != null) ...[Gap.h32, DashboardEntrance(delay: 200, child: _PotentialTriggerCard(mealId: symptom.lastMealFirestoreId!))],
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
    if (severity <= 3) return context.appColorScheme.success;
    if (severity <= 7) return context.appColorScheme.warning;
    return context.appColorScheme.error;
  }
}

class _SymptomHeader extends StatelessWidget {
  const _SymptomHeader({required this.symptom, required this.severityColor});
  final SymptomLog symptom;
  final Color severityColor;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final severity = symptom.severity ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: severityColor, borderRadius: BorderRadius.circular(4)),
              child: Text(
                'SEVERITY $severity/10',
                style: context.caption.copyWith(color: AppPalette.white, fontWeight: FontWeight.w900, fontSize: 10.sp),
              ),
            ),
            Gap.w12,
            Text(DateFormatter.formatFull(symptom.createdAt).toUpperCase(), style: context.eyebrow.copyWith(color: scheme.textMuted)),
          ],
        ),
        Gap.h16,
        Text(
          symptom.symptom.toUpperCase(),
          style: context.displaySm.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1.5, height: 1.0, color: scheme.textPrimary),
        ),
        Gap.h24,
        _SeverityBar(severity: severity, color: severityColor),
      ],
    );
  }
}

class _SeverityBar extends StatelessWidget {
  const _SeverityBar({required this.severity, required this.color});
  final int severity;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'LOW',
            style: context.caption.copyWith(fontSize: 9.sp, fontWeight: FontWeight.w900, color: context.appColorScheme.textMuted),
          ),
          Text(
            'HIGH',
            style: context.caption.copyWith(fontSize: 9.sp, fontWeight: FontWeight.w900, color: context.appColorScheme.textMuted),
          ),
        ],
      ),
      Gap.h8,
      Container(
        height: 8,
        width: double.infinity,
        decoration: BoxDecoration(color: context.appColorScheme.elevatedSurface, borderRadius: BorderRadius.circular(100)),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: (severity / 10).clamp(0.05, 1.0),
          child: Container(
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(100)),
          ),
        ),
      ),
    ],
  );
}

class _SymptomStatsGrid extends StatelessWidget {
  const _SymptomStatsGrid({required this.symptom});
  final SymptomLog symptom;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetSectionHeader(title: 'OBSERVATIONS', color: Colors.transparent),
        GridView.count(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2,
          children: [
            if (symptom.energyLevel != null) _StatCard(title: 'ENERGY', value: '${symptom.energyLevel}/10', icon: AppIcons.zap, color: AppPalette.yellow),
            if (symptom.mood != null) _StatCard(title: 'MOOD', value: symptom.mood!.toUpperCase(), icon: AppIcons.smile, color: AppPalette.blue),
            if (symptom.sleep != null) _StatCard(title: 'SLEEP', value: symptom.sleep!.toUpperCase(), icon: AppIcons.moon, color: AppPalette.purple),
            _StatCard(title: 'SOURCE', value: symptom.source?.toUpperCase() ?? 'MANUAL', icon: AppIcons.info, color: scheme.textMuted),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(AppSizes.r20),
        border: Border.all(color: scheme.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          Gap.w10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: context.caption.copyWith(fontSize: 8.sp, fontWeight: FontWeight.w900, color: scheme.textMuted, letterSpacing: 0.5),
                ),
                Text(
                  value,
                  style: context.bodyBold.copyWith(fontSize: 11.sp, color: scheme.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetSectionHeader(title: 'REACTION NOTES', color: Colors.transparent),
        Text('"$notes"', style: context.body.copyWith(color: scheme.textSecondary)),
      ],
    );
  }
}

class _PotentialTriggerCard extends StatelessWidget {
  const _PotentialTriggerCard({required this.mealId});
  final String mealId;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetSectionHeader(title: 'POTENTIAL TRIGGER', color: Colors.transparent),
        Container(
          padding: const EdgeInsets.all(24),
          width: double.infinity,
          decoration: BoxDecoration(
            color: scheme.error.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppSizes.r32),
            border: Border.all(color: scheme.error.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: scheme.error.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(AppIcons.utensils, color: scheme.error, size: 20),
                  ),
                  Gap.w16,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RECENT MEAL DETECTED', style: context.bodyBold.copyWith(color: scheme.error)),
                        Text('A meal logged shortly before this reaction.', style: context.caption.copyWith(color: scheme.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
