import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/insight_bento_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/pattern_style.dart';

export 'insight_bento_theme.dart';

/// Shared metrics transcribed from `uploads/v4.html`.
///
/// Kept in one place so the seven Insights screens cannot drift apart. CSS
/// `letter-spacing` is authored in `em` upstream; Flutter's is absolute, so
/// every value below is pre-multiplied by its own font size.
abstract final class BentoMetrics {
  static const double radius = 16;
  static const double radiusSm = 12;
  static const double heroRadius = 20;
  static const double padding = 14;
  static const double gridGap = 12;
  static const double heroPaddingH = 20;
  static const double heroPaddingTop = 18;
  static const double heroPaddingBottom = 16;

  // Type scale (fontSize, letterSpacing) — em values resolved against the size.
  static const double tagSize = 8.5;
  static const double tagTracking = 1.36; // .16em
  static const double eyebrowSize = 10;
  static const double eyebrowTracking = 2.4; // .24em
  static const double titleSize = 14.5;
  static const double titleTracking = -0.29; // -.02em
  static const double titleWideSize = 17;
  static const double titleWideTracking = -0.51; // -.03em
  static const double bodySize = 11.5;
  static const double footSize = 11;
  static const double scoreSize = 68;
  static const double scoreTracking = -4.08; // -.06em
  static const double deltaSize = 13.5;
  static const double statusSize = 10.5;
  static const double trackHeight = 6;
  static const double ctaHeight = 46;
  static const double ctaRadius = 12;
}

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

/// The uppercase pill in a bento card's corner (`.bento-tag`).
class BentoTag extends StatelessWidget {
  const BentoTag({super.key, required this.tone, required this.label, this.icon, this.overrideBackground, this.overrideForeground});

  final BentoTone tone;
  final String label;
  final String? icon;
  final Color? overrideBackground;
  final Color? overrideForeground;

  @override
  Widget build(BuildContext context) {
    final p = context.bentoTheme.bento(tone);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.w),
      decoration: BoxDecoration(color: overrideBackground ?? p.tagBackground, borderRadius: BorderRadius.circular(100)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Text(icon!, style: TextStyle(fontSize: 8.sp, height: 1)), Gap.w4],
          // Flexible + ellipsis: the pill shrinks and truncates rather than
          // pushing the row past the tile edge.
          Flexible(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: InsightBentoTheme.fontFamily,
                fontSize: BentoMetrics.tagSize.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: BentoMetrics.tagTracking,
                color: overrideForeground ?? p.tagForeground,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints the gradient surface, border and tinted shadow behind bento content.
class _CardSurface extends StatelessWidget {
  const _CardSurface({required this.palette, required this.radius, required this.shadowColor, required this.shadowBlur, required this.shadowOffset, required this.child, this.onTap});

  final BentoPalette palette;
  final double radius;
  final Color shadowColor;
  final double shadowBlur;
  final Offset shadowOffset;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: BentoPalette.begin, end: BentoPalette.end, colors: [palette.gradientStart, palette.gradientEnd]),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: palette.border),
        boxShadow: [BoxShadow(color: shadowColor, blurRadius: shadowBlur, offset: shadowOffset)],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(radius), child: child),
      ),
    );
    if (onTap == null) return content;
    return Semantics(button: true, child: content);
  }
}

/// The two-column bento grid (`.bento-grid`).
///
/// Implemented with [Wrap] rather than a `GridView`: the screens mix 1×1 and
/// span-2 tiles in arbitrary order, and a fixed-aspect grid would either crop
/// text or leave ragged holes. Wrap flows span-2 tiles onto their own row and
/// packs the 1×1s beside each other, matching CSS grid auto-flow.
class BentoGrid extends StatelessWidget {
  const BentoGrid({super.key, required this.children, this.gap = BentoMetrics.gridGap, this.runSpacing});

  final List<BentoTile> children;
  final double gap;
  final double? runSpacing;

  /// Splits the flat tile list into visual rows the way CSS grid auto-flow
  /// does: a span-2 tile takes a row to itself, 1x1 tiles pair up, and a lone
  /// trailing 1x1 keeps its half-width slot so the column rhythm holds.
  @visibleForTesting
  static List<List<BentoTile>> computeRows(List<BentoTile> tiles) {
    final rows = <List<BentoTile>>[];
    var i = 0;
    while (i < tiles.length) {
      if (tiles[i].spanTwo) {
        rows.add([tiles[i]]);
        i += 1;
      } else if (i + 1 < tiles.length && !tiles[i + 1].spanTwo) {
        rows.add([tiles[i], tiles[i + 1]]);
        i += 2;
      } else {
        rows.add([tiles[i]]);
        i += 1;
      }
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final g = gap.w;
      final rg = (runSpacing ?? gap).w;
      final half = (constraints.maxWidth - g) / 2;
      final rows = computeRows(children);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var r = 0; r < rows.length; r++) ...[if (r > 0) SizedBox(height: rg), _BentoRow(tiles: rows[r], halfWidth: half, gap: g, fullWidth: constraints.maxWidth)],
        ],
      );
    },
  );
}

/// One grid row. [IntrinsicHeight] + `CrossAxisAlignment.stretch` is what makes
/// row-mates equal height, reproducing CSS grid's default `align-items:
/// stretch`. Without it a `Wrap` sizes every tile to its own content, which is
/// how a 64px height gap between two cards in the same row crept in.
class _BentoRow extends StatelessWidget {
  const _BentoRow({required this.tiles, required this.halfWidth, required this.gap, required this.fullWidth});

  final List<BentoTile> tiles;
  final double halfWidth;
  final double gap;
  final double fullWidth;

  @override
  Widget build(BuildContext context) {
    if (tiles.length == 1 && tiles.first.spanTwo) {
      return IntrinsicHeight(
        child: SizedBox(width: fullWidth, child: tiles.first.child),
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: halfWidth, child: tiles.first.child),
          SizedBox(width: gap),
          // A lone 1x1 keeps an empty second slot so the next row still lines up.
          SizedBox(width: halfWidth, child: tiles.length > 1 ? tiles[1].child : null),
        ],
      ),
    );
  }
}

/// A [BentoCard] paired with the flag that says whether it spans both columns.
class BentoTile {
  const BentoTile(this.child, {this.spanTwo = false});
  final Widget child;
  final bool spanTwo;
}

/// The score hero (`.score-hero-standout`).
///
/// Reused by screens 01, 02, 03 and 07 with different eyebrow/badge copy, so
/// every knob the mock varies is a parameter rather than a separate widget.
class ScoreHeroCard extends StatelessWidget {
  const ScoreHeroCard({
    super.key,
    required this.eyebrow,
    required this.value,
    this.statusBadge,
    this.delta,
    this.deltaSub,
    this.trackProgress,
    this.trackGradient,
    this.footLeft,
    this.footRight,
    this.valueColor,
    this.dotColor,
    this.deltaBackground,
    this.deltaForeground,
    this.statusBackground,
    this.statusForeground,
    this.statusBorder,
    this.gradientBackground,
    this.borderOverride,
    this.showTrack = true,
    this.onTap,
    this.between,
    this.footRightColor,
  });

  final String eyebrow;

  /// The 68px figure — a score, a count, or `--` while learning.
  final String value;
  final String? statusBadge;
  final String? delta;
  final String? deltaSub;

  /// 0..1 fill of the score track. `null` hides the track (screen 07).
  final double? trackProgress;

  /// Overrides the default orange→gold→mint ramp (screen 02 uses orange→gold).
  final List<Color>? trackGradient;
  final String? footLeft;
  final String? footRight;
  final Color? footRightColor;
  final Color? valueColor;
  final Color? dotColor;
  final Color? deltaBackground;
  final Color? deltaForeground;
  final Color? statusBackground;
  final Color? statusForeground;
  final Color? statusBorder;

  /// Overrides the hero's white surface (screen 02's learning gradient).
  final LinearGradient? gradientBackground;
  final Color? borderOverride;

  /// When false the track bar is omitted entirely (screen 07's food hero).
  final bool showTrack;
  final VoidCallback? onTap;

  /// Optional slot between the track and the footer (screen 03's sparkline).
  final Widget? between;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final radius = BentoMetrics.heroRadius.w;

    return Semantics(
      button: onTap != null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradientBackground ?? LinearGradient(colors: [t.cardBackground, t.cardBackground]),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderOverride ?? t.border),
          boxShadow: [
            BoxShadow(color: t.textPrimary.withValues(alpha: 0.05), blurRadius: 18.w, offset: Offset(0, 4.w)),
            BoxShadow(color: t.textPrimary.withValues(alpha: 0.03), blurRadius: 3.w, offset: Offset(0, 1.w)),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Stack(
                children: [
                  Positioned(
                    top: -30.w,
                    right: -30.w,
                    child: _HeroGlow(warm: t.heroGlowWarm, cool: t.heroGlowCool),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(BentoMetrics.heroPaddingH.w, BentoMetrics.heroPaddingTop.w, BentoMetrics.heroPaddingH.w, BentoMetrics.heroPaddingBottom.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Flexible on both sides: an uppercase eyebrow with
                            // .24em tracking is wide, and the status pill is
                            // not allowed to push it off the card.
                            Flexible(
                              child: _Eyebrow(text: eyebrow, dotColor: dotColor ?? t.mint),
                            ),
                            if (statusBadge != null) ...[
                              Gap.w8,
                              Flexible(
                                child: _StatusPill(
                                  label: statusBadge!,
                                  background: statusBackground ?? t.statusBadgeBackground,
                                  foreground: statusForeground ?? t.statusBadgeForeground,
                                  border: statusBorder ?? t.statusBadgeBorder,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Gap.h10,
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              value,
                              style: TextStyle(
                                fontFamily: InsightBentoTheme.fontFamily,
                                fontSize: BentoMetrics.scoreSize.sp,
                                fontWeight: FontWeight.w300,
                                letterSpacing: BentoMetrics.scoreTracking,
                                height: 0.9,
                                fontFeatures: const [FontFeature.liningFigures(), FontFeature.tabularFigures()],
                                color: valueColor ?? t.textPrimary,
                              ),
                            ),
                            if (delta != null || deltaSub != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (delta != null)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.w),
                                      decoration: BoxDecoration(color: deltaBackground ?? t.deltaPillBackground, borderRadius: BorderRadius.circular(100)),
                                      child: Text(
                                        delta!,
                                        style: TextStyle(
                                          fontFamily: InsightBentoTheme.fontFamily,
                                          fontSize: BentoMetrics.deltaSize.sp,
                                          fontWeight: FontWeight.w700,
                                          color: deltaForeground ?? t.deltaPillForeground,
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                  if (deltaSub != null) ...[
                                    Gap.h4,
                                    Text(
                                      deltaSub!,
                                      style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.bodySize.sp, color: t.textTertiary, height: 1.2),
                                    ),
                                  ],
                                ],
                              ),
                          ],
                        ),
                        if (showTrack && trackProgress != null) ...[
                          Gap.h14,
                          SizedBox(
                            width: double.infinity,
                            child: ScoreTrack(progress: trackProgress!, colors: trackGradient),
                          ),
                        ],
                        ?between,
                        if (footLeft != null || footRight != null) ...[
                          Gap.h10,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (footLeft != null)
                                Expanded(
                                  child: Text(
                                    footLeft!,
                                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.bodySize.sp, fontWeight: FontWeight.w500, color: t.textSecondary, height: 1.3),
                                  ),
                                ),
                              if (footRight != null) ...[
                                Gap.w8,
                                Text(
                                  footRight!,
                                  style: TextStyle(
                                    fontFamily: InsightBentoTheme.fontFamily,
                                    fontSize: BentoMetrics.bodySize.sp,
                                    fontWeight: FontWeight.w700,
                                    color: footRightColor ?? t.positive,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.text, required this.dotColor});
  final String text;
  final Color dotColor;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 6.w,
        height: 6.w,
        decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
      ),
      Gap.w6,
      Flexible(
        child: Text(
          text.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: InsightBentoTheme.fontFamily,
            fontSize: BentoMetrics.eyebrowSize.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: BentoMetrics.eyebrowTracking,
            color: context.bentoTheme.textTertiary,
            height: 1.2,
          ),
        ),
      ),
    ],
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.background, required this.foreground, required this.border});
  final String label;
  final Color background;
  final Color foreground;
  final Color border;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.w),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(100),
      border: Border.all(color: border),
    ),
    child: Text(
      label.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: BentoMetrics.statusSize.sp, fontWeight: FontWeight.w700, color: foreground, height: 1.2),
    ),
  );
}

/// The `::after` radial glow behind the score hero's top-right corner.
class _HeroGlow extends StatelessWidget {
  const _HeroGlow({required this.warm, required this.cool});
  final Color warm;
  final Color cool;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: 140.w,
      height: 140.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [warm, cool, cool.withValues(alpha: 0)], stops: const [0, 0.5, 0.7]),
      ),
    ),
  );
}

/// The 6px score track with its orange→gold→mint fill (`.score-track-bar`).
class ScoreTrack extends StatelessWidget {
  const ScoreTrack({super.key, required this.progress, this.colors});

  final double progress;
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final ramp = colors ?? [t.scoreTrackStart, t.scoreTrackMid, t.scoreTrackEnd];
    final stops = ramp.length == 3 ? const [0.0, 0.5, 1.0] : null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: Container(
        height: BentoMetrics.trackHeight.w,
        decoration: BoxDecoration(color: t.textPrimary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(99)),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: LinearGradient(colors: ramp, stops: stops),
            ),
          ),
        ),
      ),
    );
  }
}

/// The three-up mini gauge row on screen 05 (`.tickfan` + the `tickArc` JS).
class TickFanRow extends StatelessWidget {
  const TickFanRow({super.key, required this.items, this.tickCount = 24});

  final List<TickFanItem> items;
  final int tickCount;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) Gap.w8,
        Expanded(
          child: _TickFan(item: items[i], tickCount: tickCount),
        ),
      ],
    ],
  );
}

class TickFanItem {
  const TickFanItem({required this.fraction, required this.amount, required this.label});
  final double fraction;
  final String amount;
  final String label;
}

class _TickFan extends StatelessWidget {
  const _TickFan({required this.item, required this.tickCount});
  final TickFanItem item;
  final int tickCount;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 10.w),
      decoration: BoxDecoration(
        color: t.tileBackground,
        borderRadius: BorderRadius.circular(BentoMetrics.radiusSm.w),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 50.w,
            width: double.infinity,
            child: CustomPaint(
              painter: _TickArcPainter(fraction: item.fraction.clamp(0.0, 1.0), tickCount: tickCount, lit: t.tickLit, unlit: t.tickUnlit),
            ),
          ),
          Gap.h4,
          Text(
            item.amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: InsightBentoTheme.fontFamily,
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: t.textPrimary,
            ),
          ),
          Gap.h2,
          Text(
            item.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: InsightBentoTheme.fontFamily,
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.44, // .16em of 9px
              color: t.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ports `tickArc(t)` from the mock: [tickCount] radial strokes sweeping from
/// 180° to 0°, lit up to `fraction`, round-capped, lit strokes thicker.
class _TickArcPainter extends CustomPainter {
  const _TickArcPainter({required this.fraction, required this.tickCount, required this.lit, required this.unlit});

  final double fraction;
  final int tickCount;
  final Color lit;
  final Color unlit;

  @override
  void paint(Canvas canvas, Size size) {
    // The mock draws in an 80x60 box centred at (40,60) with radii 20..30.
    final scale = size.height / 60.0;
    final center = Offset(size.width / 2, size.height);
    final inner = 20.0 * scale;
    final outer = 30.0 * scale;
    final litPaint = Paint()
      ..strokeWidth = 1.8 * scale
      ..strokeCap = StrokeCap.round
      ..color = lit;
    final unlitPaint = Paint()
      ..strokeWidth = 1.2 * scale
      ..strokeCap = StrokeCap.round
      ..color = unlit;

    for (var i = 0; i < tickCount; i++) {
      final p = tickCount == 1 ? 0.0 : i / (tickCount - 1);
      final angle = math.pi * (1 - p);
      final dir = Offset(math.cos(angle), -math.sin(angle));
      final isLit = p <= fraction + 0.001;
      canvas.drawLine(center + dir * inner, center + dir * outer, isLit ? litPaint : unlitPaint);
    }
  }

  @override
  bool shouldRepaint(_TickArcPainter old) => old.fraction != fraction || old.tickCount != tickCount || old.lit != lit || old.unlit != unlit;
}

/// The weekly sparkline card on screen 03 (`.foilspark`).
class FoilSparkCard extends StatelessWidget {
  const FoilSparkCard({super.key, required this.values, this.labels = const [], this.height = 50});

  final List<double> values;
  final List<String> labels;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    return Container(
      margin: EdgeInsets.only(top: 8.w, bottom: 12.w),
      padding: EdgeInsets.fromLTRB(14.w, 12.w, 14.w, 10.w),
      decoration: BoxDecoration(
        color: t.tileBackground,
        borderRadius: BorderRadius.circular(14.w),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: height.w,
            width: double.infinity,
            child: CustomPaint(
              painter: _SparkPainter(values: values, line: t.positive, fill: t.positive.withValues(alpha: 0.10), peak: t.positive),
            ),
          ),
          if (labels.isNotEmpty) ...[
            Gap.h4,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final l in labels)
                    Text(
                      l,
                      style: TextStyle(
                        fontFamily: InsightBentoTheme.fontFamily,
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.38, // .04em
                        color: t.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ports the `foilspark` script: normalises to the max, pads 8px either side
/// and 8px top/bottom, then draws a filled area under a 2px stroke.
class _SparkPainter extends CustomPainter {
  const _SparkPainter({required this.values, required this.line, required this.fill, required this.peak});

  final List<double> values;
  final Color line;
  final Color fill;
  final Color peak;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final w = size.width;
    final h = size.height;
    const pad = 8.0;
    final maxV = values.fold<double>(1, (m, v) => v > m ? v : m);

    Offset at(int i) {
      final x = values.length == 1 ? pad : pad + (w - pad * 2) * i / (values.length - 1);
      final y = h - 8 - (values[i] / maxV) * (h - 16);
      return Offset(x, y);
    }

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    final area = Path.from(path)
      ..lineTo(at(values.length - 1).dx, h)
      ..lineTo(at(0).dx, h)
      ..close();

    final fillPaint = Paint()..color = fill;
    final linePaint = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas
      ..drawPath(area, fillPaint)
      ..drawPath(path, linePaint);

    // Peak marker, matching the mock's highlighted max point.
    var peakIdx = 0;
    for (var i = 1; i < values.length; i++) {
      if (values[i] > values[peakIdx]) peakIdx = i;
    }
    final p = at(peakIdx);
    canvas
      ..drawCircle(p, 3.5, Paint()..color = peak)
      ..drawCircle(p, 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.values != values || old.line != line || old.fill != fill;
}

/// The text-tab strip on screen 04 (`.seg`), with the trailing "Filter".
class BentoSegmentedTabs extends StatelessWidget {
  const BentoSegmentedTabs({super.key, required this.tabs, required this.selectedIndex, required this.onChanged, this.trailingLabel});

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 10.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // The strip scrolls rather than overflows, so long or numerous labels
          // can never push the trailing action off-screen.
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < tabs.length; i++) ...[
                    if (i > 0) SizedBox(width: 18.w),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(i),
                      child: Container(
                        padding: EdgeInsets.only(bottom: 6.w),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: i == selectedIndex ? t.textPrimary : Colors.transparent, width: 2)),
                        ),
                        child: Text(
                          tabs[i],
                          style: TextStyle(
                            fontFamily: InsightBentoTheme.fontFamily,
                            fontSize: 13.5.sp,
                            fontWeight: i == selectedIndex ? FontWeight.w700 : FontWeight.w500,
                            color: i == selectedIndex ? t.textPrimary : t.textQuaternary,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (trailingLabel != null) SizedBox(width: 18.w),
          if (trailingLabel != null)
            Padding(
              padding: EdgeInsets.only(bottom: 6.w),
              child: Text(
                trailingLabel!,
                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w500, color: t.textQuaternary, height: 1.2),
              ),
            ),
        ],
      ),
    );
  }
}

/// One food entry inside the span-2 "Top Foods" card (`.food-tile`).
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
class BentoCta extends StatelessWidget {
  const BentoCta({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    return SizedBox(
      width: double.infinity,
      height: BentoMetrics.ctaHeight.w,
      child: Material(
        color: t.ctaBackground,
        borderRadius: BorderRadius.circular(BentoMetrics.ctaRadius.w),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(BentoMetrics.ctaRadius.w),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: InsightBentoTheme.fontFamily,
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.27, // .02em
                color: t.ctaForeground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A soft plate behind the emoji art used by the larger bento tiles, standing
/// in for the mock's illustration column.
class BentoArtPlate extends StatelessWidget {
  const BentoArtPlate({super.key, required this.emoji, this.tone = BentoTone.white, this.width = 68, this.height = 62, this.imageUrl});

  final String emoji;
  final BentoTone tone;
  final double width;
  final double height;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final p = context.bentoTheme.bento(tone);
    return SizedBox(
      width: width.w,
      height: height.w,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12.w),
          border: Border.all(color: p.border),
        ),
        child: Center(
          child: FoodArt(emoji: emoji, imageUrl: imageUrl, size: height * 0.72),
        ),
      ),
    );
  }
}

/// Large stat figure used by the mock's `24px` emphasis blocks.
class BentoEmphasis extends StatelessWidget {
  const BentoEmphasis({super.key, required this.text, required this.color, this.size = 24});

  final String text;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: size.sp, fontWeight: FontWeight.w700, color: color, height: 1.1),
  );
}
