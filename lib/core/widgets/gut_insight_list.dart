import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';

class GutInsightList extends StatelessWidget {
  final List<Widget> items;

  const GutInsightList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: AppSizes.p12),
              child: item,
            ),
          )
          .toList(),
    );
  }
}

class GutInsightGrid extends StatelessWidget {
  final List<Widget> items;

  const GutInsightGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: AppSizes.p12, mainAxisSpacing: AppSizes.p12, childAspectRatio: 1.2),
      itemBuilder: (context, index) => items[index],
    );
  }
}
