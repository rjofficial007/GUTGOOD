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
    final theme = context.insightTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B191B) : const Color(0xFFFFF1EF),
        borderRadius: BorderRadius.circular(14.w),
        border: Border.all(color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.18) : const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icon, size: 14.w, color: iconColor),
          ),
          Gap.w8,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w800, letterSpacing: 0.45, color: theme.textTertiary)),
                Gap.h4,
                Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w800, height: 1.2, color: theme.textPrimary)),
                Gap.h2,
                Text(subtext, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.sp, color: theme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

