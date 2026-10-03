part of 'bento_widgets.dart';

/// Bento tag and surface presentation components.

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
