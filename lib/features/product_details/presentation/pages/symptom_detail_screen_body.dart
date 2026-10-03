part of 'symptom_detail_screen.dart';

/// Symptom detail screen body.

class SymptomDetailScreen extends StatelessWidget {
  const SymptomDetailScreen({super.key, required this.symptom});
  final SymptomLog symptom;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasTriggers = (symptom.foodName != null && symptom.foodName!.isNotEmpty) || (symptom.lastMealFirestoreId != null && symptom.lastMealFirestoreId!.isNotEmpty);
    final hasNotes = symptom.notes != null && symptom.notes!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: isDark ? scheme.cardBackground : const Color(0xFFFCFCFD),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const GutSliverAppBar(title: 'Symptom result', centerTitle: true),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Symptom Identity Header (Photo + Severity Badge + Name + Tags)
                  DashboardEntrance(delay: 50, child: _SymptomHeader(symptom: symptom)),
                  Gap.h20,

                  // 2. Severity Gauge & Band Section + Expandable "Why this severity"
                  DashboardEntrance(delay: 100, child: _SymptomSeveritySection(symptom: symptom)),
                  Gap.h20,

                  // 3. Quick-Signal Metric Cards Row (Severity, Energy, Mood, Sleep)
                  DashboardEntrance(delay: 150, child: _SymptomMetricsRow(symptom: symptom)),
                  Gap.h20,

                  // 4. Potential Triggers & Expert Analysis
                  if (hasTriggers) ...[DashboardEntrance(delay: 200, child: _SymptomTriggerSection(symptom: symptom)), Gap.h20],

                  // 5. Reaction Memo & User Observation
                  if (hasNotes) ...[DashboardEntrance(delay: 250, child: _SymptomNotesSection(notes: symptom.notes!)), Gap.h20],

                  // 6. Log Details (Provenance Footer)
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
              Gap.h10,
              Wrap(
                spacing: 6.w,
                runSpacing: 6.h,
                children: [
                  ProductDetailHeaderTag(label: 'Severity ${symptom.severity ?? 0}/10', color: color, uppercaseLabel: true),
                  ProductDetailHeaderTag(label: DateFormatter.formatFull(symptom.eventTime), color: t.textSecondary, uppercaseLabel: true),
                  if (symptom.foodName != null && symptom.foodName!.isNotEmpty) ProductDetailHeaderTag(label: 'After ${symptom.foodName}', color: t.positive, icon: AppIcons.utensils, uppercaseLabel: true),
                  if (symptom.source != null && symptom.source!.isNotEmpty) ProductDetailHeaderTag(label: symptom.source!.toUpperCase(), color: t.textSecondary, uppercaseLabel: true),
                ],
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
    color: color.withValues(alpha: 0.1),
    child: Center(
      child: Icon(AppIcons.alertCircle, color: color, size: (size * 0.36).sp),
    ),
  );

  Color _severityColor(int severity) {
    if (severity <= 3) return const Color(0xFF10B981);
    if (severity <= 6) return AppPalette.orange;
    return const Color(0xFFE11D48);
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
    final factors = _getSeverityFactors(symptom);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withValues(alpha: 0.14), color.withValues(alpha: 0.05)]),
        borderRadius: BorderRadius.circular(BentoMetrics.radius.w),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      padding: EdgeInsets.all(BentoMetrics.padding.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          if (factors.isNotEmpty) ...[Gap.h14, _WhySeverityExpander(factors: factors, bandColor: color)],
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

  List<_SymptomFactor> _getSeverityFactors(SymptomLog symptom) {
    final factors = <_SymptomFactor>[];
    final severity = symptom.severity ?? 0;

    factors.add(
      _SymptomFactor(
        label: 'Symptom Intensity · $severity/10',
        isNegative: severity > 3,
        phrase: severity <= 3 ? 'low physical discomfort' : (severity <= 6 ? 'moderate gut distress' : 'severe gut reaction'),
      ),
    );

    if (symptom.energyLevel != null) {
      final e = symptom.energyLevel!;
      factors.add(_SymptomFactor(label: 'Energy Level · $e/10', isNegative: e < 5, phrase: e >= 7 ? 'good vitality retained' : 'reduced energy level'));
    }

    if (symptom.mood != null && symptom.mood!.isNotEmpty) {
      factors.add(
        _SymptomFactor(
          label: 'Mood State · ${symptom.mood!.toUpperCase()}',
          isNegative: ['anxious', 'stressed', 'sad', 'irritated', 'low'].contains(symptom.mood!.toLowerCase()),
          phrase: 'emotional state logged',
        ),
      );
    }

    if (symptom.foodName != null && symptom.foodName!.isNotEmpty) {
      factors.add(_SymptomFactor(label: 'Associated Food · ${symptom.foodName}', isNegative: true, phrase: 'potential dietary trigger under review'));
    }

    return factors;
  }
}

