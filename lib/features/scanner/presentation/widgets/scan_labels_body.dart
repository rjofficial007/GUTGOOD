part of 'scan_detail_sections.dart';

/// Scan labels body.

class _LabelsBody extends StatelessWidget {
  const _LabelsBody({required this.product});

  final OffProduct product;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((product.labels ?? const []).isNotEmpty)
          Wrap(
            spacing: AppSizes.p8,
            runSpacing: AppSizes.p8,
            children: [for (final label in product.labels!) _tagChip(context, label.replaceAll('-', ' '), color: scheme.info, background: scheme.softInfo)],
          ),
        if ((product.countries ?? '').isNotEmpty) ...[
          if ((product.labels ?? const []).isNotEmpty) Gap.h12,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(AppIcons.globe, size: 14.sp, color: scheme.textMuted),
              Gap.w6,
              Expanded(child: Text('Sold in: ${product.countries}', style: context.bodySm)),
            ],
          ),
        ],
        if ((product.barcode ?? '').isNotEmpty || (product.quantity ?? '').isNotEmpty) ...[
          Gap.h12,
          Wrap(
            spacing: AppSizes.p12,
            runSpacing: AppSizes.p4,
            children: [
              if ((product.quantity ?? '').isNotEmpty) _miniMeta(context, AppIcons.scale, product.quantity!),
              if ((product.barcode ?? '').isNotEmpty) _miniMeta(context, AppIcons.barcode, product.barcode!),
              if ((product.servingSize ?? '').isNotEmpty) _miniMeta(context, AppIcons.utensils, 'Serving ${product.servingSize}'),
            ],
          ),
        ],
      ],
    );
  }

  Widget _miniMeta(BuildContext context, IconData icon, String text) {
    final scheme = context.appColorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13.sp, color: scheme.textMuted),
        Gap.w4,
        Text(text, style: context.bodySm.copyWith(color: scheme.textSecondary)),
      ],
    );
  }
}

Widget _tagChip(BuildContext context, String tag, {required Color color, required Color background}) => Container(
  padding: EdgeInsets.symmetric(horizontal: AppSizes.p10, vertical: AppSizes.p6),
  decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppSizes.r100)),
  child: Text(
    tag,
    style: context.captionBold.copyWith(color: color, fontSize: 12.sp),
  ),
);

// -----------------------------------------------------------------------------
// Shared: segmented Per 100 g ↔ Per serving toggle
// -----------------------------------------------------------------------------

