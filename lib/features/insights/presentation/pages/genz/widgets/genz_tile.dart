import 'package:flutter/material.dart';
import 'package:gutgood/features/insights/presentation/pages/genz/genz_theme.dart';

enum GenzTone { lime, pink, blue, orange, lilac, butter, ink }

class GenzTile extends StatelessWidget {

  const GenzTile({
    super.key,
    required this.tone,
    required this.child,
    this.art,
    this.height,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });
  final GenzTone tone;
  final Widget child;
  final Widget? art;
  final double? height;
  final EdgeInsetsGeometry padding;
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
      style: TextStyle(fontFamily: 'InterTight', color: _fgColor),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: bgColor,
            gradient: RadialGradient(
              center: const Alignment(1.0, -1.0), // Top right approximation
              radius: 1.5,
              colors: [Colors.white.withValues(alpha: 0.3), bgColor],
              stops: const [0.0, 0.58],
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            fit: height != null ? StackFit.expand : StackFit.loose,
            clipBehavior: Clip.none,
            children: [
              if (art != null) art!,
              child,
            ],
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
    this.tone = GenzTone.ink,
    this.angle = -0.05, // ~ -3 degrees
  });
  final String text;
  final GenzTone tone;
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
          style: TextStyle(
            color: fg,
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}
