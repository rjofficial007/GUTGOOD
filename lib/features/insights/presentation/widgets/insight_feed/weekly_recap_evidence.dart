part of 'insights_feed.dart';

/// Weekly recap evidence and highlight presentation components.

class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow({required this.label, required this.count});

  final String label;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(LucideIcons.checkSquare, size: 9.w, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
            Gap.w3,
            Text(
              label,
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, color: context.insightColor(const Color(0xFF334155))),
            ),
          ],
        ),
        Text(
          count?.toString() ?? '—',
          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
        ),
      ],
    );
  }
}

class _WeeklyHighlightsCard extends StatelessWidget {
  const _WeeklyHighlightsCard({required this.recap});

  final WeeklyRecap? recap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlights = (recap?.highlights ?? const []).where((h) => h is RecapHighlight ? h.text.trim().isNotEmpty : h is String && h.trim().isNotEmpty).toList();

    if (highlights.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: context.insightColor(const Color(0xFFF0FDF4)),
          borderRadius: BorderRadius.circular(20.w),
          border: Border.all(color: context.insightColor(const Color(0xFFDCFCE7))),
        ),
        child: Text(
          'No weekly highlights yet. They’ll appear as your logs reveal useful trends.',
          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, color: context.insightColor(const Color(0xFF475569))),
        ),
      );
    }

    final h1 = highlights.first;
    final h2 = highlights.length > 1 ? highlights[1] : null;

    final highlight1 = h1 is RecapHighlight ? h1.text : h1 is String ? h1 : '';
    const sub1 = 'From your logs';

    final highlight2 = h2 is RecapHighlight ? h2.text : h2 is String ? h2 : '';
    const sub2 = 'From your logs';

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.insightColor(const Color(0xFFF0FDF4)),
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: context.insightColor(const Color(0xFFDCFCE7))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.star, size: 15.w, color: const Color(0xFFD97706)),
                  Gap.w6,
                  Text(
                    'Weekly Highlights',
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                  ),
                ],
              ),
            ],
          ),
          Gap.h8,

          Row(
            children: [
              if (highlight1.isNotEmpty) Expanded(
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: context.insightTheme.card,
                    borderRadius: BorderRadius.circular(14.w),
                    border: Border.all(color: context.insightColor(const Color(0xFFDCFCE7))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(5.w),
                        decoration: BoxDecoration(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.20) : const Color(0xFFDCFCE7), shape: BoxShape.circle),
                        child: Icon(LucideIcons.leaf, size: 12.w, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
                      ),
                      Gap.w8,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              highlight1,
                              style: TextStyle(
                                fontFamily: InsightTheme.fontFamily,
                                fontSize: 10.5.sp,
                                fontWeight: FontWeight.w700,
                                color: context.insightColor(const Color(0xFF0F172A)),
                                height: 1.2,
                              ),
                            ),
                            Gap.h2,
                            Text(
                              sub1,
                              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.sp, color: context.insightColor(const Color(0xFF64748B))),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (highlight1.isNotEmpty && highlight2.isNotEmpty) Gap.w8,

              if (highlight2.isNotEmpty) Expanded(
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: context.insightTheme.card,
                    borderRadius: BorderRadius.circular(14.w),
                    border: Border.all(color: context.insightColor(const Color(0xFFDCFCE7))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(5.w),
                        decoration: BoxDecoration(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.20) : const Color(0xFFDCFCE7), shape: BoxShape.circle),
                        child: Icon(LucideIcons.arrowDown, size: 12.w, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
                      ),
                      Gap.w8,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              highlight2,
                              style: TextStyle(
                                fontFamily: InsightTheme.fontFamily,
                                fontSize: 10.5.sp,
                                fontWeight: FontWeight.w700,
                                color: context.insightColor(const Color(0xFF0F172A)),
                                height: 1.2,
                              ),
                            ),
                            Gap.h2,
                            Text(
                              sub2,
                              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.sp, color: context.insightColor(const Color(0xFF64748B))),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyTopFoodsRow extends StatelessWidget {
  const _WeeklyTopFoodsRow({required this.data});

  final AIInsight data;

  @override
  Widget build(BuildContext context) {
    final topHealing =
        data.healingSummary?.foods.firstOrNull ??
        (data.healingFoods.isNotEmpty
            ? InsightFood(
                foodId: 'h_${data.healingFoods.first.name}',
                name: data.healingFoods.first.name,
                emoji: data.healingFoods.first.emoji,
                imageUrl: data.healingFoods.first.userImageUrl ?? data.healingFoods.first.imageUrl,
                effect: data.healingFoods.first.effect,
              )
            : null);

    final topTrigger =
        data.triggerSummary?.foods.firstOrNull ??
        (data.triggerFoods.isNotEmpty
            ? InsightFood(
                foodId: 't_${data.triggerFoods.first.name}',
                name: data.triggerFoods.first.name,
                emoji: data.triggerFoods.first.emoji,
                imageUrl: data.triggerFoods.first.userImageUrl ?? data.triggerFoods.first.imageUrl,
                effect: data.triggerFoods.first.effect,
              )
            : null);

    if (topHealing == null && topTrigger == null) {
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
            Text(
              'Weekly Top Foods',
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
            ),
            Gap.h4,
            Text(
              'No top supportive or trigger foods recorded yet for this week.',
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, color: context.insightColor(const Color(0xFF64748B))),
            ),
          ],
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Card: Top Healing Food
          if (topHealing != null) ...[
            Expanded(
              child: Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF102319) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(18.w),
                  border: Border.all(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.28) : const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
                              child: Icon(LucideIcons.arrowUp, size: 10.w, color: Colors.white),
                            ),
                            Gap.w4,
                            Expanded(
                              child: Text(
                                'Top Healing Food',
                                style: TextStyle(
                                  fontFamily: InsightTheme.fontFamily,
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Gap.h8,

                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.w),
                          child: CachedNetworkImage(imageUrl: topHealing.imageUrl ?? InsightUiKit.foodImageUrl(topHealing.name), height: 64.w, width: double.infinity, fit: BoxFit.cover),
                        ),
                        Gap.h6,

                        Text(
                          topHealing.name,
                          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                        ),
                        Gap.h2,
                        Text(
                          topHealing.effect ?? 'No effect details available.',
                          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, color: context.insightColor(const Color(0xFF64748B)), height: 1.15),
                        ),
                      ],
                    ),
                    Gap.h6,

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Observed',
                          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.w),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.18) : const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8.w),
                            border: Border.all(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.35) : const Color(0xFFBBF7D0), width: 0.8.w),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.leaf, size: 8.w, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
                              Gap.w2,
                              Text(
                                'Supportive observation',
                                style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.sp, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (topHealing != null && topTrigger != null) Gap.w10,

          // Right Card: Top Trigger Food
          if (topTrigger != null) ...[
            Expanded(
              child: Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF231416) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(18.w),
                  border: Border.all(color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.45) : const Color(0xFFFCA5A5), width: 1.2.w),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626)).withValues(alpha: isDark ? 0.08 : 0.04),
                      blurRadius: 10.w,
                      offset: Offset(0, 2.w),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
                              child: Icon(LucideIcons.triangleAlert, size: 10.w, color: Colors.white),
                            ),
                            Gap.w4,
                            Expanded(
                              child: Text(
                                'Top Trigger Food',
                                style: TextStyle(
                                  fontFamily: InsightTheme.fontFamily,
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? const Color(0xFFF87171) : const Color(0xFF991B1B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Gap.h8,

                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.w),
                          child: CachedNetworkImage(imageUrl: topTrigger.imageUrl ?? InsightUiKit.foodImageUrl(topTrigger.name), height: 64.w, width: double.infinity, fit: BoxFit.cover),
                        ),
                        Gap.h6,

                        Text(
                          topTrigger.name,
                          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                        ),
                        Gap.h2,
                        Text(
                          topTrigger.effect ?? 'No effect details available.',
                          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, color: context.insightColor(const Color(0xFF64748B)), height: 1.15),
                        ),
                      ],
                    ),
                    Gap.h6,

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Observed',
                          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.w),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.18) : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8.w),
                            border: Border.all(color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.35) : const Color(0xFFFECACA), width: 0.8.w),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.triangleAlert, size: 8.w, color: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C)),
                              Gap.w2,
                              Text(
                                'Symptom observation',
                                style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.sp, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

