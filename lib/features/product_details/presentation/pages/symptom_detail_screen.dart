import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/utils/date_formatter.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/bento_card.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/bento_widgets.dart' hide BentoCard;
import 'package:gutgood/features/product_details/presentation/widgets/scan_result_widgets.dart';

class SymptomDetailScreen extends StatelessWidget {
  const SymptomDetailScreen({super.key, required this.symptom});
  final SymptomLog symptom;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasMetrics =
        (symptom.energyLevel != null) ||
        (symptom.mood != null && symptom.mood!.isNotEmpty) ||
        (symptom.sleep != null && symptom.sleep!.isNotEmpty) ||
        (symptom.foodName != null && symptom.foodName!.isNotEmpty);
    final hasTriggers = (symptom.foodName != null && symptom.foodName!.isNotEmpty) || (symptom.lastMealFirestoreId != null && symptom.lastMealFirestoreId!.isNotEmpty);
    final hasNotes = symptom.notes != null && symptom.notes!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: isDark ? scheme.cardBackground : const Color(0xFFFCFCFD),
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
                  // 1. Symptom Identity Header (Photo + Severity + Name + Event Date)
                  DashboardEntrance(delay: 50, child: _SymptomHeader(symptom: symptom)),
                  Gap.h20,

                  // 2. Severity Gauge & Band Section
                  DashboardEntrance(delay: 100, child: _SymptomSeveritySection(symptom: symptom)),
                  Gap.h20,

                  // 3. Quick-Signal Metrics Row (Energy, Mood, Sleep, Food)
                  if (hasMetrics) ...[DashboardEntrance(delay: 150, child: _SymptomMetricsRow(symptom: symptom)), Gap.h20],

                  // 4. Potential Triggers & Expert Analysis
                  if (hasTriggers) ...[DashboardEntrance(delay: 200, child: _SymptomTriggerSection(symptom: symptom)), Gap.h20],

                  // 5. Notes & User Observation
                  if (hasNotes) ...[DashboardEntrance(delay: 250, child: _SymptomNotesSection(notes: symptom.notes!)), Gap.h20],

                  // 6. Symptom Details Card (Provenance Footer)
                  DashboardEntrance(delay: 300, child: _SymptomDetailsCard(symptom: symptom)),
                  Gap.h20,

                  // 7. Footer Chat Nudge
                  const DashboardEntrance(delay: 350, child: ScanFooterCard()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🌟 Section 1: Symptom Identity Header (matching ScanScoreHeader).
class _SymptomHeader extends StatelessWidget {
  const _SymptomHeader({required this.symptom});
  final SymptomLog symptom;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final severity = symptom.severity ?? 0;
    final color = _severityColor(severity);
    final hasImage = symptom.imageUrl != null && symptom.imageUrl!.isNotEmpty;
    final size = 104.w;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: t.cardBackground,
            borderRadius: BorderRadius.circular(BentoMetrics.radius.w * 0.75),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular((BentoMetrics.radius.w * 0.75) - 1.2),
            child: hasImage
                ? CachedNetworkImage(
                    imageUrl: symptom.imageUrl!,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      color: color.withValues(alpha: 0.08),
                      child: Center(
                        child: SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: CircularProgressIndicator(strokeWidth: 2, color: color),
                        ),
                      ),
                    ),
                    errorWidget: (_, _, _) => _fallbackTile(color, size),
                  )
                : _fallbackTile(color, size),
          ),
        ),
        Gap.w14,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.symptomAnalysis.toUpperCase(),
                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: (BentoMetrics.eyebrowSize * 0.95).sp, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: t.textSecondary),
              ),
              Gap.h6,
              Text(
                symptom.symptom,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: InsightBentoTheme.fontFamily,
                  fontSize: (BentoMetrics.titleWideSize * 1.05).sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: BentoMetrics.titleWideTracking,
                  height: 1.2,
                  color: t.textPrimary,
                ),
              ),
              Gap.h6,
              if (symptom.foodName != null && symptom.foodName!.isNotEmpty) ...[
                Text(
                  'After ${symptom.foodName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.bodySize.sp, fontWeight: FontWeight.w600, color: t.textPrimary),
                ),
                Gap.h4,
              ],
              Text(
                DateFormatter.formatFull(symptom.eventTime),
                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w400, color: t.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fallbackTile(Color color, double size) => Container(
    width: size,
    height: size,
    color: color.withValues(alpha: 0.12),
    child: Center(
      child: Icon(AppIcons.alertCircle, color: color, size: (size * 0.38).sp),
    ),
  );

  Color _severityColor(int severity) {
    if (severity <= 3) return const Color(0xFF10B981); // Green
    if (severity <= 6) return AppPalette.orange;
    return const Color(0xFFE11D48); // Red
  }
}

/// 🌟 Section 2: Severity Gauge & Band Section (matching ScanScoreSection).
class _SymptomSeveritySection extends StatelessWidget {
  const _SymptomSeveritySection({required this.symptom});
  final SymptomLog symptom;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final severity = symptom.severity ?? 0;
    final color = _severityColor(severity);
    final bandLabel = _severityBand(severity);
    final explanation = _severityExplanation(severity, symptom);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withValues(alpha: 0.14), color.withValues(alpha: 0.05)]),
        borderRadius: BorderRadius.circular(BentoMetrics.radius.w),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      padding: EdgeInsets.all(BentoMetrics.padding.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 96.w,
            child: ScoreGauge(score: (severity * 10).clamp(0, 100), color: color, label: 'SEVERITY', fontSize: 26.sp),
          ),
          Gap.w14,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(100.r)),
                      child: Text(
                        bandLabel.toUpperCase(),
                        style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 9.sp, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Colors.white),
                      ),
                    ),
                    Gap.w6,
                    Text(
                      '$severity/10',
                      style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w800, color: color),
                    ),
                  ],
                ),
                Gap.h6,
                Text(
                  explanation,
                  style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.bodySize.sp, fontWeight: FontWeight.w500, height: 1.4, color: t.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _severityColor(int severity) {
    if (severity <= 3) return const Color(0xFF10B981);
    if (severity <= 6) return AppPalette.orange;
    return const Color(0xFFE11D48);
  }

  String _severityBand(int severity) {
    if (severity <= 3) return 'Mild Reaction';
    if (severity <= 6) return 'Moderate Reaction';
    return 'Severe Reaction';
  }

  String _severityExplanation(int severity, SymptomLog symptom) {
    if (symptom.notes != null && symptom.notes!.isNotEmpty) {
      return symptom.notes!;
    }
    if (severity <= 3) return 'Mild discomfort reported. Keep logging to identify early sensitivity patterns.';
    if (severity <= 6) return 'Moderate reaction recorded. Consider noting nearby meals to pinpoint potential triggers.';
    return 'High severity reaction recorded. Review recent meal logs and consider consulting a gut health specialist.';
  }
}

/// 🌟 Section 3: Quick-Signal Metrics Row (matching ScanMetricsRow).
class _SymptomMetricsRow extends StatelessWidget {
  const _SymptomMetricsRow({required this.symptom});
  final SymptomLog symptom;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final items = <Widget>[];

    if (symptom.energyLevel != null) {
      items.add(
        Expanded(
          child: _MetricTile(icon: AppIcons.zap, color: AppPalette.orange, value: '${symptom.energyLevel}/10', label: 'Energy'),
        ),
      );
    }

    if (symptom.mood != null && symptom.mood!.isNotEmpty) {
      if (items.isNotEmpty) items.add(Gap.w6);
      items.add(
        Expanded(
          child: _MetricTile(icon: AppIcons.smile, color: const Color(0xFF0284C7), value: symptom.mood!.toUpperCase(), label: 'Mood'),
        ),
      );
    }

    if (symptom.sleep != null && symptom.sleep!.isNotEmpty) {
      if (items.isNotEmpty) items.add(Gap.w6);
      items.add(
        Expanded(
          child: _MetricTile(icon: AppIcons.moon, color: const Color(0xFF7C3AED), value: symptom.sleep!.toUpperCase(), label: 'Sleep'),
        ),
      );
    }

    if (symptom.foodName != null && symptom.foodName!.isNotEmpty) {
      if (items.isNotEmpty) items.add(Gap.w6);
      items.add(
        Expanded(
          child: _MetricTile(icon: AppIcons.utensils, color: t.positive, value: symptom.foodName!, label: 'Food'),
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Row(children: items);
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.icon, required this.color, required this.value, required this.label});

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLong = value.length > 10;
    final fontSize = isLong ? 10.sp : 11.5.sp;

    final bgStart = color.withValues(alpha: isDark ? 0.22 : 0.12);
    final bgEnd = color.withValues(alpha: isDark ? 0.12 : 0.04);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [bgStart, bgEnd]),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.12 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.28 : 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24.sp, color: color),
          ),
          Gap.h8,
          Center(
            child: Text(
              value,
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: fontSize, fontWeight: FontWeight.w900, height: 1.15, color: color),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Gap.h2,
          Text(
            label.toUpperCase(),
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: t.textSecondary),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// 🌟 Section 4: Potential Triggers & Expert Analysis (matching ScanWatchSection).
class _SymptomTriggerSection extends StatelessWidget {
  const _SymptomTriggerSection({required this.symptom});
  final SymptomLog symptom;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = <_FactorItem>[];

    if (symptom.foodName != null && symptom.foodName!.isNotEmpty) {
      items.add(_FactorItem(icon: AppIcons.utensils, color: t.negative, title: symptom.foodName!, subtitle: 'Meal consumed shortly before reaction'));
    }

    if (symptom.lastMealFirestoreId != null && symptom.lastMealFirestoreId!.isNotEmpty) {
      items.add(_FactorItem(icon: AppIcons.sparkles, color: const Color(0xFF7C3AED), title: 'Linked Meal Record', subtitle: 'Meal log is being cross-referenced with your pattern history'));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: t.negative.withAlpha(20), shape: BoxShape.circle),
              child: Icon(AppIcons.sparkles, size: 22.sp, color: t.negative),
            ),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.expertAnalysis,
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.titleSize.sp, fontWeight: FontWeight.w700, color: t.textPrimary),
                  ),
                  Text(
                    'Potential food or environmental triggers linked to this reaction.',
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w400, color: t.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        Gap.h16,
        ...items.map((item) => _buildCard(context, item, isDark: isDark)),
      ],
    );
  }

  Widget _buildCard(BuildContext context, _FactorItem item, {required bool isDark}) {
    final t = context.bentoTheme;
    final cardShade = item.color.withValues(alpha: isDark ? 0.16 : 0.08);
    final iconBgColor = item.color.withValues(alpha: isDark ? 0.28 : 0.16);

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
      decoration: BoxDecoration(color: cardShade, borderRadius: BorderRadius.circular(14.r)),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
            child: Icon(item.icon, size: 16.sp, color: item.color),
          ),
          Gap.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w700, color: t.textPrimary, height: 1.2),
                ),
                Gap.h2,
                Text(
                  item.subtitle,
                  style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w400, color: t.textSecondary, height: 1.3),
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

class _FactorItem {
  _FactorItem({required this.icon, required this.color, required this.title, required this.subtitle});
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
}

/// 🌟 Section 5: Reaction Notes & User Observation (matching ScanDetailsCard).
class _SymptomNotesSection extends StatelessWidget {
  const _SymptomNotesSection({required this.notes});
  final String notes;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;

    return Container(
      padding: EdgeInsets.all(BentoMetrics.padding.w),
      decoration: BoxDecoration(color: t.cardBackground, borderRadius: BorderRadius.circular(BentoMetrics.radius.w)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BentoCardHeader(title: 'REACTION MEMO', icon: AppIcons.fileText),
          Gap.h12,
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(color: t.border.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10.r)),
            child: Text(
              notes,
              style: TextStyle(
                fontFamily: InsightBentoTheme.fontFamily,
                fontSize: BentoMetrics.bodySize.sp,
                fontWeight: FontWeight.w500,
                height: 1.5,
                color: t.textPrimary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🌟 Section 6: Symptom Provenance Details (matching ScanDetailsCard).
class _SymptomDetailsCard extends StatelessWidget {
  const _SymptomDetailsCard({required this.symptom});
  final SymptomLog symptom;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final date = DateFormatter.formatFull(symptom.eventTime);

    return Container(
      padding: EdgeInsets.all(BentoMetrics.padding.w),
      decoration: BoxDecoration(color: t.cardBackground, borderRadius: BorderRadius.circular(BentoMetrics.radius.w)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BentoCardHeader(title: 'LOG DETAILS', icon: AppIcons.info),
          Gap.h12,
          _detailRow(context, 'Recorded On', date, AppIcons.calendar),
          Gap.h8,
          _detailRow(context, 'Source', symptom.source?.toUpperCase() ?? AppStrings.chatSource, AppIcons.database),
          Gap.h8,
          _detailRow(context, 'Severity Level', '${symptom.severity ?? 0} / 10', AppIcons.activity),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value, IconData icon) {
    final t = context.bentoTheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(color: t.border.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8.r)),
      child: Row(
        children: [
          Icon(icon, size: 14.sp, color: t.textTertiary),
          Gap.w8,
          Text(
            label,
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w500, color: t.textSecondary),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w700, color: t.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
