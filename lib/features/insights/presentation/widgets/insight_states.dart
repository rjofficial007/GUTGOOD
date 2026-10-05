import 'package:flutter/material.dart';

/// A compact state card that can be used in a page, list or SliverToBoxAdapter.
class InsightEmptyStateCard extends StatelessWidget {
  const InsightEmptyStateCard({
    super.key,
    this.title = 'No insights yet',
    this.message = 'Log a meal and how you feel to start building your personal picture.',
    this.icon = Icons.insights_outlined,
    this.actionLabel,
    this.onAction,
  });

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
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: CircleAvatar(
                radius: 24,
                backgroundColor: colors.primaryContainer,
                child: Icon(icon, color: colors.onPrimaryContainer),
              ),
            ),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant, height: 1.5)),
            if (onAction != null && actionLabel != null) ...[const SizedBox(height: 16), FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!))],
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF171717) : Colors.white;
    final skeleton = isDark ? const Color(0xFF303030) : const Color(0xFFEAEAEA);
    final border = isDark ? const Color(0xFF303030) : const Color(0xFFE8E8E8);

    return Semantics(
      label: label,
      liveRegion: true,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _line(context, 220, 20, color: skeleton),
                  const SizedBox(height: 10),
                  _line(context, double.infinity, 12, color: skeleton),
                  const SizedBox(height: 8),
                  _line(context, 190, 12, color: skeleton),
                  const SizedBox(height: 22),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final height in [24.0, 36.0, 29.0, 48.0, 40.0, 58.0, 46.0])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Container(
                              height: height,
                              decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < 2; i++) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(14)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _line(context, 130, 12, color: skeleton),
                          const SizedBox(height: 9),
                          _line(context, double.infinity, 10, color: skeleton),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (i == 0) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _line(BuildContext context, double width, double height, {required Color color}) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
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
    final color = negative
        ? colors.error
        : positive
        ? colors.primary
        : colors.onSurfaceVariant;
    final label = value == null
        ? 'No comparison yet'
        : value == 0
        ? 'No change'
        : '${positive ? '+' : ''}$value pts';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive
                ? Icons.trending_up
                : negative
                ? Icons.trending_down
                : Icons.remove,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
