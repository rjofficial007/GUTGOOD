part of 'scan_detail_sections.dart';

/// Expandable scan-detail tile component.

class _DetailTile extends StatefulWidget {
  const _DetailTile({required this.icon, required this.title, required this.peek, required this.body});

  final IconData icon;
  final String title;
  final String peek;
  final Widget body;

  @override
  State<_DetailTile> createState() => _DetailTileState();
}

class _DetailTileState extends State<_DetailTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Row(
              children: [
                Icon(widget.icon, size: 24.sp, color: scheme.textPrimary.withAlpha(200)),
                Gap.w16,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: context.body.copyWith(fontWeight: FontWeight.w700, color: scheme.textPrimary),
                      ),
                      Text(
                        widget.peek,
                        style: context.caption.copyWith(color: scheme.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Gap.w12,
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(AppIcons.chevronDown, size: 16.sp, color: scheme.textMuted),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: _DetailCard(child: widget.body),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Soft rounded card wrapping the expanded section content.
