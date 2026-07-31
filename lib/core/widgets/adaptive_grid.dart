import 'package:flutter/material.dart';
import 'package:gutgood/core/utils/responsive.dart';

class AdaptiveGrid extends StatelessWidget {
  final List<Widget> items;
  final double? mainAxisExtent;

  const AdaptiveGrid({super.key, required this.items, this.mainAxisExtent});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    if (items.length == 1) return items.first;

    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12.0.w, mainAxisSpacing: 12.0.h, mainAxisExtent: mainAxisExtent ?? Responsive.h(140.0)),
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }
}
