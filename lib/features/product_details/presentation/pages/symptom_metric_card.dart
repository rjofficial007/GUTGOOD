part of 'symptom_detail_screen.dart';

/// Symptom metric card component.

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.color, required this.value, required this.label});

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNumber = RegExp(r'^\d+').hasMatch(value);
    final isLong = value.length > 10;
    final fontSize = isNumber ? 15.sp : (isLong ? 9.5.sp : 11.sp);

    final bgStart = color.withValues(alpha: isDark ? 0.22 : 0.12);
    final bgEnd = color.withValues(alpha: isDark ? 0.12 : 0.04);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [bgStart, bgEnd]),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.12 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.28 : 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20.sp, color: color),
          ),
          Gap.h8,
          Center(
            child: Text(
              value,
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: fontSize, fontWeight: FontWeight.w900, height: 1.15, color: color),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Gap.h2,
          Text(
            label.toUpperCase(),
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: t.textSecondary),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// 🌟 Section 4: Potential Triggers & Expert Analysis (matching ScanWatchSection).
