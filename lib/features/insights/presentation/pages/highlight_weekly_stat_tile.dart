part of 'highlight_detail_screen.dart';

/// Highlight weekly-stat presentation component.

class _WeeklyStatTile extends StatelessWidget {
  const _WeeklyStatTile({required this.icon, required this.iconBg, required this.iconColor, required this.label, required this.value, required this.subtext});

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
    final isFoodsLogged = label.toLowerCase().contains('foods logged');

    final tileBg = isDark ? (isFoodsLogged ? const Color(0xFF231A14) : const Color(0xFF102319)) : theme.card;
    final tileBorder = isDark ? (isFoodsLogged ? const Color(0xFFF97316).withValues(alpha: 0.28) : const Color(0xFF22C55E).withValues(alpha: 0.28)) : theme.border;
    final resolvedIconBg = isDark ? (isFoodsLogged ? const Color(0xFFF97316).withValues(alpha: 0.18) : const Color(0xFF22C55E).withValues(alpha: 0.18)) : iconBg;
    final resolvedIconColor = isDark ? (isFoodsLogged ? const Color(0xFFFB923C) : const Color(0xFF4ADE80)) : iconColor;
    final resolvedLabelColor = isDark ? (isFoodsLogged ? const Color(0xFFFB923C) : const Color(0xFF4ADE80)) : theme.textSecondary;

    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(14.w),
        border: Border.all(color: tileBorder, width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24.w,
            height: 24.w,
            decoration: BoxDecoration(color: resolvedIconBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icon, size: 12.w, color: resolvedIconColor),
          ),
          Gap.h6,
          Text(
            label,
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, color: resolvedLabelColor, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 16.sp, fontWeight: FontWeight.w800, color: theme.textPrimary),
          ),
          Text(
            subtext,
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.5.sp, color: theme.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

