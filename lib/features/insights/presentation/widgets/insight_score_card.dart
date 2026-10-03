import 'package:flutter/material.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_states.dart';

/// Score and comparison are separate: absence of a comparison is not a gain.
class InsightScoreCard extends StatelessWidget {
  const InsightScoreCard({super.key, required this.score, this.delta, this.onTap, this.onWhyTap});
  final int? score;
  final int? delta;
  final VoidCallback? onTap;
  final VoidCallback? onWhyTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final value = score;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: colors.outlineVariant)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('YOUR GUT SCORE', style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 1.2, color: colors.onSurfaceVariant)),
          const SizedBox(height: 12),
          Wrap(spacing: 16, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Semantics(
              label: value == null ? 'Gut score unavailable' : 'Gut score $value out of 100',
              excludeSemantics: true,
              child: Text.rich(TextSpan(children: [
                TextSpan(text: value == null ? '—' : '$value', style: theme.textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -2)),
                TextSpan(text: ' / 100', style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurfaceVariant)),
              ])),
            ),
            InsightTrendBadge(delta: value == null ? null : delta),
          ]),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: value == null ? 0 : (value / 100).clamp(0, 1),
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
            backgroundColor: colors.surfaceContainerHighest,
            semanticsLabel: value == null ? 'Score unavailable' : 'Score progress',
          ),
          const SizedBox(height: 16),
          Text(value == null ? 'A score will appear when enough scored logs are available.' : delta == null ? 'Your starting point. Future scores will help show how things change.' : delta == 0 ? 'Your score is unchanged from the previous recorded insight.' : 'Your score is ${delta! > 0 ? 'higher' : 'lower'} than the previous recorded insight.', style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant, height: 1.5)),
          if (onTap != null || (onWhyTap != null && value != null)) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              if (onTap != null) TextButton.icon(onPressed: onTap, icon: const Icon(Icons.show_chart, size: 18), label: const Text('Score history')),
              if (onWhyTap != null && value != null) TextButton(onPressed: onWhyTap, child: const Text('How it’s calculated')),
            ]),
          ],
        ]),
      ),
    );
  }
}
