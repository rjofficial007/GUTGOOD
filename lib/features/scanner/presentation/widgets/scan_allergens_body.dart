part of 'scan_detail_sections.dart';

/// Scan allergens body.

class _AllergensBody extends StatelessWidget {
  const _AllergensBody({required this.product});

  final OffProduct product;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((product.allergens ?? const []).isNotEmpty) ...[
          Row(
            children: [
              Icon(AppIcons.alertTriangle, size: 14.sp, color: scheme.error),
              Gap.w6,
              Text('Contains', style: context.captionBold),
            ],
          ),
          Gap.h8,
          Wrap(
            spacing: AppSizes.p8,
            runSpacing: AppSizes.p8,
            children: [for (final allergen in product.allergens!) _tagChip(context, allergen, color: scheme.error, background: scheme.softError)],
          ),
        ],
        if ((product.tracesTags ?? const []).isNotEmpty) ...[
          if ((product.allergens ?? const []).isNotEmpty) Gap.h16,
          Row(
            children: [
              Icon(AppIcons.info, size: 14.sp, color: scheme.warning),
              Gap.w6,
              Text('May contain', style: context.captionBold),
            ],
          ),
          Gap.h8,
          Wrap(
            spacing: AppSizes.p8,
            runSpacing: AppSizes.p8,
            children: [for (final trace in product.tracesTags!) _tagChip(context, trace, color: scheme.warning, background: scheme.softWarning)],
          ),
        ],
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Labels & availability
// -----------------------------------------------------------------------------

