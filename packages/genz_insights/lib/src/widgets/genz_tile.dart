import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:genz_insights/src/genz_theme.dart';

enum GenzTone { lime, pink, blue, orange, lilac, butter, ink }

/// Converts Flutter's circular radial shader into the prototype's 120% x 90%
/// top-right ellipse.
@immutable
class GenzCssRadialTransform extends GradientTransform {
  const GenzCssRadialTransform({this.verticalRadius = 0.9});

  /// Percentage of bounds.height used for the CSS-style vertical radius.
  final double verticalRadius;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final shortestSide = bounds.shortestSide;
    if (shortestSide == 0) return Matrix4.identity();

    final center = Alignment.topRight.withinRect(bounds);
    return Matrix4.identity()
      ..translate(center.dx, center.dy)
      ..scale(
        bounds.width / shortestSide,
        (verticalRadius / 1.2) * bounds.height / shortestSide,
      )
      ..translate(-center.dx, -center.dy);
  }
}

/// Applies the prototype's white cut-out stroke and soft drop shadow to
/// transparent decorative assets.
class GenzArt extends StatelessWidget {
  const GenzArt({
    super.key,
    required this.asset,
    required this.width,
    required this.height,
    this.fit = BoxFit.contain,
  });

  final String asset;
  final double width;
  final double height;
  final BoxFit fit;

  Widget _tinted(Color color) => ColorFiltered(
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        child: Image.asset(asset, fit: fit, package: 'genz_insights'),
      );

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Transform.translate(
                offset: const Offset(2, 12),
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: _tinted(Colors.black.withOpacity(0.28)),
                ),
              ),
            ),
            for (final offset in const [Offset(2, 0), Offset(-2, 0), Offset(0, 2), Offset(0, -2)])
              Positioned.fill(
                child: Transform.translate(offset: offset, child: _tinted(Colors.white)),
              ),
            Positioned.fill(child: Image.asset(asset, fit: fit, package: 'genz_insights')),
          ],
        ),
      );
}

class GenzTile extends StatelessWidget {
  const GenzTile({
    super.key,
    required this.tone,
    required this.child,
    this.art,
    this.height,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 30,
    this.onTap,
  });

  final GenzTone tone;
  final Widget child;
  final Widget? art;
  final double? height;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;

  Color _bgColor(BuildContext context) {
    switch (tone) {
      case GenzTone.lime:
        return GenzColors.lime;
      case GenzTone.pink:
        return GenzColors.pink;
      case GenzTone.blue:
        return GenzColors.blue;
      case GenzTone.orange:
        return GenzColors.orange;
      case GenzTone.lilac:
        return GenzColors.lilac;
      case GenzTone.butter:
        return GenzColors.butter;
      case GenzTone.ink:
        return GenzColors.tileInk(context);
    }
  }

  Color get _fgColor {
    switch (tone) {
      case GenzTone.blue:
      case GenzTone.ink:
        return Colors.white;
      default:
        return const Color(0xFF0B0B12);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _bgColor(context);
    return DefaultTextStyle(
      style: TextStyle(
        fontFamily: GenzFonts.primary,
        fontFamilyFallback: GenzFonts.fallback,
        color: _fgColor,
      ),
      child: _GenzPressScale(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          clipBehavior: Clip.hardEdge,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.2,
                colors: [Colors.white.withValues(alpha: 0.3), Colors.transparent],
                stops: const [0.0, 0.58],
                transform: const GenzCssRadialTransform(),
              ),
            ),
            child: Stack(
              fit: height != null ? StackFit.expand : StackFit.loose,
              clipBehavior: Clip.none,
              children: [
                if (art != null) art!,
                Padding(padding: padding, child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GenzSticker extends StatelessWidget {
  const GenzSticker({
    super.key,
    required this.text,
    this.tone,
    this.angle = -0.05,
  });

  final String text;
  final GenzTone? tone;
  final double angle;

  @override
  Widget build(BuildContext context) {
    var bg = Colors.white;
    var fg = GenzColors.ink;
    var shadow = GenzColors.ink;

    if (tone == GenzTone.ink) {
      bg = GenzColors.ink;
      fg = GenzColors.lime;
      shadow = Colors.white.withValues(alpha: 0.25);
    } else if (tone == GenzTone.lime) {
      bg = GenzColors.lime;
      fg = GenzColors.ink;
    } else if (tone == GenzTone.orange) {
      bg = GenzColors.orange;
      fg = GenzColors.ink;
    }

    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(11),
          boxShadow: [BoxShadow(color: shadow, offset: const Offset(0, 3))],
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: GenzFonts.primary,
            fontFamilyFallback: GenzFonts.fallback,
            color: GenzColors.ink,
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.1,
          ).copyWith(color: fg),
        ),
      ),
    );
  }
}

/// Mirrors the prototype's `[data-go]:active { transform: scale(.985) }`.
class _GenzPressScale extends StatefulWidget {
  const _GenzPressScale({
    super.key,
    required this.child,
    required this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_GenzPressScale> createState() => _GenzPressScaleState();
}

class _GenzPressScaleState extends State<_GenzPressScale> {
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed == pressed) return;
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
        onTapUp: widget.onTap == null ? null : (_) => _setPressed(false),
        onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
        child: Transform.scale(
          scale: _pressed ? 0.985 : 1,
          child: widget.child,
        ),
      );
}
