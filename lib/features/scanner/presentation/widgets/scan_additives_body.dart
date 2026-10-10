part of 'scan_detail_sections.dart';

/// Scan additives body.

class _AdditivesBody extends StatelessWidget {
  const _AdditivesBody({required this.product});

  final OffProduct product;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final concerns = product.additiveConcerns;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < concerns.length; i++) ...[if (i > 0) Gap.h12, _additiveRow(context, concerns[i], scheme)],
        Gap.h8,
        Text('Fewer additives usually means less ultra-processing.', style: context.bodySm.copyWith(color: scheme.textMuted)),
      ],
    );
  }

  Widget _additiveRow(BuildContext context, AdditiveConcern c, AppColorScheme scheme) {
    final colors = AdditiveLevelColors.of(context, c.level);
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(AppSizes.p6),
          decoration: BoxDecoration(color: colors.iconBackground, shape: BoxShape.circle),
          child: Icon(AdditiveLevelColors.iconFor(c.level), size: 14.sp, color: colors.accent),
        ),
        Gap.w12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.displayTitle, style: context.labelBold.copyWith(color: scheme.textPrimary, fontSize: 12.sp)),
              if (c.name.isNotEmpty && c.name.toLowerCase() != c.displayTitle.toLowerCase()) Text(c.name, style: context.bodySm, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: 3.0.h),
          decoration: BoxDecoration(color: colors.pillBackground, borderRadius: BorderRadius.circular(AppSizes.r100)),
          child: Text(
            c.level.label,
            style: context.labelBold.copyWith(color: colors.accent, fontSize: 11.5.sp, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Allergens & traces
// -----------------------------------------------------------------------------

