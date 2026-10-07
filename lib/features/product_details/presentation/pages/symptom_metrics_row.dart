part of 'symptom_detail_screen.dart';

/// Symptom metrics presentation components.

class _SymptomMetricsRow extends StatelessWidget {
  const _SymptomMetricsRow({required this.symptom});
  final SymptomLog symptom;

  @override
  Widget build(BuildContext context) {
    final metrics = <Widget>[];
    final severity = symptom.severity;
    if (severity != null) {
      metrics.add(_MetricCard(icon: AppIcons.activity, color: _severityColor(severity), value: '$severity/10', label: 'Severity'));
    }
    if (symptom.mood != null && symptom.mood!.isNotEmpty) {
      metrics.add(_MetricCard(icon: AppIcons.smile, color: const Color(0xFF0284C7), value: symptom.mood!.toUpperCase(), label: 'Mood'));
    }
    if (symptom.sleep != null && symptom.sleep!.isNotEmpty) {
      metrics.add(_MetricCard(icon: AppIcons.moon, color: const Color(0xFF7C3AED), value: symptom.sleep!.toUpperCase(), label: 'Sleep'));
    }
    if (metrics.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (var i = 0; i < metrics.length; i++) ...[if (i > 0) Gap.w6, Expanded(child: metrics[i])],
      ],
    );
  }

  Color _severityColor(int severity) {
    if (severity <= 3) return const Color(0xFF10B981);
    if (severity <= 6) return AppPalette.orange;
    return const Color(0xFFE11D48);
  }
}
