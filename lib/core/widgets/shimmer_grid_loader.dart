import 'package:flutter/material.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:shimmer/shimmer.dart';

import '../constants/app_sizes.dart';

enum ShimmerVariant { grid, list, hero, card, recap, scanResult }

/// Reusable skeleton loader mirroring the real widget shapes across the app.
/// Prevents visual "pops" when transitioning from loading to loaded state.
class ShimmerGridLoader extends StatelessWidget {
  final int itemCount;
  final double? mainAxisExtent;
  final int crossAxisCount;
  final ShimmerVariant variant;

  const ShimmerGridLoader({super.key, this.itemCount = 4, this.mainAxisExtent, this.crossAxisCount = 2, this.variant = ShimmerVariant.grid});

  @override
  Widget build(BuildContext context) {
    final baseColor = context.appColorScheme.border.withValues(alpha: 0.2);
    final highlightColor = context.appColorScheme.border.withValues(alpha: 0.1);

    if (variant == ShimmerVariant.recap || variant == ShimmerVariant.scanResult) {
      return Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            children: variant == ShimmerVariant.recap ? _buildRecapSkeleton(context) : _buildScanResultSkeleton(context),
          ),
        ),
      );
    }

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12.0.w,
          mainAxisSpacing: 12.0.h,
          mainAxisExtent: mainAxisExtent ?? _getDefaultExtent(),
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          switch (variant) {
            case ShimmerVariant.hero:
              return _buildHeroSkeleton(context);
            case ShimmerVariant.card:
              return _buildCardSkeleton(context);
            case ShimmerVariant.list:
              return _buildListSkeleton(context);
            case ShimmerVariant.grid:
            default:
              return _buildGridSkeleton(context);
          }
        },
      ),
    );
  }

  double _getDefaultExtent() {
    switch (variant) {
      case ShimmerVariant.hero:
        return Responsive.h(240.0);
      case ShimmerVariant.card:
        return Responsive.h(160.0);
      case ShimmerVariant.list:
        return Responsive.h(84.0);
      case ShimmerVariant.grid:
      default:
        return Responsive.h(140.0);
    }
  }

  Widget _buildGridSkeleton(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.0.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32.0.w,
            height: 32.0.w,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
          const Spacer(),
          Container(
            width: 60.0.w,
            height: 12.0.h,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4.r)),
          ),
          Gap.h8,
          Container(
            width: double.infinity,
            height: 10.0.h,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4.r)),
          ),
        ],
      ),
    );
  }

  Widget _buildListSkeleton(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.0.h),
      padding: EdgeInsets.all(12.0.w),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.0.r)),
      child: Row(
        children: [
          Container(
            width: 52.0.w,
            height: 52.0.w,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.0.r)),
          ),
          Gap.w16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 140.0.w,
                  height: 14.0.h,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4.r)),
                ),
                Gap.h8,
                Container(
                  width: 100.0.w,
                  height: 10.0.h,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4.r)),
                ),
              ],
            ),
          ),
          Gap.w12,
          Container(
            width: 44.0.w,
            height: 44.0.w,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSkeleton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32.0.r)),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.0.w, 20.0.h, 20.0.w, 12.0.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 20.w, height: 20.w, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                    Gap.w12,
                    Container(width: 100.w, height: 10.h, color: Colors.white),
                  ],
                ),
                Container(width: 40.w, height: 18.h, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(100))),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                width: 160.0.w,
                height: 160.0.w,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              ),
            ),
          ),
          Container(
            height: 44.0.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32.0.r), bottomRight: Radius.circular(32.0.r)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSkeleton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32.0.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.0.w, 20.0.h, 20.0.w, 12.0.h),
            child: Row(
              children: [
                Container(
                  width: 20.0.w,
                  height: 20.0.w,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
                Gap.w12,
                Container(
                  width: 120.0.w,
                  height: 10.0.h,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4.r)),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: double.infinity, height: 12.h, color: Colors.white),
                Gap.h8,
                Container(width: 200.w, height: 12.h, color: Colors.white),
              ],
            ),
          ),
          const Spacer(),
          Container(
            height: 36.0.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32.0.r), bottomRight: Radius.circular(32.0.r)),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRecapSkeleton(BuildContext context) {
    return [
      Center(child: Container(width: 120.w, height: 24.h, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(100)))),
      Gap.h24,
      _buildHeroSkeleton(context),
      Gap.h32,
      _buildCardSkeleton(context),
      Gap.h32,
      _buildCardSkeleton(context),
      Gap.h32,
      _buildGridSkeleton(context),
    ];
  }

  List<Widget> _buildScanResultSkeleton(BuildContext context) {
    return [
      // Product Hero
      Container(
        height: 140.h,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24.r)),
      ),
      Gap.h32,
      // Impact Section
      _buildCardSkeleton(context),
      Gap.h32,
      // Nutrient Section
      _buildCardSkeleton(context),
      Gap.h32,
      // Cautions Section
      _buildCardSkeleton(context),
    ];
  }
}
