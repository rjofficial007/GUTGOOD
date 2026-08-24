import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/historical_scan.dart';
import 'package:gutgood/core/models/route_arguments.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/history/presentation/widgets/scan_history_tile.dart';

class HistorySection extends StatelessWidget {
  const HistorySection({super.key, required this.title, required this.items});
  final String title;
  final List<HistoricalScan> items;

  @override
  Widget build(BuildContext context) => GutSection(
    title: title,
    topPadding: AppSizes.p8,
    children: items
        .map(
          (item) => ScanHistoryTile(
            scanResult: item.data,
            createdAt: item.createdAt,
            userImageUrl: item.userImageUrl,
            onTap: () {
              final tag = 'scan_image_${item.data.barcode ?? item.data.productName}_${item.createdAt.millisecondsSinceEpoch}';
              final resultWithImage = item.data.copyWith(userImageUrl: item.userImageUrl);
              unawaited(
                context.push(
                  AppRoutes.scanResult,
                  extra: ScanResultArgs(scanData: resultWithImage, heroTag: tag),
                ),
              );
            },
          ),
        )
        .toList(),
  );
}
