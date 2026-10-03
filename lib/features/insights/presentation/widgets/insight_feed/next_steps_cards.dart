part of 'insights_feed.dart';

/// Food-impact next-step action cards.

class _YourNextStepsSection extends StatelessWidget {
  const _YourNextStepsSection({this.actions = const [], this.insight});

  final List<InsightAction> actions;
  final AIInsight? insight;

  @override
  Widget build(BuildContext context) {
    final resolvedActions = actions.isNotEmpty
        ? actions
        : [
            if (insight?.actions.isNotEmpty == true)
              for (var i = 0; i < insight!.actions.length; i++) InsightAction(id: 'act_${i + 1}', title: insight!.actions[i], description: 'Actionable step grounded in your recent meal logs.')
            else if (insight?.topInsight?.nextSteps.isNotEmpty == true)
              for (var i = 0; i < insight!.topInsight!.nextSteps.length; i++)
                InsightAction(id: 'step_${i + 1}', title: insight!.topInsight!.nextSteps[i], description: 'Recommended next step based on your symptoms.'),
          ];

    if (resolvedActions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: context.insightTheme.card,
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.sprout, size: 15.w, color: const Color(0xFF15803D)),
                Gap.w6,
                Text(
                  'Your Next Steps',
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                ),
              ],
            ),
            Gap.h4,
            Text(
              'No action steps recommended right now. Continue logging meals and symptoms to receive personalized guidance.',
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, color: context.insightColor(const Color(0xFF64748B))),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(LucideIcons.sprout, size: 15.w, color: const Color(0xFF15803D)),
                Gap.w6,
                Text(
                  'Your Next Steps',
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                ),
              ],
            ),
          ],
        ),
        Gap.h8,

        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < resolvedActions.take(2).length; i++) ...[
                if (i > 0) Gap.w10,
                Expanded(
                  child: _NextStepCard(
                    icon: i == 0 ? LucideIcons.leaf : LucideIcons.sprout,
                    title: resolvedActions[i].title,
                    sub: resolvedActions[i].description.isNotEmpty ? resolvedActions[i].description : 'Actionable guidance derived from your meal history.',
                    onTap: () {},
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NextStepCard extends StatelessWidget {
  const _NextStepCard({required this.icon, required this.title, required this.sub, this.onTap});

  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.insightTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.w),
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF102319) : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.3) : const Color(0xFFDCFCE7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 24.w,
                      height: 24.w,
                      decoration: BoxDecoration(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.20) : const Color(0xFFDCFCE7), shape: BoxShape.circle),
                      child: Icon(icon, size: 12.w, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
                    ),
                  ],
                ),
                Gap.h6,
                Text(
                  title,
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w800, color: theme.textPrimary, height: 1.2),
                ),
                Gap.h3,
                Text(
                  sub,
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, color: theme.textSecondary, height: 1.25),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// PATTERNS TAB: BOTTOM SMARTER BANNER CARD
// =============================================================================
