import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/date_formatter.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/widgets/analysis_card.dart';

class SymptomDetailScreen extends StatelessWidget {
  const SymptomDetailScreen({super.key, required this.symptom});
  final SymptomLog symptom;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    return Scaffold(
      backgroundColor: scheme.cardBackground,
      body: CustomScrollView(
        slivers: [
          const GutSliverAppBar(title: '', showBrandingIcon: false),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p10),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                DashboardEntrance(delay: 50, child: _SymptomHeroCard(symptom: symptom)),
                Gap.h20,
                DashboardEntrance(delay: 100, child: _SymptomDetailsCard(symptom: symptom)),
                Gap.h20,
                if (symptom.notes != null && symptom.notes!.isNotEmpty) ...[DashboardEntrance(delay: 150, child: _SymptomNotesCard(notes: symptom.notes!)), Gap.h20],
                if (symptom.lastMealFirestoreId != null) ...[DashboardEntrance(delay: 200, child: _RelatedMealCard(mealId: symptom.lastMealFirestoreId!)), Gap.h40],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SymptomHeroCard extends StatelessWidget {
  const _SymptomHeroCard({required this.symptom});
  final SymptomLog symptom;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    return ModernInsightCard(
      title: 'BODY REACTION',
      icon: AppIcons.activity,
      iconColor: scheme.textPrimary,
      backgroundColor: scheme.cardBackground,
      footer: Text(
        DateFormatter.formatFull(symptom.createdAt).toUpperCase(),
        style: context.caption.copyWith(color: scheme.cardBackground, fontWeight: FontWeight.w900, fontSize: 10.sp, letterSpacing: 1.2),
      ),
      footerColor: scheme.textPrimary,
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Gap.h24,
            Text(
              symptom.symptom.toUpperCase(),
              style: context.displaySm.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1.5, height: 0.9),
              textAlign: TextAlign.center,
            ),
            Gap.h8,
            Text('SEVERITY: ${symptom.severity ?? 0}/10', style: context.eyebrow),
            Gap.h32,
          ],
        ),
      ),
    );
  }
}

class _SymptomDetailsCard extends StatelessWidget {
  const _SymptomDetailsCard({required this.symptom});
  final SymptomLog symptom;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final items = <AnalysisItem>[];

    if (symptom.energyLevel != null) {
      items.add(AnalysisItem(title: 'ENERGY LEVEL', subtitle: '${symptom.energyLevel}/10', icon: AppIcons.zap, color: scheme.textPrimary));
    }
    if (symptom.mood != null) {
      items.add(AnalysisItem(title: 'MOOD', subtitle: symptom.mood!.toUpperCase(), icon: AppIcons.smile, color: scheme.textPrimary));
    }
    if (symptom.sleep != null) {
      items.add(AnalysisItem(title: 'SLEEP QUALITY', subtitle: symptom.sleep!.toUpperCase(), icon: AppIcons.moon, color: scheme.textPrimary));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('OBSERVATIONS', style: context.eyebrow),
        Gap.h16,
        AnalysisCard(metric: (symptom.severity ?? 0).toString(), label: 'SEVERITY', icon: AppIcons.brain, glowColor: scheme.textPrimary, items: items),
      ],
    );
  }
}

class _SymptomNotesCard extends StatelessWidget {
  const _SymptomNotesCard({required this.notes});
  final String notes;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('NOTES', style: context.eyebrow),
        Gap.h16,
        Container(
          padding: EdgeInsets.all(AppSizes.p20),
          width: double.infinity,
          decoration: BoxDecoration(
            color: scheme.elevatedSurface,
            borderRadius: BorderRadius.circular(AppSizes.r24),
            border: Border.all(color: scheme.border.withValues(alpha: 0.5)),
          ),
          child: Text(notes, style: context.body.copyWith(color: scheme.textSecondary)),
        ),
      ],
    );
  }
}

class _RelatedMealCard extends StatelessWidget {
  const _RelatedMealCard({required this.mealId});
  final String mealId;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('POTENTIAL TRIGGER', style: context.eyebrow),
        Gap.h16,
        Container(
          padding: EdgeInsets.all(AppSizes.p20),
          width: double.infinity,
          decoration: BoxDecoration(
            color: scheme.elevatedSurface,
            borderRadius: BorderRadius.circular(AppSizes.r24),
            border: Border.all(color: scheme.border.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Icon(AppIcons.utensils, color: scheme.textPrimary),
              Gap.w16,
              Expanded(
                child: Text('Associated with a meal logged previously.', style: context.bodyBold.copyWith(color: scheme.textPrimary)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
