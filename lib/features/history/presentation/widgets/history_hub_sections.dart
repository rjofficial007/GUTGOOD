import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/historical_scan.dart';
import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/date_formatter.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';

class AIHubSection extends StatelessWidget {
  const AIHubSection({super.key, required this.scans, required this.onViewAll});
  final List<HistoricalScan> scans;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final displayScans = scans.take(3).toList();

    return DashboardEntrance(
      delay: 100,
      child: DashboardCard(
        footerLabel: AppStrings.viewAllScans,
        onFooterTap: onViewAll,
        child: Padding(
          padding: EdgeInsets.all(AppSizes.p20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(AppSizes.p8),
                    decoration: BoxDecoration(color: context.appColorScheme.surfaceSubtle, shape: BoxShape.circle),
                    child: Icon(AppIcons.scan, color: context.appColorScheme.textPrimary, size: AppSizes.icon20),
                  ),
                  Gap.w12,
                  Text(AppStrings.aiScanHistory.toUpperCase(), style: context.labelBold.copyWith(letterSpacing: 1.0)),
                ],
              ),
              Gap.h20,
              if (displayScans.isEmpty) Text(AppStrings.noScansYet, style: context.caption.copyWith(color: context.appColorScheme.textMuted)) else ...displayScans.map((s) => _ScanMiniTile(scan: s)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanMiniTile extends StatelessWidget {
  const _ScanMiniTile({required this.scan});
  final HistoricalScan scan;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: AppSizes.p12),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                scan.data.productName,
                style: context.bodyBold,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text('${scan.data.brand} • ${DateFormatter.formatFull(scan.createdAt)}', style: context.caption.copyWith(color: context.appColorScheme.textMuted)),
            ],
          ),
        ),
        Gap.w12,
        Container(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p4),
          decoration: BoxDecoration(color: context.appColorScheme.surfaceSubtle, borderRadius: BorderRadius.circular(AppSizes.r8)),
          child: Text(
            '${scan.data.score}',
            style: context.labelBold.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ),
      ],
    ),
  );
}

class MealHubSection extends StatelessWidget {
  const MealHubSection({super.key, required this.meals});
  final List<MealLog> meals;

  @override
  Widget build(BuildContext context) => DashboardEntrance(
    delay: 200,
    child: DashboardCard(
      child: Padding(
        padding: EdgeInsets.all(AppSizes.p20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSizes.p8),
                  decoration: BoxDecoration(color: context.appColorScheme.surfaceSubtle, shape: BoxShape.circle),
                  child: Icon(AppIcons.utensils, color: context.appColorScheme.textPrimary, size: AppSizes.icon20),
                ),
                Gap.w12,
                Text(AppStrings.dailyMealJournal.toUpperCase(), style: context.labelBold.copyWith(letterSpacing: 1.0)),
              ],
            ),
            Gap.h20,
            if (meals.isEmpty) Text(AppStrings.noMealsLogged, style: context.caption.copyWith(color: context.appColorScheme.textMuted)) else ...meals.take(5).map((m) => _MealMiniTile(meal: m)),
          ],
        ),
      ),
    ),
  );
}

class _MealMiniTile extends StatelessWidget {
  const _MealMiniTile({required this.meal});
  final MealLog meal;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: AppSizes.p12),
    child: Row(
      children: [
        Container(
          width: 4,
          height: 32,
          decoration: BoxDecoration(color: context.appColorScheme.textPrimary.withAlpha(77), borderRadius: BorderRadius.circular(2)),
        ),
        Gap.w12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meal.items.join(', '),
                style: context.bodyBold,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text('${DateFormatter.formatTime(meal.createdAt)} • ${meal.source?.toUpperCase() ?? AppStrings.labelLog}', style: context.caption.copyWith(color: context.appColorScheme.textMuted)),
            ],
          ),
        ),
      ],
    ),
  );
}

class SymptomHubSection extends StatelessWidget {
  const SymptomHubSection({super.key, required this.symptoms});
  final List<SymptomLog> symptoms;

  @override
  Widget build(BuildContext context) => DashboardEntrance(
    delay: 300,
    child: DashboardCard(
      child: Padding(
        padding: EdgeInsets.all(AppSizes.p20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSizes.p8),
                  decoration: BoxDecoration(color: context.appColorScheme.surfaceSubtle, shape: BoxShape.circle),
                  child: Icon(AppIcons.activity, color: context.appColorScheme.textPrimary, size: AppSizes.icon20),
                ),
                Gap.w12,
                Text(AppStrings.bodySymptomTracker.toUpperCase(), style: context.labelBold.copyWith(letterSpacing: 1.0)),
              ],
            ),
            Gap.h20,
            if (symptoms.isEmpty)
              Text(AppStrings.noSymptomsLogged, style: context.caption.copyWith(color: context.appColorScheme.textMuted))
            else
              ...symptoms.take(5).map((s) => _SymptomMiniTile(symptom: s)),
          ],
        ),
      ),
    ),
  );
}

class _SymptomMiniTile extends StatelessWidget {
  const _SymptomMiniTile({required this.symptom});
  final SymptomLog symptom;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: AppSizes.p12),
    child: Row(
      children: [
        Container(
          padding: EdgeInsets.all(AppSizes.p6),
          decoration: BoxDecoration(color: context.appColorScheme.surfaceSubtle, shape: BoxShape.circle),
          child: Icon(AppIcons.alertCircle, size: 14, color: context.appColorScheme.textSecondary),
        ),
        Gap.w12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                symptom.symptom,
                style: context.bodyBold,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text('${AppStrings.severity}: ${symptom.severity}/10 • ${DateFormatter.formatTime(symptom.createdAt)}', style: context.caption.copyWith(color: context.appColorScheme.textMuted)),
            ],
          ),
        ),
      ],
    ),
  );
}
