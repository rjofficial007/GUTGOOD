import 'package:flutter/material.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:shimmer/shimmer.dart';

/// A standardized shimmer loader component used across the GutGood app.
class GutShimmerSkeleton extends StatelessWidget {
  const GutShimmerSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12.0,
    this.margin,
  });

  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final baseColor = AppPalette.shimmerBase(context);
    final highlightColor = AppPalette.shimmerHighlight(context);

    return Container(
      margin: margin,
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}
