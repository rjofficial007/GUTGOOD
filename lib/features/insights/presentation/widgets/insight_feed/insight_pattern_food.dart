part of 'insight_ui_kit.dart';

/// Insight pattern and food components.

class InsightPatternPill extends StatelessWidget {
  const InsightPatternPill({super.key, required this.title, this.subtitle, this.badge, this.emoji, this.imageUrl, this.imageName, this.onTap});

  final String title;
  final String? subtitle;
  final String? badge;
  final String? emoji;
  final String? imageUrl;
  final VoidCallback? onTap;

  /// Clean food name for the image-utils lookup (the display [title] often
  /// carries suffixes like "• Trigger food" that would poison the keyword).
  final String? imageName;

  @override
  Widget build(BuildContext context) {
    final t = context.insightTheme;
    return InsightCard(
      onTap: onTap,
      padding: EdgeInsets.all(10.w),
      radius: InsightTheme.radiusTile,
      background: t.cardSubtle,
      child: Row(
        children: [
          InsightFoodImage(name: imageName ?? title, userImageUrl: imageUrl, emoji: emoji, size: 32, tone: InsightTone.neutral),
          Gap.w10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: InsightUiKit.text(context, size: 12, weight: FontWeight.w600),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  Gap.h2,
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: InsightUiKit.text(context, size: 11, color: t.textTertiary),
                  ),
                ],
                if (badge != null && badge!.isNotEmpty) ...[Gap.h4, InsightBadge(badge!, tone: InsightTone.success, size: 8.5)],
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 16.w, color: t.textTertiary),
        ],
      ),
    );
  }
}

class InsightFoodItemData {
  const InsightFoodItemData({required this.name, this.count, this.delta, this.emoji, this.imageUrl, this.userImageUrl, this.deltaColor});

  final String name;
  final String? count;
  final String? delta;

  /// Delta chip colour (e.g. success for "+3").
  final Color? deltaColor;
  final String? emoji;
  final String? imageUrl;
  final String? userImageUrl;
}

