part of 'insights_feed.dart';

/// Recent food-impact list components.

class _RecentFoodImpactsSection extends StatelessWidget {
  const _RecentFoodImpactsSection({this.impacts = const [], this.onSeeAll});

  final List<FoodImpact> impacts;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(12.w),
    decoration: BoxDecoration(
      color: context.insightTheme.card,
      borderRadius: BorderRadius.circular(20.w),
      border: Border.all(color: context.insightTheme.borderSubtle),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RecentFoodImpactsHeader(onSeeAll: onSeeAll, isEmpty: impacts.isEmpty),
        if (impacts.isNotEmpty) ...[
          Gap.h10,
          for (var i = 0; i < impacts.take(4).length; i++) ...[
            if (i > 0)
              Row(
                children: [
                  SizedBox(width: 56.w),
                  Expanded(
                    child: Divider(height: 14.w, color: context.insightTheme.borderSubtle),
                  ),
                ],
              ),
            _FoodImpactRow(
              imageUrl: impacts[i].userImageUrl ?? impacts[i].imageUrl,
              title: impacts[i].food,
              sub: '${impacts[i].dateLabel} • ${impacts[i].timeframeLabel}',
              status: impacts[i].effect,
              isPositive: const {'positive', 'healing', 'good', 'supportive'}.contains(impacts[i].impactType.toLowerCase().trim()),
              isNegative: const {'negative', 'trigger', 'bad', 'watch'}.contains(impacts[i].impactType.toLowerCase().trim()),
            ),
          ],
        ],
      ],
    ),
  );
}

class _RecentFoodImpactsHeader extends StatelessWidget {
  const _RecentFoodImpactsHeader({this.onSeeAll, this.isEmpty = false});

  final VoidCallback? onSeeAll;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) => FoodImpactSectionHeader(
    title: 'Recent Food Impacts',
    subtitle: isEmpty ? 'No recent impacts yet. Log meals and symptoms to see how specific foods relate to your gut.' : 'Your latest logged food responses.',
    icon: LucideIcons.clock,
    iconColor: const Color(0xFF2563EB),
    trailing: onSeeAll == null ? null : FoodImpactSectionAction(label: 'See All', onPressed: onSeeAll!),
  );
}

class _FoodImpactRow extends StatelessWidget {
  const _FoodImpactRow({required this.imageUrl, required this.title, required this.sub, required this.status, required this.isPositive, required this.isNegative});

  final String? imageUrl;
  final String title;
  final String sub;
  final String status;
  final bool isPositive;
  final bool isNegative;

  @override
  Widget build(BuildContext context) {
    final impactColor = isPositive
        ? const Color(0xFF15803D)
        : isNegative
        ? const Color(0xFFB42318)
        : context.insightTheme.textTertiary;
    final impactIcon = isPositive
        ? LucideIcons.leaf
        : isNegative
        ? LucideIcons.triangleAlert
        : Icons.info_outline_rounded;
    final impactLabel = isPositive
        ? 'Positive'
        : isNegative
        ? 'Negative'
        : 'Observation';
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12.w),
          child: DynamicFoodImage(
            keyword: title,
            imageUrl: imageUrl,
            width: 46.w,
            height: 46.w,
            fit: BoxFit.cover,
            placeholder: Container(color: context.insightTheme.cardSubtle),
            errorWidget: Container(
              color: context.insightTheme.cardSubtle,
              alignment: Alignment.center,
              child: Icon(Icons.image_outlined, size: 18.w, color: context.insightTheme.textTertiary),
            ),
          ),
        ),
        Gap.w10,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
              ),
              Text(
                sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, color: context.insightColor(const Color(0xFF64748B))),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 100.w,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(impactIcon, size: 11.w, color: impactColor),
                  Gap.w4,
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 76.w),
                    child: Text(
                      status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w600, color: context.insightColor(const Color(0xFF0F172A))),
                    ),
                  ),
                ],
              ),
              Gap.h2,
              Text(
                impactLabel,
                style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.sp, fontWeight: FontWeight.w700, color: impactColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// FOOD IMPACT TAB: 5. YOUR NEXT STEPS SECTION
// =============================================================================
