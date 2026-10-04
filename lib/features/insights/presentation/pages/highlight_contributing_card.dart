part of 'highlight_detail_screen.dart';

/// Highlight contributing-factor presentation component.

class _ContributingCard extends StatelessWidget {
  const _ContributingCard({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.imageKeyword,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeColor;
  final Color badgeTextColor;
  final String imageKeyword;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = context.insightTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = InsightUiKit.foodImageUrl(imageKeyword);

    return Container(
      width: 108.w,
      padding: EdgeInsets.all(7.w),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(14.w),
        border: Border.all(color: theme.border, width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.w),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: 94.w,
              height: 60.w,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(color: theme.cardSubtle),
              errorWidget: (_, _, _) => Container(
                color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.2) : const Color(0xFFDCFCE7),
                alignment: Alignment.center,
                child: Icon(icon, size: 20.w, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
              ),
            ),
          ),
          Gap.h5,
          Text(
            title,
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: theme.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.sp, color: theme.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Gap.h3,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.w),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.2) : badgeColor, borderRadius: BorderRadius.circular(10.w)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 8.5.w, color: isDark ? const Color(0xFF4ADE80) : badgeTextColor),
                Gap.w2,
                Flexible(
                  child: Text(
                    badgeText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFF4ADE80) : badgeTextColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

