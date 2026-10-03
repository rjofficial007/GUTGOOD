part of 'insight_bento_feed.dart';

/// Insight highlight presentation component.

class InsightHighlightCard extends StatelessWidget {
  const InsightHighlightCard({
    super.key,
    required this.tag,
    this.emoji,
    this.icon,
    this.imageUrl,
    this.userImageUrl,
    this.assetImage,
    required this.title,
    this.body,
    this.meta,
    this.metaChip = false,
    this.bigTitle = false,
    this.footLeft,
    required this.accentColor,
    required this.backgroundColor,
    this.chartPainter,
    this.chart,
    this.onTap,
    this.actionIcon = AppIcons.chevronRight,
  });

  /// Head-row card name ("To watch", "Top win", "Driver 1"…).
  final String tag;

  /// Tile content: either an emoji, Lucide icon, or asset image.
  final String? emoji;
  final IconData? icon;
  final String? imageUrl;
  final String? userImageUrl;
  final String? assetImage;

  final String title;

  /// Muted paragraph under the title.
  final String? body;

  /// Right-aligned accent meta in the head row ("+18%", "5 of 7 days").
  /// Renders as a small chip when [metaChip] is set ("LOCKED").
  final String? meta;
  final bool metaChip;

  /// Feed-scale title: 15px w700 on a single line (the gallery feed cards).
  /// The default is the recap-scale 13.5px w800 over two lines.
  final bool bigTitle;

  final String? footLeft;
  final Color accentColor;
  final Color backgroundColor;

  /// Chart slot: a prebuilt [chart] widget wins over [chartPainter].
  final CustomPainter? chartPainter;
  final Widget? chart;

  final VoidCallback? onTap;

  /// Trailing footer action; only rendered when [onTap] is set.
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) {
    final chartSlot =
        chart ??
        (chartPainter == null
            ? null
            : SizedBox(
                height: 38.w,
                width: double.infinity,
                child: CustomPaint(size: Size.infinite, painter: chartPainter!),
              ));
    final tappable = onTap != null;
    final displayImg = userImageUrl ?? imageUrl;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(color: PatternSurface.tone(context, accentColor, backgroundColor), borderRadius: BorderRadius.circular(18.w), boxShadow: PatternSurface.shadow(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(10.w)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.w),
                    child: (assetImage != null && assetImage!.isNotEmpty)
                        ? Image.asset(
                            assetImage!,
                            width: 32.w,
                            height: 32.w,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Center(
                              child: emoji != null ? Text(emoji!, style: TextStyle(fontSize: 16.sp, height: 1)) : Icon(icon ?? AppIcons.sparkles, size: 16.w, color: Colors.white),
                            ),
                          )
                        : (displayImg != null && displayImg.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: displayImg,
                            width: 32.w,
                            height: 32.w,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => Center(
                              child: emoji != null ? Text(emoji!, style: TextStyle(fontSize: 16.sp, height: 1)) : Icon(icon ?? AppIcons.sparkles, size: 16.w, color: Colors.white),
                            ),
                          )
                        : Center(
                            child: emoji != null ? Text(emoji!, style: TextStyle(fontSize: 16.sp, height: 1)) : Icon(icon ?? AppIcons.sparkles, size: 16.w, color: Colors.white),
                          ),
                  ),
                ),
                Gap.w8,
                Expanded(
                  child: Text(
                    tag.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 13.sp, fontWeight: FontWeight.w800, color: PatternSurface.ink(context)),
                  ),
                ),
                if (meta != null) ...[
                  Gap.w6,
                  if (metaChip)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.5.w),
                      decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6.w)),
                      child: Text(
                        meta!.toUpperCase(),
                        style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: accentColor),
                      ),
                    )
                  else
                    Text(
                      meta!,
                      maxLines: 1,
                      style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: accentColor),
                    ),
                ],
              ],
            ),
            Gap.h10,
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: InsightBentoTheme.fontFamily,
                fontSize: bigTitle ? 15.sp : 13.5.sp,
                fontWeight: bigTitle ? FontWeight.w700 : FontWeight.w800,
                height: bigTitle ? 1.2 : 1.3,
                letterSpacing: -0.2,
                color: PatternSurface.ink(context),
              ),
            ),
            if ((body ?? '').isNotEmpty) ...[
              Gap.h4,
              Text(
                body!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.5.sp, color: PatternSurface.muted(context), height: 1.4),
              ),
            ],
            Gap.h10,
            if (chartSlot != null) ...[chartSlot, Gap.h10],
            Gap.h10,
            Row(
              children: [
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                ),
                Gap.w6,
                Expanded(
                  child: Text(
                    footLeft ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w600, color: PatternSurface.foot(context)),
                  ),
                ),
                if (tappable && actionIcon != null) Icon(actionIcon, size: 15, color: accentColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

