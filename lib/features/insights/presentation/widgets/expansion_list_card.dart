import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/image_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ExpansionListCard extends StatefulWidget {
  const ExpansionListCard({super.key, required this.title, required this.items, required this.color, this.onViewAll, this.actionIcon = AppIcons.plus, this.viewAllText});

  final String title;
  final List<ExpansionListItemData> items;
  final Color color;
  final VoidCallback? onViewAll;
  final IconData actionIcon;
  final String? viewAllText;

  @override
  State<ExpansionListCard> createState() => _ExpansionListCardState();
}

class _ExpansionListCardState extends State<ExpansionListCard> {
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayItems = widget.items.isEmpty ? [const ExpansionListItemData(title: 'Stay Consistent', subtitle: 'Keep logging your meals for more insights.', emoji: '📊')] : widget.items;

    return Container(
      decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(20.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Inner Card
          Container(
            margin: EdgeInsets.all(4.w),
            decoration: BoxDecoration(color: isDark ? AppPalette.darkCard : Colors.white, borderRadius: BorderRadius.circular(16.r)),
            padding: EdgeInsets.fromLTRB(10.w, 12.h, 10.w, 10.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.bodyBold.copyWith(color: isDark ? scheme.textPrimary : AppPalette.black, fontSize: 13.sp, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                      ),
                    ),
                  ],
                ),
                Gap.h12,
                // PageView for Items
                SizedBox(
                  height: 150.h,
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: displayItems.length,
                    itemBuilder: (context, index) {
                      final item = displayItems[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Food Image area
                          Container(
                            height: 100.h,
                            width: double.infinity,
                            decoration: BoxDecoration(color: widget.color.withOpacity(isDark ? 0.15 : 0.08), borderRadius: BorderRadius.circular(12.r)),
                            clipBehavior: Clip.antiAlias,
                            child: CachedNetworkImage(
                              imageUrl: getDynamicImageUrl(item.title),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: Text(item.emoji, style: TextStyle(fontSize: 44.sp)),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Text(item.emoji, style: TextStyle(fontSize: 44.sp)),
                              ),
                            ),
                          ),
                          Gap.h12,
                          Text(
                            item.title.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.bodyBold.copyWith(color: isDark ? scheme.textPrimary : AppPalette.black, fontSize: 12.sp, fontWeight: FontWeight.w900),
                          ),
                          Gap.h2,
                          Text(
                            item.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.caption.copyWith(color: isDark ? scheme.textMuted : AppPalette.black.withOpacity(0.5), fontSize: 10.sp, height: 1.2, fontWeight: FontWeight.w500),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Scroll Indicator Area
          Padding(
            padding: EdgeInsets.symmetric(vertical: 5.h),
            child: Center(
              child: SmoothPageIndicator(
                controller: _controller,
                count: displayItems.length,
                effect: WormEffect(dotHeight: 4, dotWidth: 4, spacing: 4, dotColor: Colors.white.withOpacity(0.3), activeDotColor: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExpansionListItemData {
  const ExpansionListItemData({required this.title, required this.subtitle, required this.emoji});
  final String title;
  final String subtitle;
  final String emoji;
}
