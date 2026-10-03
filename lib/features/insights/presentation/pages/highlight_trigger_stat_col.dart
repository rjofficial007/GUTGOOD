part of 'highlight_detail_screen.dart';

/// Highlight trigger-stat presentation component.

class _TriggerStatCol extends StatelessWidget {
  const _TriggerStatCol({required this.icon, required this.iconBg, required this.iconColor, required this.label, required this.value, required this.subtext});

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final String subtext;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22.w,
          height: 22.w,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(icon, size: 11.w, color: iconColor),
        ),
        Gap.h4,
        Text(
          label,
          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.sp, color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626), fontWeight: FontWeight.w600),
        ),
        Gap.h2,
        Text(
          value,
          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A)), height: 1.15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Gap.h2,
        Text(
          subtext,
          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.5.sp, color: context.insightColor(const Color(0xFF64748B))),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

