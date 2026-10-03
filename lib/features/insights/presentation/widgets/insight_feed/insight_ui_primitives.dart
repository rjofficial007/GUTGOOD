part of 'insight_ui_kit.dart';

/// Insight image, badge, and card primitives.

/// Shared primitives for the Insights design language.
///
/// These widgets map directly to the image, badge, pattern, and card surfaces
/// used by the active Insights feed.
abstract final class InsightUiKit {
  /// Food-image resolution chain, shared by every Insights tile: a scan/user image
  /// wins, otherwise the app-wide [getDynamicImageUrl] keyword lookup.
  static String foodImageUrl(String name, {String? userImageUrl, String? imageUrl}) {
    if (userImageUrl != null && userImageUrl.isNotEmpty) return userImageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty && !imageUrl.contains('unsplash.com')) return imageUrl;
    return getDynamicImageUrl(name);
  }

  /// Insights card shadow: `0 1px 2px rgba(23,23,27,.04)`.
  static List<BoxShadow> shadow(BuildContext context) => [BoxShadow(color: const Color(0xFF17171B).withValues(alpha: 0.04), blurRadius: 2.w, offset: Offset(0, 1.w))];

  static TextStyle text(BuildContext context, {double? size, FontWeight? weight, Color? color, double? height, double? letterSpacing}) => TextStyle(
    fontFamily: InsightTheme.fontFamily,
    fontSize: size?.sp,
    fontWeight: weight ?? FontWeight.w400,
    color: color ?? context.insightTheme.textPrimary,
    height: height ?? 1.35,
    letterSpacing: letterSpacing,
  );
}

/// Tone for the Insights badges, images, and pattern pills.
enum InsightTone { success, error, warning, neutral, purple }

/// `.badge` — soft wash, leading dot, 9px uppercase-ish label.
class InsightBadge extends StatelessWidget {
  const InsightBadge(this.label, {super.key, this.tone = InsightTone.neutral, this.withDot = true, this.size = 9.0});

  final String label;
  final InsightTone tone;
  final bool withDot;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.insightTheme;
    final (fg, bg) = switch (tone) {
      InsightTone.success => (t.success, t.successSoft),
      InsightTone.error => (t.error, t.errorSoft),
      InsightTone.warning => (t.warning, t.warningSoft),
      InsightTone.purple => (t.purple, t.purplePastel.withValues(alpha: 0.18)),
      InsightTone.neutral => (t.textPrimary, t.surfaceSubtle),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.w),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(InsightTheme.radiusPill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (withDot) ...[
            Container(
              width: 5.w,
              height: 5.w,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            Gap.w4,
          ],
          Text(
            label,
            style: InsightUiKit.text(context, size: size, weight: FontWeight.w700, color: fg, height: 1),
          ),
        ],
      ),
    );
  }
}

/// `.pill` — hairline-bordered label chip ("↗︎ Improving", "Pattern").

/// Clipped food image used across the Insights tiles (log rows, pattern pills,
/// food grids, detail heroes).
///
/// Resolution: [userImageUrl] → [imageUrl] → `getDynamicImageUrl(name)` (the
/// app-wide image utils). Renders a shimmer placeholder while loading and an
/// [emoji] fallback on error — per the asset-refactoring
/// spec, emoji indicators become real food imagery with graceful fallbacks.
class InsightFoodImage extends StatelessWidget {
  const InsightFoodImage({super.key, required this.name, this.userImageUrl, this.imageUrl, this.emoji, this.size = 32, this.circle = true, this.tone = InsightTone.neutral});

  final String name;
  final String? userImageUrl;
  final String? imageUrl;

  /// Last-resort error fallback (legacy docs store one); null renders the
  /// app-standard image glyph.
  final String? emoji;

  /// Logical (unscaled) diameter/edge.
  final double size;

  /// Circle for tiles/chips, rounded-square for grid cells.
  final bool circle;
  final InsightTone tone;

  @override
  Widget build(BuildContext context) {
    final t = context.insightTheme;
    final radius = circle ? size / 2 : size * 0.28;
    final bg = switch (tone) {
      InsightTone.success => t.successSoft,
      InsightTone.error => t.errorSoft,
      InsightTone.warning => t.warningSoft,
      InsightTone.purple => t.purplePastel.withValues(alpha: 0.18),
      InsightTone.neutral => t.surfaceSubtle,
    };
    final url = InsightUiKit.foodImageUrl(name, userImageUrl: userImageUrl, imageUrl: imageUrl);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius.w),
      child: SizedBox(
        width: size.w,
        height: size.w,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          width: size.w,
          height: size.w,
          placeholder: (_, _) => ColoredBox(
            color: bg,
            child: Shimmer.fromColors(
              baseColor: t.border.withValues(alpha: 0.4),
              highlightColor: t.card,
              child: DecoratedBox(
                decoration: BoxDecoration(color: t.border.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(radius.w)),
              ),
            ),
          ),
          errorWidget: (_, _, _) => ColoredBox(
            color: bg,
            child: Center(
              child: (emoji != null && emoji!.isNotEmpty)
                  ? Text(emoji!, style: TextStyle(fontSize: (size * 0.45).sp, height: 1))
                  : Icon(Icons.image_outlined, size: size.w * 0.5, color: t.textTertiary),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.card` — the white hairline surface every section sits on.
class InsightCard extends StatelessWidget {
  const InsightCard({super.key, required this.child, this.onTap, this.padding, this.radius = InsightTheme.radiusCard, this.background, this.borderColor});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? background;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final t = context.insightTheme;
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: background ?? t.card,
        borderRadius: BorderRadius.circular(radius.w),
        border: Border.all(color: borderColor ?? t.borderSubtle),
        boxShadow: InsightUiKit.shadow(context),
      ),
      child: Padding(padding: padding ?? EdgeInsets.all(14.w), child: child),
    );
    if (onTap == null) return card;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(radius.w), child: card),
    );
  }
}


