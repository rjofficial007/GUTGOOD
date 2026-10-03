part of 'bento_widgets.dart';

class BentoCta extends StatelessWidget {
  const BentoCta({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    return SizedBox(
      width: double.infinity,
      height: BentoMetrics.ctaHeight.w,
      child: Material(
        color: t.ctaBackground,
        borderRadius: BorderRadius.circular(BentoMetrics.ctaRadius.w),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(BentoMetrics.ctaRadius.w),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: InsightBentoTheme.fontFamily,
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.27, // .02em
                color: t.ctaForeground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
