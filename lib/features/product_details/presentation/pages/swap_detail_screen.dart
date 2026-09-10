import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/image_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/bento_card.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/product_details/presentation/utils/scan_result_utils.dart';

/// Detail view for one recommended swap with a one-tap journal log action.
class SwapDetailScreen extends StatelessWidget {
  const SwapDetailScreen({super.key, required this.swap});
  final ProductSwap swap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final imageUrl = (swap.imageUrl != null && swap.imageUrl!.isNotEmpty) ? swap.imageUrl! : getDynamicImageUrl(swap.imageKeyword.isNotEmpty ? swap.imageKeyword : swap.title);

    return Scaffold(
      backgroundColor: scheme.cardBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const GutSliverAppBar(title: AppStrings.betterSwapsLabel, centerTitle: true),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashboardEntrance(
                    delay: 50,
                    child: BentoCard(
                      padding: const EdgeInsets.all(14),
                      borderRadius: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: CachedNetworkImage(imageUrl: imageUrl, height: 200.h, width: double.infinity, fit: BoxFit.cover),
                          ),
                          Gap.h12,
                          Text(
                            swap.tag.toUpperCase(),
                            style: context.captionBold.copyWith(color: scheme.success, fontSize: 10.sp, letterSpacing: 1.0),
                          ),
                          Gap.h4,
                          Text(
                            swap.title,
                            style: context.headingSm.copyWith(fontSize: 20.sp, fontWeight: FontWeight.w900),
                          ),
                          if (swap.subtitle.isNotEmpty) ...[
                            Gap.h6,
                            Text(
                              swap.subtitle,
                              style: context.bodySm.copyWith(color: scheme.textSecondary, height: 1.5, fontSize: 13.5.sp),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Gap.h12,
                  DashboardEntrance(
                    delay: 100,
                    child: GestureDetector(
                      onTap: () => logSwapToJournal(context, swap),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(color: scheme.success, borderRadius: BorderRadius.circular(14)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(AppIcons.plus, size: 16.sp, color: const Color(0xFFFFFFFF)),
                            Gap.w6,
                            Text(
                              'Log to journal',
                              style: context.labelBold.copyWith(color: const Color(0xFFFFFFFF), fontSize: 14.sp),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Gap.h8,
                  Center(
                    child: Text(
                      'Logged as a snack in your journal.',
                      style: context.caption.copyWith(color: scheme.textMuted, fontSize: 11.sp),
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
}
