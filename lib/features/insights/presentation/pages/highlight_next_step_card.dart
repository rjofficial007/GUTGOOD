part of 'highlight_detail_screen.dart';

/// Highlight next-step presentation component.

class _NextStepCard extends StatelessWidget {
  const _NextStepCard({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = context.insightTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF102319) : const Color(0xFFF4FAF5),
        borderRadius: BorderRadius.circular(14.w),
        border: Border.all(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.3) : const Color(0xFFDCFCE7), width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 22.w,
                height: 22.w,
                decoration: BoxDecoration(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.2) : const Color(0xFFDCFCE7), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(icon, size: 11.w, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
              ),
            ],
          ),
          Gap.h6,
          Text(
            title,
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: theme.textPrimary, height: 1.2),
          ),
          if (body.isNotEmpty && body.trim() != title.trim()) ...[
            Gap.h2,
            Text(
              body,
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, color: theme.textSecondary, height: 1.2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

