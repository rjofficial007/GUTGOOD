import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:shimmer/shimmer.dart';

enum ShimmerVariant { grid, list, hero, card, recap, scanResult }

/// Reusable skeleton loader mirroring the real widget shapes across the app.
/// Prevents visual "pops" when transitioning from loading to loaded state.
class ShimmerGridLoader extends StatelessWidget {
  const ShimmerGridLoader({super.key, this.itemCount = 4, this.mainAxisExtent, this.crossAxisCount = 2, this.variant = ShimmerVariant.grid});
  final int itemCount;
  final double? mainAxisExtent;
  final int crossAxisCount;
  final ShimmerVariant variant;

  @override
  Widget build(BuildContext context) {
    final baseColor = AppPalette.shimmerBase(context);
    final highlightColor = AppPalette.shimmerHighlight(context);

    if (variant == ShimmerVariant.recap || variant == ShimmerVariant.scanResult) {
      return Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(mainAxisSize: MainAxisSize.min, children: variant == ShimmerVariant.recap ? _buildRecapSkeleton(context) : _buildScanResultSkeleton(context)),
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

  Widget _buildGridSkeleton(BuildContext context) => Container(
    padding: EdgeInsets.all(AppSizes.p16),
    decoration: BoxDecoration(color: AppPalette.white, borderRadius: BorderRadius.circular(AppSizes.r28)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AppSizes.p32,
          height: AppSizes.p32,
          decoration: const BoxDecoration(color: AppPalette.white, shape: BoxShape.circle),
        ),
        Gap.h32,
        Container(
          width: 60.0.w,
          height: 12.0.h,
          decoration: BoxDecoration(color: AppPalette.white, borderRadius: BorderRadius.circular(AppSizes.r4)),
        ),
        Gap.h8,
        Container(
          width: double.infinity,
          height: 10.0.h,
          decoration: BoxDecoration(color: AppPalette.white, borderRadius: BorderRadius.circular(AppSizes.r4)),
        ),
      ],
    ),
  );

  Widget _buildListSkeleton(BuildContext context) => Container(
    margin: EdgeInsets.only(bottom: AppSizes.p12),
    padding: EdgeInsets.all(AppSizes.p12),
    decoration: BoxDecoration(color: AppPalette.white, borderRadius: BorderRadius.circular(AppSizes.r20)),
    child: Row(
      children: [
        Container(
          width: AppSizes.p56 - AppSizes.p4,
          height: AppSizes.p56 - AppSizes.p4,
          decoration: BoxDecoration(color: AppPalette.white, borderRadius: BorderRadius.circular(AppSizes.r12)),
        ),
        Gap.w16,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: AppSizes.w140,
                height: 14.0.h,
                decoration: BoxDecoration(color: AppPalette.white, borderRadius: BorderRadius.circular(AppSizes.r4)),
              ),
              Gap.h8,
              Container(
                width: 100.0.w,
                height: 10.0.h,
                decoration: BoxDecoration(color: AppPalette.white, borderRadius: BorderRadius.circular(AppSizes.r4)),
              ),
            ],
          ),
        ),
        Gap.w12,
        Container(
          width: AppSizes.p44,
          height: AppSizes.p44,
          decoration: const BoxDecoration(color: AppPalette.white, shape: BoxShape.circle),
        ),
      ],
    ),
  );

  Widget _buildHeroSkeleton(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: AppPalette.white, borderRadius: BorderRadius.circular(AppSizes.r32)),
    child: Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(AppSizes.p20, AppSizes.p20, AppSizes.p20, AppSizes.p12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: AppSizes.icon20,
                    height: AppSizes.icon20,
                    decoration: const BoxDecoration(color: AppPalette.white, shape: BoxShape.circle),
                  ),
                  Gap.w12,
                  Container(width: 100.0.w, height: 10.0.h, color: AppPalette.white),
                ],
              ),
              Container(
                width: AppSizes.icon40,
                height: 18.h,
                decoration: BoxDecoration(color: AppPalette.white, borderRadius: BorderRadius.circular(AppSizes.r100)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Container(
              width: AppSizes.p120 + AppSizes.p40,
              height: AppSizes.p120 + AppSizes.p40,
              decoration: const BoxDecoration(color: AppPalette.white, shape: BoxShape.circle),
            ),
          ),
        ),
        Container(
          height: AppSizes.p44,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppPalette.white.withAlpha(127),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(AppSizes.r32), bottomRight: Radius.circular(AppSizes.r32)),
          ),
        ),
      ],
    ),
  );

  Widget _buildCardSkeleton(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: AppPalette.white, borderRadius: BorderRadius.circular(AppSizes.r32)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(AppSizes.p20, AppSizes.p20, AppSizes.p20, AppSizes.p12),
          child: Row(
            children: [
              Container(
                width: AppSizes.icon20,
                height: AppSizes.icon20,
                decoration: const BoxDecoration(color: AppPalette.white, shape: BoxShape.circle),
              ),
              Gap.w12,
              Container(
                width: AppSizes.p120,
                height: 10.0.h,
                decoration: BoxDecoration(color: AppPalette.white, borderRadius: BorderRadius.circular(AppSizes.r4)),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.p20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: double.infinity, height: 12.h, color: AppPalette.white),
              Gap.h8,
              Container(width: 200.w, height: 12.h, color: AppPalette.white),
            ],
          ),
        ),
        Gap.h24,
        Container(
          height: AppSizes.p36,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppPalette.white.withAlpha(127),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(AppSizes.r32), bottomRight: Radius.circular(AppSizes.r32)),
          ),
        ),
      ],
    ),
  );

  List<Widget> _buildRecapSkeleton(BuildContext context) => [
    Center(
      child: Container(
        width: AppSizes.p120,
        height: AppSizes.p24,
        decoration: BoxDecoration(color: AppPalette.white, borderRadius: BorderRadius.circular(AppSizes.r100)),
      ),
    ),
    Gap.h24,
    _buildHeroSkeleton(context),
    Gap.h32,
    _buildCardSkeleton(context),
    Gap.h32,
    _buildCardSkeleton(context),
    Gap.h32,
    _buildGridSkeleton(context),
  ];

  List<Widget> _buildScanResultSkeleton(BuildContext context) => [
    // Product Hero
    Container(
      height: 140.h,
      decoration: BoxDecoration(color: AppPalette.white, borderRadius: BorderRadius.circular(AppSizes.r24)),
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
