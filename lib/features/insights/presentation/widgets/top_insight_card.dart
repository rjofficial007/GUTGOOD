import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_assets.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/insight_theme.dart';
import 'package:gutgood/core/utils/insight_values.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TopInsightCard extends StatelessWidget {
  const TopInsightCard({super.key, required this.topInsight, this.onTap, this.observationCount, this.showAction = true});

  final InsightSummary topInsight;
  final VoidCallback? onTap;
  final int? observationCount;
  final bool showAction;

  @override
  Widget build(BuildContext context) {
    final titleText = InsightValues.text(topInsight.title, fallback: 'Your food and symptom snapshot');
    final descriptionText = InsightValues.text(topInsight.description, fallback: '');
    final reportedCount = observationCount ?? topInsight.frequency ?? 1;
    final count = reportedCount < 1 ? 1 : reportedCount;
    final isEarlyObservation = count <= 1;
    final statusText = isEarlyObservation ? 'Early observation · $count observation' : 'Top insight · $count observations';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22.w),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF5F57D9), Color(0xFF8179E9), Color(0xFF9A93F3)]),
        boxShadow: [BoxShadow(color: const Color(0xFF5F57D9).withValues(alpha: 0.16), blurRadius: 14.w, offset: Offset(0, 6.w))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: showAction ? (onTap ?? () => context.push(AppRoutes.smartInsightDetail, extra: topInsight)) : null,
          borderRadius: BorderRadius.circular(22.w),
          child: Padding(
            padding: EdgeInsets.fromLTRB(18.w, 16.w, 14.w, 16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        statusText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.88), letterSpacing: 0.7),
                      ),
                      Gap.h2,
                      Gap.h10,
                      Text(
                        titleText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 17.sp, fontWeight: FontWeight.w800, color: Colors.white, height: 1.12, letterSpacing: -0.35),
                      ),
                      if (descriptionText.isNotEmpty) ...[
                        Gap.h6,
                        Text(
                          descriptionText,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.9), height: 1.3),
                        ),
                      ],
                      if (showAction) ...[
                        Gap.h12,
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 28.w,
                              height: 28.w,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: Icon(Icons.north_east_rounded, size: 15.w, color: const Color(0xFF5F57D9)),
                            ),
                            Gap.w8,
                            Text('View observation', style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.1)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Gap.w8,
                SizedBox(
                  width: 76.w,
                  height: 76.w,
                  child: Image.asset(
                    AppAssets.appIconBg,
                    color: Colors.white,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Container(
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Icon(LucideIcons.sparkles, size: 34.w, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
