import 'package:flutter/material.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class EvidenceMethodologyScreen extends StatelessWidget {
  const EvidenceMethodologyScreen({super.key, this.evidence});

  final InsightEvidence? evidence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v2 = context.v2Theme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: v2.scaffold,
      appBar: AppBar(
        backgroundColor: v2.scaffold,
        elevation: 0,
        title: Text(
          'Evidence & Methodology',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: v2.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: v2.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF102319) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.28) : const Color(0xFFDCFCE7)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF16A34A).withValues(alpha: 0.85) : const Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How GutGood Insights Work',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: v2.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Deterministic pattern corroboration built on your personal log data.',
                            style: TextStyle(fontSize: 12, color: v2.textSecondary, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Sample sizes if evidence is passed
              if (evidence != null) ...[
                Text(
                  'Current Analysis Baseline',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: v2.textPrimary),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: v2.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: v2.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(label: 'Meals', value: '${evidence!.sampleSizes.meals}', icon: LucideIcons.utensils),
                      _StatColumn(label: 'Symptoms', value: '${evidence!.sampleSizes.symptoms}', icon: LucideIcons.activity),
                      _StatColumn(label: 'Food Scans', value: '${evidence!.sampleSizes.scans}', icon: LucideIcons.scanLine),
                      _StatColumn(label: 'Window', value: '${evidence!.spanDays}d', icon: LucideIcons.calendar),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              Text(
                '3-Step Pattern Engine Pipeline',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: v2.textPrimary),
              ),
              const SizedBox(height: 12),

              const _StepCard(
                stepNumber: '1',
                title: 'Multi-Meal Corroboration',
                description: 'A candidate pattern requires at least 3 distinct occurrences where the trigger food preceded the symptom within a relevant time window before being highlighted.',
              ),
              const SizedBox(height: 12),

              const _StepCard(
                stepNumber: '2',
                title: 'Timing & Delay Normalization',
                description: 'Digestion times vary by meal composition. The engine maps typical delays (15m to 24h) to distinguish acute gastric reactions from delayed intestinal symptoms.',
              ),
              const SizedBox(height: 12),

              const _StepCard(
                stepNumber: '3',
                title: 'Evidence Ratio & Confidence',
                description: 'The ratio of symptomatic meals versus symptom-free meals containing the ingredient determines the confidence rating (High >80%, Moderate 50-80%, Low <50%).',
              ),

              const SizedBox(height: 24),

              // Disclaimer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? v2.cardSubtle : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: v2.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.info, color: v2.textTertiary, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Disclaimer: GutGood Insights are calculated correlations for personal habit tracking and are not intended to diagnose, treat, or replace professional medical advice.',
                        style: TextStyle(fontSize: 11, color: v2.textTertiary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final v2 = context.v2Theme;
    return Column(
      children: [
        Icon(icon, size: 18, color: v2.success),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: v2.textPrimary),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: v2.textTertiary)),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.stepNumber, required this.title, required this.description});

  final String stepNumber;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final v2 = context.v2Theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: v2.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: v2.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? v2.cardSubtle : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              stepNumber,
              style: TextStyle(fontWeight: FontWeight.bold, color: v2.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: v2.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(fontSize: 12, color: v2.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
