import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/models/historical_scan.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/widgets.dart';

import 'scan_history_tile.dart';

class HistorySection extends StatelessWidget {
  final String title;
  final List<HistoricalScan> items;

  const HistorySection({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return GutSection(
      title: title,
      topPadding: 8.0.h,
      children: items.map((item) {
        return ScanHistoryTile(
          scanResult: item.data,
          time: item.time,
          userImageUrl: item.userImageUrl,
          onTap: () {
            final tag = 'scan_image_${item.data.barcode ?? item.data.productName}_${item.time.millisecondsSinceEpoch}';
            final resultWithImage = item.data.copyWith(userImageUrl: item.userImageUrl);
            context.push('/scan-result', extra: {'scanData': resultWithImage.toMap(), 'heroTag': tag});
          },
        );
      }).toList(),
    );
  }
}
