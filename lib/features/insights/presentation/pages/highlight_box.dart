part of 'highlight_detail_screen.dart';

/// Highlight summary-box presentation component.

class _HighlightBox extends StatelessWidget {
  const _HighlightBox({required this.icon, required this.iconBg, required this.iconColor, required this.title, required this.subtitle});

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = context.insightTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(14.w),
        border: Border.all(color: theme.border, width: 1.w),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22.w,
            height: 22.w,
            decoration: BoxDecoration(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.2) : iconBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icon, size: 11.w, color: isDark ? const Color(0xFF4ADE80) : iconColor),
          ),
          Gap.w6,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: theme.textPrimary, height: 1.2),
                ),
                Gap.h2,
                Text(
                  subtitle,
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, color: theme.textSecondary, height: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

