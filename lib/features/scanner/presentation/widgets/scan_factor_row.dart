part of 'scan_summary_sheet.dart';

/// Scan health-factor row component.

class _FactorRow extends StatefulWidget {
  const _FactorRow({required this.factor});
  final _HealthFactor factor;

  @override
  State<_FactorRow> createState() => _FactorRowState();
}

class _FactorRowState extends State<_FactorRow> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final factor = widget.factor;

    return Column(
      children: [
        InkWell(
          onTap: factor.expandable ? () => setState(() => _isExpanded = !_isExpanded) : null,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Row(
              children: [
                Icon(factor.icon, size: 24.sp, color: scheme.textPrimary.withAlpha(200)),
                Gap.w16,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        factor.label,
                        style: context.body.copyWith(fontWeight: FontWeight.w700, color: scheme.textPrimary),
                      ),
                      Text(factor.description, style: context.bodySm.copyWith(color: scheme.textSecondary, height: 1.4)),
                    ],
                  ),
                ),
                if (factor.value.isNotEmpty) Text(factor.value, style: context.labelBold.copyWith(color: scheme.textSecondary, fontSize: 12.sp)),
                Gap.w12,
                if (factor.useTick)
                  Icon(AppIcons.check, size: 16.sp, color: factor.color)
                else
                  Container(
                    width: 12.sp,
                    height: 12.sp,
                    decoration: BoxDecoration(color: factor.color, shape: BoxShape.circle),
                  ),
                if (factor.expandable) ...[Gap.w8, Icon(_isExpanded ? AppIcons.chevronUp : AppIcons.chevronDown, size: 16.sp, color: scheme.textMuted)],
              ],
            ),
          ),
        ),
        if (_isExpanded)
          Padding(
            padding: EdgeInsets.only(left: 40.w, bottom: 12.h),
            child: factor.details.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: factor.details.map((detail) {
                      final concern = factor.detailsArePlain ? null : AdditiveConcernDb.resolve(detail);
                      final label = factor.detailsArePlain ? detail : concern!.displayTitle;
                      final dotColor = factor.detailsArePlain ? factor.color : _getConcernColor(concern!.level, scheme);
                      return Padding(
                        padding: EdgeInsets.only(bottom: 6.h),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                            ),
                            Gap.w10,
                            Expanded(
                              child: Text(label, style: context.bodySm.copyWith(color: scheme.textPrimary)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                : Text(factor.longDescription, style: context.bodySm.copyWith(color: scheme.textSecondary, height: 1.5)),
          ),
      ],
    );
  }

  Color _getConcernColor(AdditiveConcernLevel level, AppColorScheme scheme) {
    switch (level) {
      case AdditiveConcernLevel.higher:
        return scheme.error;
      case AdditiveConcernLevel.moderate:
        return scheme.warning;
      case AdditiveConcernLevel.low:
        return scheme.success;
      case AdditiveConcernLevel.unknown:
        return scheme.textMuted;
    }
  }
}
