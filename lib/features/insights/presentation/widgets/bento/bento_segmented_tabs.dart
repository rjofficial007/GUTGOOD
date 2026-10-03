part of 'bento_widgets.dart';

/// Bento segmented-tab presentation component.

class BentoSegmentedTabs extends StatelessWidget {
  const BentoSegmentedTabs({super.key, required this.tabs, required this.selectedIndex, required this.onChanged, this.trailingLabel});

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 10.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // The strip scrolls rather than overflows, so long or numerous labels
          // can never push the trailing action off-screen.
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < tabs.length; i++) ...[
                    if (i > 0) SizedBox(width: 18.w),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(i),
                      child: Container(
                        padding: EdgeInsets.only(bottom: 6.w),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: i == selectedIndex ? t.textPrimary : Colors.transparent, width: 2)),
                        ),
                        child: Text(
                          tabs[i],
                          style: TextStyle(
                            fontFamily: InsightBentoTheme.fontFamily,
                            fontSize: 13.5.sp,
                            fontWeight: i == selectedIndex ? FontWeight.w700 : FontWeight.w500,
                            color: i == selectedIndex ? t.textPrimary : t.textQuaternary,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (trailingLabel != null) SizedBox(width: 18.w),
          if (trailingLabel != null)
            Padding(
              padding: EdgeInsets.only(bottom: 6.w),
              child: Text(
                trailingLabel!,
                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w500, color: t.textQuaternary, height: 1.2),
              ),
            ),
        ],
      ),
    );
  }
}

/// One food entry inside the span-2 "Top Foods" card (`.food-tile`).
