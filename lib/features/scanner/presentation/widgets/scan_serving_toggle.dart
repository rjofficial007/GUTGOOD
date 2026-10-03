part of 'scan_detail_sections.dart';

/// Scan serving toggle component.

class _ServingToggle extends StatelessWidget {
  const _ServingToggle({required this.per100g, required this.perServing, required this.perServingActive, required this.onChanged});

  final String per100g;
  final String perServing;
  final bool perServingActive;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.0.w),
      decoration: BoxDecoration(color: scheme.surfaceSubtle, borderRadius: BorderRadius.circular(AppSizes.r100)),
      child: Row(
        children: [
          _option(context, label: per100g, active: !perServingActive, onTap: () => onChanged(false)),
          _option(context, label: perServing, active: perServingActive, onTap: () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _option(BuildContext context, {required String label, required bool active, required VoidCallback onTap}) {
    final scheme = context.appColorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(vertical: AppSizes.p8),
          decoration: BoxDecoration(color: active ? scheme.elevatedSurface : Colors.transparent, borderRadius: BorderRadius.circular(AppSizes.r100)),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.captionBold.copyWith(color: active ? scheme.textPrimary : scheme.textMuted, fontSize: 12.sp),
          ),
        ),
      ),
    );
  }
}
