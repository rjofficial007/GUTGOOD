part of 'insight_bento_feed.dart';

class HealingSparklinePainter extends CustomPainter {
  HealingSparklinePainter({required this.color, this.values = const []});
  final Color color;
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final data = values.where((value) => value.isFinite && value >= 0 && value <= 100).toList();
    if (data.length < 2 || size.width <= 0 || size.height <= 0) return;
    final visible = data.length > 7 ? data.sublist(data.length - 7) : data;
    final min = visible.reduce(math.min);
    final max = visible.reduce(math.max);
    final range = max - min;
    final points = [for (var i = 0; i < visible.length; i++) Offset(size.width * i / (visible.length - 1), size.height * (0.85 - (range == 0 ? .35 : (visible[i] - min) / range * .7)))];
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      line.lineTo(point.dx, point.dy);
    }
    final area = Path.from(line)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    final fill = Paint()
      ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withValues(alpha: .2), color.withValues(alpha: 0)]).createShader(Offset.zero & size);
    canvas
      ..drawPath(area, fill)
      ..drawPath(
        line,
        Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      )
      ..drawCircle(points.last, 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(HealingSparklinePainter old) => old.color != color || !listEquals(old.values, values);
}

class TriggerSpikePainter extends CustomPainter {
  TriggerSpikePainter({required this.color, this.values = const []});
  final Color color;
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final data = values.where((value) => value.isFinite && value >= 0).toList();
    if (data.length < 2 || size.width <= 0 || size.height <= 0) return;
    final visible = data.length > 7 ? data.sublist(data.length - 7) : data;
    final min = visible.reduce(math.min);
    final max = visible.reduce(math.max);
    final range = max - min;
    final points = [for (var i = 0; i < visible.length; i++) Offset(size.width * i / (visible.length - 1), size.height * (0.85 - (range == 0 ? .35 : (visible[i] - min) / range * .7)))];
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      line.lineTo(point.dx, point.dy);
    }
    canvas
      ..drawPath(
        line,
        Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawCircle(points[visible.indexOf(max)], 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(TriggerSpikePainter old) => old.color != color || !listEquals(old.values, values);
}

class WorkingBarsPainter extends CustomPainter {
  WorkingBarsPainter({required this.color, this.values = const []});
  final Color color;

  /// Real series (e.g. per-day pattern episodes). Empty leaves the chart blank.
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;
    final gap = 6.w;

    final safeValues = values.where((value) => value.isFinite && value >= 0).toList();
    if (safeValues.length >= 2) {
      final data = safeValues.length > 7 ? safeValues.sublist(safeValues.length - 7) : safeValues;
      final n = data.length;
      final maxV = data.reduce(math.max);
      final barW = (w - (gap * (n - 1))) / n;
      for (var i = 0; i < n; i++) {
        final t = maxV <= 0 ? 0.5 : (0.25 + 0.75 * (data[i] / maxV)).clamp(0.0, 1.0);
        final rectH = h * t;
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(i * (barW + gap), h - rectH, barW, rectH), Radius.circular(math.min(4, barW / 2))),
          Paint()..color = color.withValues(alpha: n == 1 ? 1.0 : 0.45 + 0.55 * (i / (n - 1))),
        );
      }
      return;
    }

    return;
  }

  @override
  bool shouldRepaint(WorkingBarsPainter old) => old.color != color || !listEquals(old.values, values);
}
