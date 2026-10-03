part of 'highlight_detail_screen.dart';

/// Aligned day-label presentation component.

class AlignedDayLabelsRow extends StatelessWidget {
  const AlignedDayLabelsRow({super.key, required this.labels, required this.todayIndex, this.chartPadding = 6.0});

  final List<String> labels;
  final int todayIndex;
  final double chartPadding;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final totalW = constraints.maxWidth;
      if (totalW <= 0) return const SizedBox.shrink();

      final chartW = totalW - (chartPadding * 2);
      const count = 7;
      const labelBoxW = 20.0;

      return SizedBox(
        height: 16,
        width: totalW,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < labels.length && i < count; i++)
              Positioned(
                left: (chartPadding + (chartW * i / (count - 1))) - (labelBoxW / 2),
                top: 0,
                width: labelBoxW,
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: InsightTheme.fontFamily,
                    fontSize: 9.5.sp,
                    fontWeight: i == todayIndex ? FontWeight.w900 : FontWeight.w700,
                    color: i == todayIndex ? context.insightColor(const Color(0xFF0F172A)) : context.insightColor(const Color(0xFF64748B)),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
