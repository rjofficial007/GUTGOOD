part of 'scan_result_widgets.dart';

/// Better-swap presentation components.

class ScanSwapsSection extends StatelessWidget {
  const ScanSwapsSection({super.key, required this.swaps});
  final List<ProductSwap> swaps;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    if (swaps.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: t.orange.withAlpha(26), shape: BoxShape.circle),
              child: Icon(AppIcons.lightbulb, size: 22.sp, color: t.orange),
            ),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.betterSwapsLabel,
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.titleSize.sp, fontWeight: FontWeight.w700, color: t.textPrimary),
                  ),
                  Text(
                    'Simple swaps to make this meal even better.',
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w400, color: t.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        Gap.h16,
        SizedBox(
          height: 186.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: swaps.length,
            separatorBuilder: (_, _) => Gap.w10,
            itemBuilder: (context, i) => _SwapCard(swap: swaps[i]),
          ),
        ),
      ],
    );
  }
}

class _SwapCard extends StatelessWidget {
  const _SwapCard({required this.swap});
  final ProductSwap swap;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = (swap.imageUrl != null && swap.imageUrl!.isNotEmpty) ? swap.imageUrl! : getDynamicImageUrl(swap.imageKeyword.isNotEmpty ? swap.imageKeyword : swap.title);
    final cardShade = t.positive.withValues(alpha: isDark ? 0.16 : 0.08);

    return InkWell(
      onTap: () => context.push(AppRoutes.swapDetail, extra: swap),
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        width: 164.w,
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(color: cardShade, borderRadius: BorderRadius.circular(14.r)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 84.h,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => Container(
                  height: 84.h,
                  color: t.positive.withValues(alpha: 0.12),
                  child: Center(
                    child: Icon(AppIcons.salad, color: t.positive, size: 24.sp),
                  ),
                ),
              ),
            ),
            Gap.h8,
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: t.positive.withValues(alpha: isDark ? 0.25 : 0.14),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                swap.tag,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w900, letterSpacing: 0.6, color: t.positive),
              ),
            ),
            Gap.h4,
            Text(
              swap.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: t.textPrimary),
            ),
            Gap.h2,
            Expanded(
              child: Text(
                swap.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w400, height: 1.2, color: t.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🌟 Section 8: Additives (modern cards → additive detail; clean state when none).
