part of 'bento_widgets.dart';

/// Bento food tile presentation components.

class FoodTile extends StatelessWidget {
  const FoodTile({super.key, required this.name, required this.stat, required this.emoji, required this.statColor, this.imageUrl});

  final String name;
  final String stat;
  final String emoji;
  final Color statColor;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final dark = PatternSurface.isDark(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.w),
      decoration: BoxDecoration(
        color: PatternSurface.card(context),
        borderRadius: BorderRadius.circular(BentoMetrics.radiusSm.w),
        border: Border.all(color: t.border.withValues(alpha: dark ? 1.0 : 0.6)),
        boxShadow: PatternSurface.softShadow(context),
      ),
      child: Row(
        children: [
          FoodArt(emoji: emoji, imageUrl: imageUrl, size: 28),
          Gap.w8,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w700, height: 1.1, color: PatternSurface.ink(context)),
                ),
                Gap.h2,
                Text(
                  stat,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w800, color: dark ? statColor : _getDeepStatColor(statColor), height: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getDeepStatColor(Color accent) => HSLColor.fromColor(accent).withLightness((HSLColor.fromColor(accent).lightness - 0.15).clamp(0.0, 1.0)).toColor();
}

/// The 2×2 food grid inside a span-2 bento (`.mini-food-grid`).
class MiniFoodGrid extends StatelessWidget {
  const MiniFoodGrid({super.key, required this.tiles, this.gap = 10});
  final List<Widget> tiles;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final g = gap.w;
    // Pair tiles into rows and stretch row-mates to a common height, so a long
    // food name cannot make one tile taller than its neighbour.
    final rows = <List<Widget>>[];
    for (var i = 0; i < tiles.length; i += 2) {
      rows.add(tiles.sublist(i, i + 2 > tiles.length ? tiles.length : i + 2));
    }
    return Padding(
      padding: EdgeInsets.only(top: 8.w),
      child: Column(
        children: [
          for (var r = 0; r < rows.length; r++) ...[
            if (r > 0) SizedBox(height: g),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: rows[r].first),
                  SizedBox(width: g),
                  Expanded(child: rows[r].length > 1 ? rows[r][1] : const SizedBox.shrink()),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Food artwork. The mock ships base64 illustrations; the app models food art
/// as an emoji (optionally an uploaded photo URL), so this renders whichever
/// is available and falls back to a neutral plate.
class FoodArt extends StatelessWidget {
  const FoodArt({super.key, required this.emoji, this.imageUrl, this.size = 28});

  final String emoji;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.w),
        child: SizedBox(
          width: size.w,
          height: size.w,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _EmojiArt(emoji: emoji, size: size),
          ),
        ),
      );
    }
    if (emoji.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(color: context.bentoTheme.border.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8.w)),
        child: SizedBox(width: size.w, height: size.w),
      );
    }
    return _EmojiArt(emoji: emoji, size: size);
  }
}

class _EmojiArt extends StatelessWidget {
  const _EmojiArt({required this.emoji, required this.size});
  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size.w,
    height: size.w,
    child: Center(
      child: Text(
        emoji,
        style: TextStyle(fontSize: (size * 0.72).sp, height: 1),
        textScaler: TextScaler.noScaling,
      ),
    ),
  );
}

/// The full-width dark action button (`.cta`).
