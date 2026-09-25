
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/utils/image_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:shimmer/shimmer.dart';

/// Shared primitives for the v2 Insights language.
///
/// Every widget maps 1:1 onto a CSS component in `uploads/v2.html`
/// (`.badge`, `.pill`, `.card`, `.ring`, `.stat`, `.food-item`, `.meal-row`,
/// `.pattern-pill`, `.rec-card`, `.why`, `.chart`, `.dot-grid`) so reviewing
/// Dart against the mock is a visual diff, not an archaeology dig.
abstract final class V2Kit {
  /// Food-image resolution chain, shared by every v2 tile: a scan/user image
  /// wins, otherwise the app-wide [getDynamicImageUrl] keyword lookup.
  static String foodImageUrl(String name, {String? userImageUrl, String? imageUrl}) {
    if (userImageUrl != null && userImageUrl.isNotEmpty) return userImageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty && !imageUrl.contains('unsplash.com')) return imageUrl;
    return getDynamicImageUrl(name);
  }

  /// v2's card shadow: `0 1px 2px rgba(23,23,27,.04)`.
  static List<BoxShadow> shadow(BuildContext context) => [BoxShadow(color: const Color(0xFF17171B).withValues(alpha: 0.04), blurRadius: 2.w, offset: Offset(0, 1.w))];

  static TextStyle text(BuildContext context, {double? size, FontWeight? weight, Color? color, double? height, double? letterSpacing}) => TextStyle(
    fontFamily: InsightV2Theme.fontFamily,
    fontSize: size?.sp,
    fontWeight: weight ?? FontWeight.w400,
    color: color ?? context.v2Theme.textPrimary,
    height: height ?? 1.35,
    letterSpacing: letterSpacing,
  );
}

/// Tone for [V2Badge], [V2IconCircle], [V2RecCard] and the why-list checks.
enum V2Tone { success, error, warning, neutral, purple }

/// `.badge` — soft wash, leading dot, 9px uppercase-ish label.
class V2Badge extends StatelessWidget {
  const V2Badge(this.label, {super.key, this.tone = V2Tone.neutral, this.withDot = true, this.size = 9.0});

  final String label;
  final V2Tone tone;
  final bool withDot;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.v2Theme;
    final (fg, bg) = switch (tone) {
      V2Tone.success => (t.success, t.successSoft),
      V2Tone.error => (t.error, t.errorSoft),
      V2Tone.warning => (t.warning, t.warningSoft),
      V2Tone.purple => (t.purple, t.purplePastel.withValues(alpha: 0.18)),
      V2Tone.neutral => (t.textPrimary, t.surfaceSubtle),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.w),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(InsightV2Theme.radiusPill)),
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
            style: V2Kit.text(context, size: size, weight: FontWeight.w700, color: fg, height: 1),
          ),
        ],
      ),
    );
  }
}

/// `.pill` — hairline-bordered label chip ("↗︎ Improving", "Pattern").
class V2Pill extends StatelessWidget {
  const V2Pill(this.label, {super.key, this.color, this.size = 10.0, this.weight = FontWeight.w600, this.background});

  final String label;
  final Color? color;
  final Color? background;
  final double size;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    final t = context.v2Theme;
    final fg = color ?? t.textSecondary;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.5.w),
      decoration: BoxDecoration(
        color: background ?? Colors.transparent,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(InsightV2Theme.radiusPill),
      ),
      child: Text(
        label,
        style: V2Kit.text(context, size: size, weight: weight, color: fg, height: 1),
      ),
    );
  }
}

/// Clipped food image used across the v2 tiles (log rows, pattern pills,
/// food grids, detail heroes).
///
/// Resolution: [userImageUrl] → [imageUrl] → `getDynamicImageUrl(name)` (the
/// app-wide image utils). Renders a shimmer placeholder while loading and an
/// [emoji]/`AppIcons.image` fallback on error — per the asset-refactoring
/// spec, emoji indicators become real food imagery with graceful fallbacks.
class V2FoodImage extends StatelessWidget {
  const V2FoodImage({super.key, required this.name, this.userImageUrl, this.imageUrl, this.emoji, this.size = 32, this.circle = true, this.tone = V2Tone.neutral});

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
  final V2Tone tone;

  @override
  Widget build(BuildContext context) {
    final t = context.v2Theme;
    final radius = circle ? size / 2 : size * 0.28;
    final bg = V2RecCard.toneSoft(t, tone);
    final url = V2Kit.foodImageUrl(name, userImageUrl: userImageUrl, imageUrl: imageUrl);
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

/// `.icon-circle` — tinted circle tile for glyphs and emoji.
class V2IconCircle extends StatelessWidget {
  const V2IconCircle({super.key, this.glyph, this.icon, this.emoji, this.imageUrl, this.tone = V2Tone.success, this.size = 36});

  final IconData? icon;
  final String? glyph;
  final String? emoji;
  final String? imageUrl;
  final V2Tone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.v2Theme;
    final (fg, bg) = switch (tone) {
      V2Tone.success => (t.success, t.successSoft),
      V2Tone.error => (t.error, t.errorSoft),
      V2Tone.warning => (t.warning, t.warningSoft),
      V2Tone.purple => (t.purple, t.purplePastel.withValues(alpha: 0.18)),
      V2Tone.neutral => (t.textPrimary, t.surfaceSubtle),
    };
    final child = imageUrl != null && imageUrl!.isNotEmpty
        ? ClipRRect(
            borderRadius: BorderRadius.circular(size),
            child: CachedNetworkImage(imageUrl: imageUrl!, width: size.w, height: size.w, fit: BoxFit.cover, errorWidget: (_, _, _) => _glyph(context, fg)),
          )
        : _glyph(context, fg);
    return Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _glyph(BuildContext context, Color fg) => emoji != null && emoji!.isNotEmpty
      ? Text(emoji!, style: TextStyle(fontSize: (size * 0.45).sp, height: 1))
      : icon != null
      ? Icon(icon, size: size.w * 0.5, color: fg)
      : Text(
          glyph ?? '✓',
          style: V2Kit.text(context, size: size * 0.45, weight: FontWeight.w700, color: fg, height: 1),
        );
}

/// `.card` — the white hairline surface every section sits on.
class V2Card extends StatelessWidget {
  const V2Card({super.key, required this.child, this.onTap, this.padding, this.radius = InsightV2Theme.radiusCard, this.background, this.borderColor});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? background;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final t = context.v2Theme;
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: background ?? t.card,
        borderRadius: BorderRadius.circular(radius.w),
        border: Border.all(color: borderColor ?? t.borderSubtle),
        boxShadow: V2Kit.shadow(context),
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

/// `.stat` — the bordered key/value tile; `.stats-row` is `Row(children: stats)`.
class V2Stat extends StatelessWidget {
  const V2Stat({super.key, required this.label, required this.value, this.sub, this.valueColor, this.labelWidget, this.flex = 1});

  final String label;
  final String value;
  final String? sub;
  final Color? valueColor;
  final Widget? labelWidget;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final t = context.v2Theme;
    return Expanded(
      flex: flex,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.w),
        decoration: BoxDecoration(
          color: t.card,
          border: Border.all(color: t.borderSubtle),
          borderRadius: BorderRadius.circular(InsightV2Theme.radiusChip),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            labelWidget ??
                Text(
                  label,
                  style: V2Kit.text(context, size: 9.5, weight: FontWeight.w600, color: t.textTertiary, height: 1),
                ),
            Gap.h4,
            Text(
              value,
              style: V2Kit.text(context, size: 12.5, weight: FontWeight.w700, color: valueColor ?? t.textPrimary, height: 1.1),
            ),
            if (sub != null && sub!.isNotEmpty) ...[Gap.h2, Text(sub!, style: V2Kit.text(context, size: 9.5, color: t.textTertiary, height: 1.2))],
          ],
        ),
      ),
    );
  }
}

/// Section micro-label ("Key foods driving this", "Recent timeline").
class V2SectionLabel extends StatelessWidget {
  const V2SectionLabel(this.label, {super.key, this.color});

  /// "Smart swap • 73% less risk" — bold lead + muted tail.
  factory V2SectionLabel.rich(String lead, String tail) => V2SectionLabel(tail.isEmpty ? lead : '$lead • $tail');

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: V2Kit.text(context, size: 11, weight: FontWeight.w700, color: color ?? context.v2Theme.textPrimary),
  );
}

/// `.rec-card` — the recommendation strip with a leading icon tile
/// ("Keep it up — …", "Same crunch, better fiber. …").
class V2RecCard extends StatelessWidget {
  const V2RecCard({super.key, required this.richText, this.glyph = '✓', this.emoji, this.icon, this.tone = V2Tone.success, this.onTap, this.dark = false});

  /// Already-styled spans (bold lead + muted tail) built by the caller.
  final TextSpan richText;
  final String glyph;
  final String? emoji;
  final IconData? icon;
  final V2Tone tone;
  final VoidCallback? onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final t = context.v2Theme;
    final fg = dark ? t.card : toneColor(t, tone);
    return V2Card(
      radius: 15,
      onTap: onTap,
      padding: EdgeInsets.all(10.w),
      background: dark ? t.textPrimary : null,
      borderColor: dark ? Colors.transparent : t.borderSubtle,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 26.w,
            height: 26.w,
            decoration: BoxDecoration(
              color: dark ? t.overlayBarrier : toneSoft(t, tone),
              border: Border.all(color: dark ? Colors.transparent : t.borderSubtle),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: emoji != null && emoji!.isNotEmpty ? Text(emoji!, style: TextStyle(fontSize: 12.sp, height: 1)) : Icon(icon ?? Icons.check, size: 13.w, color: fg),
          ),
          Gap.w10,
          Expanded(child: Text.rich(richText)),
          if (onTap != null) Icon(Icons.chevron_right, size: 15.w, color: dark ? t.card : t.textTertiary),
        ],
      ),
    );
  }

  static Color toneColor(InsightV2Theme t, V2Tone tone) => switch (tone) {
    V2Tone.success => t.success,
    V2Tone.error => t.error,
    V2Tone.warning => t.warning,
    V2Tone.purple => t.purple,
    V2Tone.neutral => t.textPrimary,
  };

  static Color toneSoft(InsightV2Theme t, V2Tone tone) => switch (tone) {
    V2Tone.success => t.successSoft,
    V2Tone.error => t.errorSoft,
    V2Tone.warning => t.warningSoft,
    V2Tone.purple => t.purplePastel.withValues(alpha: 0.18),
    V2Tone.neutral => t.surfaceSubtle,
  };
}

/// `.meal-row` timeline — list of rows without card background or outer padding.
class V2Timeline extends StatelessWidget {
  const V2Timeline({super.key, required this.rows});

  final List<V2TimelineRow> rows;

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: rows);
}

class V2TimelineRow extends StatelessWidget {
  const V2TimelineRow({super.key, required this.title, this.subtitle, this.trailing, this.dotColor, this.dotMuted = false, this.imageName, this.imageUrl});

  final String title;
  final String? subtitle;
  final String? trailing;
  final Color? dotColor;
  final bool dotMuted;

  /// When set, renders a clipped food image (image-utils chain) instead of
  /// the bare dot — log tiles carry imagery per the asset spec.
  final String? imageName;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final t = context.v2Theme;
    final foodName = imageName ?? title;
    final url = V2Kit.foodImageUrl(foodName, imageUrl: imageUrl);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.w),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.w),
            child: CachedNetworkImage(
              imageUrl: url,
              width: 56.w,
              height: 56.w,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(color: t.surfaceSubtle, width: 56.w, height: 56.w),
              errorWidget: (_, _, _) => Container(
                width: 56.w,
                height: 56.w,
                color: t.surfaceSubtle,
                alignment: Alignment.center,
                child: Icon(Icons.restaurant, size: 24.w, color: t.textTertiary),
              ),
            ),
          ),
          Gap.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: V2Kit.text(context, size: 12, weight: FontWeight.w700),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  Gap.h4,
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.w),
                        decoration: BoxDecoration(color: t.errorSoft, borderRadius: BorderRadius.circular(4.w)),
                        child: Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: V2Kit.text(context, size: 9.5, weight: FontWeight.w600, color: t.error),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null && trailing!.isNotEmpty) ...[
            Gap.w8,
            Container(
              padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.w),
              decoration: BoxDecoration(color: dotMuted ? t.surfaceSubtle : Color.alphaBlend(t.error.withValues(alpha: 0.12), t.card), borderRadius: BorderRadius.circular(10.w)),
              child: Text(
                trailing!,
                style: V2Kit.text(context, size: 9.5, weight: FontWeight.w700, color: dotMuted ? t.textTertiary : t.error),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// `.pattern-pill` — tappable row: image/emoji, title + sub, chevron.
class V2PatternPill extends StatelessWidget {
  const V2PatternPill({super.key, required this.title, this.subtitle, this.badge, this.emoji, this.imageUrl, this.imageName, this.onTap});

  final String title;
  final String? subtitle;
  final String? badge;
  final String? emoji;
  final String? imageUrl;
  final VoidCallback? onTap;

  /// Clean food name for the image-utils lookup (the display [title] often
  /// carries suffixes like "• Trigger food" that would poison the keyword).
  final String? imageName;

  @override
  Widget build(BuildContext context) {
    final t = context.v2Theme;
    return V2Card(
      onTap: onTap,
      padding: EdgeInsets.all(10.w),
      radius: InsightV2Theme.radiusTile,
      background: t.cardSubtle,
      child: Row(
        children: [
          V2FoodImage(name: imageName ?? title, userImageUrl: imageUrl, emoji: emoji, size: 32, tone: V2Tone.neutral),
          Gap.w10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: V2Kit.text(context, size: 12, weight: FontWeight.w600),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  Gap.h2,
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: V2Kit.text(context, size: 11, color: t.textTertiary),
                  ),
                ],
                if (badge != null && badge!.isNotEmpty) ...[Gap.h4, V2Badge(badge!, tone: V2Tone.success, size: 8.5)],
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 16.w, color: t.textTertiary),
        ],
      ),
    );
  }
}

/// `.food-item` / `.food-grid` — square image tile + name + count.
class V2FoodGrid extends StatelessWidget {
  const V2FoodGrid({super.key, required this.items, this.onItemTap});

  final List<V2FoodItemData> items;
  final void Function(V2FoodItemData item)? onItemTap;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < items.length; i++) ...[if (i > 0) Gap.w8, V2FoodTile(data: items[i], onTap: onItemTap == null ? null : () => onItemTap!(items[i]))],
    ],
  );
}

class V2FoodItemData {
  const V2FoodItemData({required this.name, this.count, this.delta, this.emoji, this.imageUrl, this.userImageUrl, this.deltaColor});

  final String name;
  final String? count;
  final String? delta;

  /// Delta chip colour (e.g. success for "+3").
  final Color? deltaColor;
  final String? emoji;
  final String? imageUrl;
  final String? userImageUrl;
}

class V2FoodTile extends StatelessWidget {
  const V2FoodTile({super.key, required this.data, this.onTap});

  final V2FoodItemData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.v2Theme;
    final countText = [if (data.count != null && data.count!.isNotEmpty) data.count, if (data.delta != null && data.delta!.isNotEmpty) data.delta].join(' ');

    Widget tile = Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10.w),
          child: CachedNetworkImage(
            imageUrl: V2Kit.foodImageUrl(data.name, userImageUrl: data.userImageUrl, imageUrl: data.imageUrl),
            width: 56.w,
            height: 56.w,
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(color: t.surfaceSubtle, width: 56.w, height: 56.w),
            errorWidget: (_, _, _) => Container(
              width: 56.w,
              height: 56.w,
              color: t.surfaceSubtle,
              alignment: Alignment.center,
              child: Text(data.emoji ?? '🍽', style: TextStyle(fontSize: 24.sp)),
            ),
          ),
        ),
        Gap.h6,
        Text(
          data.name,
          style: V2Kit.text(context, size: 10, weight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        if (countText.isNotEmpty) ...[
          Gap.h2,
          Text(
            countText,
            style: V2Kit.text(context, size: 10, color: t.textTertiary, weight: FontWeight.w500),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );

    if (onTap != null) {
      tile = InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10.w), child: tile);
    }

    return tile;
  }
}

/// Smart swap — "Before → After" halves with a tinted target side.
class V2SwapRow extends StatelessWidget {
  const V2SwapRow({super.key, required this.before, required this.after, this.beforeEmoji, this.afterEmoji});

  final String before;
  final String after;
  final String? beforeEmoji;
  final String? afterEmoji;

  @override
  Widget build(BuildContext context) {
    final t = context.v2Theme;
    return Row(
      children: [
        // Left Side: BEFORE (Trigger)
        Expanded(
          child: _half(context, label: 'BEFORE', labelColor: t.error, name: before, emoji: beforeEmoji, backgroundColor: t.errorSoft, borderColor: t.error.withValues(alpha: 0.30), isAfter: false),
        ),

        // Center Directional Arrow
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              color: t.card,
              shape: BoxShape.circle,
              border: Border.all(color: t.borderSubtle),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            alignment: Alignment.center,
            child: Icon(Icons.arrow_forward_rounded, size: 14.w, color: t.textPrimary),
          ),
        ),

        // Right Side: AFTER (Swap)
        Expanded(
          child: _half(context, label: 'AFTER', labelColor: t.success, name: after, emoji: afterEmoji, backgroundColor: t.successSoft, borderColor: t.success.withValues(alpha: 0.35), isAfter: true),
        ),
      ],
    );
  }

  Widget _half(
    BuildContext context, {
    required String label,
    required Color labelColor,
    required String name,
    required Color backgroundColor,
    required Color borderColor,
    required bool isAfter,
    String? emoji,
  }) => Container(
    padding: EdgeInsets.all(10.w),
    decoration: BoxDecoration(
      color: backgroundColor,
      border: Border.all(color: borderColor),
      borderRadius: BorderRadius.circular(14.w),
    ),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10.w),
          child: V2FoodImage(name: name, emoji: emoji, size: 34, circle: false, tone: isAfter ? V2Tone.success : V2Tone.error),
        ),
        Gap.w10,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(isAfter ? '🌱 ' : '⚠️ ', style: TextStyle(fontSize: 8.sp)),
                  Text(
                    label,
                    style: V2Kit.text(context, size: 9.5, weight: FontWeight.w800, color: labelColor, letterSpacing: 0.5),
                  ),
                ],
              ),
              Gap.h2,
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: V2Kit.text(context, size: 11.5, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// `.why` checklist — tinted check tile + one-line reason.
class V2WhyList extends StatelessWidget {
  const V2WhyList({super.key, required this.points, this.tone = V2Tone.success});

  final List<String> points;
  final V2Tone tone;

  @override
  Widget build(BuildContext context) {
    final t = context.v2Theme;
    final color = V2RecCard.toneColor(t, tone);
    return Column(
      children: [
        for (final point in points)
          Padding(
            padding: EdgeInsets.only(bottom: 8.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 18.w,
                  height: 18.w,
                  decoration: BoxDecoration(color: V2RecCard.toneSoft(t, tone), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Icon(tone == V2Tone.error ? Icons.priority_high_rounded : Icons.check, size: 11.w, color: color),
                ),
                Gap.w8,
                Expanded(
                  child: Text(point, style: V2Kit.text(context, size: 11.5, color: t.textSecondary, height: 1.4)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// `.dot-grid` — pager dots for the top-insight carousel.
class V2DotPager extends StatelessWidget {
  const V2DotPager({super.key, required this.count, required this.active, this.onTap});

  final int count;
  final int active;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.v2Theme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          GestureDetector(
            onTap: onTap == null ? null : () => onTap!(i),
            child: Container(
              width: 6.w,
              height: 6.w,
              margin: EdgeInsets.symmetric(horizontal: 3.w),
              decoration: BoxDecoration(color: i == active ? t.textPrimary : t.border, shape: BoxShape.circle),
            ),
          ),
      ],
    );
  }
}

/// `.chart` — the 7-day line trend with soft fill and an end dot.
class V2TrendChart extends StatelessWidget {
  const V2TrendChart({super.key, required this.values, this.height = 58, this.color, this.endDot = true});
  final List<double> values;
  final double height;
  final Color? color;
  final bool endDot;

  @override
  Widget build(BuildContext context) {
    final valid = values.where((value) => value.isFinite && value >= 0 && value <= 100).toList();
    final t = context.v2Theme;
    return Semantics(
      label: valid.isEmpty ? 'No recorded scores' : 'Gut scores out of 100, in recording order: ${valid.map((value) => value.round()).join(', ')}',
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: valid.isEmpty
            ? Center(child: Text('No score history yet', style: TextStyle(color: t.textSecondary)))
            : CustomPaint(painter: _TrendPainter(color: color ?? t.success, gridColor: t.border, values: valid, endDot: endDot)),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({required this.color, required this.gridColor, required this.values, required this.endDot});
  final Color color;
  final Color gridColor;
  final List<double> values;
  final bool endDot;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.width <= 12 || size.height <= 12) return;
    const padding = 6.0;
    final width = size.width - padding * 2;
    final height = size.height - padding * 2;
    final grid = Paint()..color = gridColor..strokeWidth = 1;
    for (final fraction in [0.0, 0.5, 1.0]) {
      final y = padding + height * fraction;
      canvas.drawLine(Offset(padding, y), Offset(size.width - padding, y), grid);
    }
    final points = [for (var i = 0; i < values.length; i++) Offset(
      values.length == 1 ? size.width / 2 : padding + width * i / (values.length - 1),
      padding + height * (1 - values[i] / 100),
    )];
    if (points.length == 1) {
      canvas.drawCircle(points.single, 4, Paint()..color = color);
      return;
    }
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) { line.lineTo(point.dx, point.dy); }
    final fill = Path.from(line)..lineTo(points.last.dx, size.height - padding)..lineTo(points.first.dx, size.height - padding)..close();
    canvas.drawPath(fill, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withValues(alpha: .18), color.withValues(alpha: .01)]).createShader(Offset.zero & size));
    canvas.drawPath(line, Paint()..color = color..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    for (final point in points) { canvas.drawCircle(point, 2.5, Paint()..color = color); }
    if (endDot) canvas.drawCircle(points.last, 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TrendPainter old) => old.color != color || old.gridColor != gridColor || old.endDot != endDot || !listEquals(old.values, values);
}

/// The 5-segment streak bar under the hero's "Streak" stat.
class V2StreakTicks extends StatelessWidget {
  const V2StreakTicks({super.key, required this.filled, required this.total, this.color});

  final int filled;
  final int total;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.v2Theme;
    final c = color ?? t.success;
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) SizedBox(width: 3.w),
          Expanded(
            child: Container(
              height: 4.w,
              decoration: BoxDecoration(color: i < filled ? c : t.border, borderRadius: BorderRadius.circular(2.w)),
            ),
          ),
        ],
      ],
    );
  }
}

/// `.btn` — v2 button (filled ink or hairline outline), r12.
class V2Button extends StatelessWidget {
  const V2Button({super.key, required this.label, this.onTap, this.outline = false, this.expanded = true});

  final String label;
  final VoidCallback? onTap;
  final bool outline;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final t = context.v2Theme;
    final btn = Material(
      color: outline ? Colors.transparent : t.textPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(InsightV2Theme.radiusButton.w),
        side: outline ? BorderSide(color: t.border) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(InsightV2Theme.radiusButton.w),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.w),
          child: Center(
            child: Text(
              label,
              style: V2Kit.text(context, size: 12.5, weight: FontWeight.w700, color: outline ? t.textPrimary : t.card),
            ),
          ),
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
