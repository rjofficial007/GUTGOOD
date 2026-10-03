part of 'bento_widgets.dart';

/// Bento card surface presentation components.

/// A single bento tile. Mirrors `.bento-card` in the mock: a tinted gradient
/// surface, an uppercase tag pill, a title, optional body copy, and an
/// optional hairline footer row.
class BentoCard extends StatelessWidget {
  const BentoCard({
    super.key,
    required this.title,
    this.tone = BentoTone.white,
    this.spanTwo = false,
    this.tag,
    this.tagIcon,
    this.badge,
    this.body,
    this.media,
    this.emphasis,
    this.footLeft,
    this.footRight,
    this.onTap,
    this.extra,
    this.minHeight,
  });

  final BentoTone tone;

  /// Spans both grid columns (`.bento-card.span-2`).
  final bool spanTwo;
  final String? tag;

  /// Emoji rendered before the tag text, matching the mock's `🔍 PATTERN…`.
  final String? tagIcon;

  /// Right-aligned counter in the tag row (`94% MATCH`, `+18%`, `3 LOGS`).
  final String? badge;
  final String title;
  final String? body;
  final Widget? media;

  /// A large stat figure shown between the tag row and the title.
  final Widget? emphasis;
  final String? footLeft;
  final String? footRight;
  final VoidCallback? onTap;

  /// Slot for bespoke content (a CTA button, a mini food grid, …).
  final Widget? extra;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final p = t.bento(tone);

    return _CardSurface(
      palette: p,
      radius: BentoMetrics.radius.w,
      shadowColor: p.shadowTint.withValues(alpha: tone == BentoTone.white ? 0.03 : 0.06),
      shadowBlur: (tone == BentoTone.white ? 8 : 12).w,
      shadowOffset: Offset(0, (tone == BentoTone.white ? 2.0 : 4.0).w),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(BentoMetrics.padding.w),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight == null ? 0 : minHeight!.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (tag != null || badge != null) _tagRow(p),
              if (emphasis != null)
                Padding(
                  padding: EdgeInsets.only(top: 8.w),
                  child: emphasis!,
                ),
              if (media != null || body != null) ...[
                Gap.h8,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (body != null || media == null)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _title(t),
                            if (body != null) ...[Gap.h4, _body(t)],
                          ],
                        ),
                      )
                    else
                      Expanded(child: _title(t)),
                    if (media != null) ...[Gap.w10, media!],
                  ],
                ),
              ] else ...[
                Gap.h8,
                _title(t),
                if (body != null) ...[Gap.h4, _body(t)],
              ],
              if (extra != null)
                Padding(
                  padding: EdgeInsets.only(top: 12.w),
                  child: extra!,
                ),
              if (footLeft != null || footRight != null) _footer(t, p),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tagRow(BentoPalette p) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Both sides are Flexible so a long tag plus a long badge can never
      // overflow the tile. Loose fit leaves free space, so spaceBetween still
      // pins the badge to the right edge.
      if (tag != null)
        Flexible(
          child: BentoTag(tone: tone, label: tag!, icon: tagIcon),
        ),
      if (badge != null) ...[
        Gap.w8,
        Flexible(
          child: Text(
            badge!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w700, color: p.tagForeground, height: 1.2),
          ),
        ),
      ],
    ],
  );

  Widget _title(InsightBentoTheme t) {
    final size = spanTwo ? BentoMetrics.titleWideSize : BentoMetrics.titleSize;
    final tracking = spanTwo ? BentoMetrics.titleWideTracking : BentoMetrics.titleTracking;
    return Text(
      title,
      style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: size.sp, fontWeight: FontWeight.w600, letterSpacing: tracking, height: 1.25, color: t.textPrimary),
    );
  }

  Widget _body(InsightBentoTheme t) => Text(
    body!,
    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.bodySize.sp, fontWeight: FontWeight.w400, height: 1.4, color: t.textSecondary),
  );

  Widget _footer(InsightBentoTheme t, BentoPalette p) => Container(
    margin: EdgeInsets.only(top: 10.w),
    padding: EdgeInsets.only(top: 8.w),
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: t.textPrimary.withValues(alpha: 0.05))),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (footLeft != null)
          Expanded(
            child: Text(
              footLeft!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w600, color: p.footForeground, height: 1.2),
            ),
          ),
        if (footRight != null) ...[
          Gap.w8,
          // Same treatment as footLeft: a rigid Text here is the one part of
          // the footer that can still push past the card edge.
          Flexible(
            child: Text(
              footRight!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.footSize.sp, fontWeight: FontWeight.w600, color: p.footForeground, height: 1.2),
            ),
          ),
        ],
      ],
    ),
  );
}

