part of 'symptom_detail_screen.dart';

/// Symptom metrics presentation components.

class _SymptomMetricsRow extends StatelessWidget {
  const _SymptomMetricsRow({required this.symptom});
  final SymptomLog symptom;

  @override
  Widget build(BuildContext context) {
    final severity = symptom.severity ?? 0;
    final severityColor = _severityColor(severity);

    return Row(
      children: [
        Expanded(
          child: _MetricCard(icon: AppIcons.activity, color: severityColor, value: '$severity/10', label: 'Severity'),
        ),
        Gap.w6,
        Expanded(
          child: _MetricCard(icon: AppIcons.zap, color: AppPalette.orange, value: symptom.energyLevel != null ? '${symptom.energyLevel}/10' : '–', label: 'Energy'),
        ),
        Gap.w6,
        Expanded(
          child: _MetricCard(icon: AppIcons.smile, color: const Color(0xFF0284C7), value: symptom.mood != null && symptom.mood!.isNotEmpty ? symptom.mood!.toUpperCase() : '–', label: 'Mood'),
        ),
        Gap.w6,
        Expanded(
          child: _MetricCard(icon: AppIcons.moon, color: const Color(0xFF7C3AED), value: symptom.sleep != null && symptom.sleep!.isNotEmpty ? symptom.sleep!.toUpperCase() : '–', label: 'Sleep'),
        ),
      ],
    );
  }

  Color _severityColor(int severity) {
    if (severity <= 3) return const Color(0xFF10B981);
    if (severity <= 6) return AppPalette.orange;
    return const Color(0xFFE11D48);
  }
}

