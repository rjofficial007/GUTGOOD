import 'package:flutter/material.dart';

/// A compact state card that can be used in a page, list or SliverToBoxAdapter.
class InsightEmptyStateCard extends StatelessWidget {
  const InsightEmptyStateCard({super.key, this.title = 'No insights yet', this.message = 'Log a meal and how you feel to start building your personal picture.', this.icon = Icons.insights_outlined, this.actionLabel, this.onAction});

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: colors.outlineVariant)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(child: CircleAvatar(radius: 24, backgroundColor: colors.primaryContainer, child: Icon(icon, color: colors.onPrimaryContainer))),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant, height: 1.5)),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class InsightErrorStateCard extends StatelessWidget {
  const InsightErrorStateCard({super.key, required this.onRetry, this.hasCachedData = false});
  final VoidCallback onRetry;
  final bool hasCachedData;

  @override
  Widget build(BuildContext context) => InsightEmptyStateCard(
    title: hasCachedData ? 'Couldn’t refresh insights' : 'Couldn’t load insights',
    message: hasCachedData ? 'Your last saved insights are shown below. Try again when you’re ready.' : 'Your logs are safe. Check your connection and try again.',
    icon: Icons.cloud_off_outlined,
    actionLabel: 'Try again',
    onAction: onRetry,
  );
}

/// Static skeletons respect reduced motion and avoid an endless shimmer.
class InsightLoadingState extends StatelessWidget {
  const InsightLoadingState({super.key, this.label = 'Loading insights'});
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    liveRegion: true,
    child: ExcludeSemantics(
      child: Column(
        children: [
          for (final height in [184.0, 116.0, 116.0])
            Container(
              height: height,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(24)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _line(context, 100, 12),
                const SizedBox(height: 16),
                _line(context, 180, 20),
              ]),
            ),
        ],
      ),
    ),
  );

  Widget _line(BuildContext context, double width, double height) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
  );
}

class InsightTrendBadge extends StatelessWidget {
  const InsightTrendBadge({super.key, required this.delta});
  final int? delta;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final value = delta;
    final positive = value != null && value > 0;
    final negative = value != null && value < 0;
    final color = negative ? colors.error : positive ? colors.primary : colors.onSurfaceVariant;
    final label = value == null ? 'No comparison yet' : value == 0 ? 'No change' : '${positive ? '+' : ''}$value pts';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(positive ? Icons.trending_up : negative ? Icons.trending_down : Icons.remove, size: 18, color: color),
        const SizedBox(width: 6),
        Flexible(child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700))),
      ]),
    );
  }
}
