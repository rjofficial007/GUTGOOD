part of 'insight_ui_kit.dart';

/// Insight trend-chart and painter components.

/// `.chart` — the 7-day line trend with soft fill and an end dot.
class InsightTrendChart extends StatelessWidget {
  const InsightTrendChart({super.key, required this.values, this.height = 58, this.color, this.endDot = true});
  final List<double> values;
  final double height;
  final Color? color;
  final bool endDot;

  @override
  Widget build(BuildContext context) {
    final valid = values.where((value) => value.isFinite && value >= 0 && value <= 100).toList();
    final t = context.insightTheme;
    return Semantics(
      label: valid.isEmpty ? 'No recorded scores' : 'Gut scores out of 100, in recording order: ${valid.map((value) => value.round()).join(', ')}',
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: valid.isEmpty
            ? Center(
                child: Text('No score history yet', style: TextStyle(color: t.textSecondary)),
              )
            : CustomPaint(
                painter: _TrendPainter(color: color ?? t.success, gridColor: t.border, values: valid, endDot: endDot),
              ),
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
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final fraction in [0.0, 0.5, 1.0]) {
      final y = padding + height * fraction;
      canvas.drawLine(Offset(padding, y), Offset(size.width - padding, y), grid);
    }
    final points = [for (var i = 0; i < values.length; i++) Offset(values.length == 1 ? size.width / 2 : padding + width * i / (values.length - 1), padding + height * (1 - values[i] / 100))];
    if (points.length == 1) {
      canvas.drawCircle(points.single, 4, Paint()..color = color);
      return;
    }
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      line.lineTo(point.dx, point.dy);
    }
    final fill = Path.from(line)
      ..lineTo(points.last.dx, size.height - padding)
      ..lineTo(points.first.dx, size.height - padding)
      ..close();
    canvas
      ..drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withValues(alpha: .18), color.withValues(alpha: .01)]).createShader(Offset.zero & size),
      )
      ..drawPath(
        line,
        Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    for (final point in points) {
      canvas.drawCircle(point, 2.5, Paint()..color = color);
    }
    if (endDot) canvas.drawCircle(points.last, 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TrendPainter old) => old.color != color || old.gridColor != gridColor || old.endDot != endDot || !listEquals(old.values, values);
}

