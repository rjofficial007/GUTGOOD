import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/utils/date_formatter.dart';
import 'package:gutgood/core/widgets/gut_score_list_tile.dart';
import 'package:shimmer/shimmer.dart';

class ScanHistoryTile extends StatelessWidget {
  const ScanHistoryTile({super.key, required this.scanResult, this.createdAt, this.userImageUrl, required this.onTap});
  final ScanResult scanResult;
  final DateTime? createdAt;
  final String? userImageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayImageUrl = scanResult.displayImageUrl ?? (scanResult.isBarcodeScan ? null : userImageUrl);

    final leadingWidget = Container(
      width: AppSizes.w52,
      height: AppSizes.w52,
      decoration: BoxDecoration(color: context.appColorScheme.cardBackground, borderRadius: BorderRadius.circular(AppSizes.r12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.r12),
        child: displayImageUrl != null
            ? Hero(
                tag: 'scan_image_${scanResult.barcode ?? scanResult.productName}_${createdAt?.millisecondsSinceEpoch}',
                child: CachedNetworkImage(
                  imageUrl: displayImageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: AppPalette.shimmerBase(context),
                    highlightColor: AppPalette.shimmerHighlight(context),
                    child: Container(color: AppPalette.white),
                  ),
                  errorWidget: (_, _, _) => Icon(AppIcons.package, size: AppSizes.icon24, color: context.appColorScheme.textMuted),
                ),
              )
            : Icon(AppIcons.package, size: AppSizes.icon24, color: context.appColorScheme.textMuted),
      ),
    );

    return GutScoreListTile(
      leading: leadingWidget,
      title: scanResult.productName,
      subtitle: '${scanResult.brand} • ${createdAt != null ? DateFormatter.formatTime(createdAt!) : AppStrings.labelSavedItem}',
      score: scanResult.score,
      onTap: onTap,
    );
  }
}
