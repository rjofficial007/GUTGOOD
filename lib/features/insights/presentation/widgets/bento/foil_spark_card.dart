part of 'bento_widgets.dart';

/// Bento sparkline presentation components.

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
