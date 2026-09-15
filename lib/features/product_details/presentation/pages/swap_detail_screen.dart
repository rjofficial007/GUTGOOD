import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/utils/image_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/insight_bento_theme.dart';

/// Detail view for one recommended swap.
class SwapDetailScreen extends StatelessWidget {
  const SwapDetailScreen({super.key, required this.swap});
  final ProductSwap swap;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = (swap.imageUrl != null && swap.imageUrl!.isNotEmpty) ? swap.imageUrl! : getDynamicImageUrl(swap.imageKeyword.isNotEmpty ? swap.imageKeyword : swap.title);

    final cardShade = t.positive.withValues(alpha: isDark ? 0.16 : 0.08);

    return Scaffold(
      backgroundColor: t.cardBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          GutSliverAppBar(title: AppStrings.betterSwapsLabel, centerTitle: true, backgroundColor: t.cardBackground.withValues(alpha: 0.8)),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.w, 16.w, 32.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Swap Card
                  DashboardEntrance(
                    delay: 50,
                    child: Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(color: cardShade, borderRadius: BorderRadius.circular(16.r)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              height: 200.h,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => Container(
                                height: 200.h,
                                color: t.positive.withValues(alpha: 0.12),
                                child: Center(
                                  child: SizedBox(
                                    width: 24.w,
                                    height: 24.w,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: t.positive),
                                  ),
                                ),
                              ),
                              errorWidget: (_, _, _) => Container(
                                height: 200.h,
                                color: t.positive.withValues(alpha: 0.12),
                                child: Center(
                                  child: Icon(AppIcons.salad, color: t.positive, size: 40.sp),
                                ),
                              ),
                            ),
                          ),
                          Gap.h14,
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: t.positive.withValues(alpha: isDark ? 0.28 : 0.16),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              swap.tag.toUpperCase(),
                              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, color: t.positive, fontSize: 9.5.sp, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                            ),
                          ),
                          Gap.h6,
                          Text(
                            swap.title,
                            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 20.sp, fontWeight: FontWeight.w900, color: t.textPrimary, height: 1.2),
                          ),
                          if (swap.subtitle.isNotEmpty) ...[
                            Gap.h8,
                            Text(
                              swap.subtitle,
                              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, color: t.textSecondary, height: 1.45, fontSize: 13.5.sp, fontWeight: FontWeight.w400),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Gap.h16,

                  // Benefits Card
                  DashboardEntrance(
                    delay: 100,
                    child: Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: t.positive.withValues(alpha: isDark ? 0.12 : 0.05),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(AppIcons.sparkles, size: 16.sp, color: t.positive),
                              Gap.w8,
                              Text(
                                'WHY THIS SWAP IS BETTER',
                                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: t.positive),
                              ),
                            ],
                          ),
                          Gap.h10,
                          _benefitRow(t, 'Cleaner, whole food ingredients with fewer additives'),
                          Gap.h6,
                          _benefitRow(t, 'Supports gut barrier health and easier digestion'),
                          Gap.h6,
                          _benefitRow(t, 'Lower inflammatory trigger potential'),
                        ],
                      ),
                    ),
                  ),
                  Gap.h40,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefitRow(InsightBentoTheme t, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.check_circle_rounded, size: 15.sp, color: t.positive),
      Gap.w8,
      Expanded(
        child: Text(
          text,
          style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w500, color: t.textSecondary, height: 1.3),
        ),
      ),
    ],
  );
}
