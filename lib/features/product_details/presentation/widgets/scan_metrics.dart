part of 'scan_result_widgets.dart';

/// Nutrient metrics and factor presentation components.

class ScanMetricsRow extends StatelessWidget {
  const ScanMetricsRow({super.key, required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final nova = NovaGroup.fromGroup(scanData.novaGroup);
    return Row(
      children: [
        Expanded(
          child: _MetricCard(icon: _impactIcon, color: _impactColor(context), value: _impactWord, label: 'Impact'),
        ),
        Gap.w6,
        Expanded(
          child: _MetricCard(icon: AppIcons.sparkles, color: _novaColor(context, nova), value: _novaWord(nova), label: nova == null ? 'Nova' : 'Nova ${nova.group}'),
        ),
        Gap.w6,
        Expanded(
          child: _MetricCard(icon: AppIcons.shield, color: _barrierColor(context), value: _barrierWord, label: 'Barrier'),
        ),
        Gap.w6,
        Expanded(
          child: _MetricCard(icon: AppIcons.droplet, color: _processingColor(context, nova), value: _processingWord(nova), label: 'Food Type'),
        ),
      ],
    );
  }

  IconData get _impactIcon {
    switch (scanData.impactType) {
      case ImpactType.positive:
        return AppIcons.heart;
      case ImpactType.negative:
        return AppIcons.alertCircle;
      case ImpactType.neutral:
        return AppIcons.sparkles;
    }
  }

  String get _impactWord {
    switch (scanData.impactType) {
      case ImpactType.positive:
        return 'Gut Friendly';
      case ImpactType.negative:
        return 'Gut Heavy';
      case ImpactType.neutral:
        return 'Moderate';
    }
  }

  String _novaWord(NovaGroup? nova) {
    if (nova == null) return '–';
    switch (nova.group) {
      case 1:
        return 'Unprocessed';
      case 2:
        return 'Lightly Processed';
      case 3:
        return 'Processed';
      case 4:
        return 'Ultra-Processed';
      default:
        return nova.label;
    }
  }

  Color _impactColor(BuildContext context) {
    final t = context.bentoTheme;
    switch (scanData.impactType) {
      case ImpactType.positive:
        return t.positive;
      case ImpactType.negative:
        return t.negative;
      case ImpactType.neutral:
        return AppPalette.orange;
    }
  }

  Color _novaColor(BuildContext context, NovaGroup? nova) {
    final t = context.bentoTheme;
    if (nova == null) return AppPalette.orange;
    switch (nova.group) {
      case 1:
        return t.positive;
      case 2:
        return const Color(0xFF0284C7);
      case 3:
        return AppPalette.orange;
      case 4:
        return t.negative;
      default:
        return AppPalette.orange;
    }
  }

  String get _barrierWord {
    final s = scanData.score;
    if (s >= 70) return 'Gut Support';
    if (s >= 50) return 'Steady';
    if (s >= 30) return 'Sensitive';
    return 'At risk';
  }

  Color _barrierColor(BuildContext context) {
    final t = context.bentoTheme;
    final s = scanData.score;
    if (s >= 70) return t.positive;
    if (s >= 50) return const Color(0xFF2563EB);
    if (s >= 30) return AppPalette.orange;
    return t.negative;
  }

  String _processingWord(NovaGroup? nova) {
    if (nova == null) return 'Unknown';
    switch (nova.group) {
      case 1:
        return 'Whole Food';
      case 2:
        return 'Some Processing';
      case 3:
        return 'Processed';
      case 4:
        return 'Heavy Processing';
      default:
        return nova.label;
    }
  }

  Color _processingColor(BuildContext context, NovaGroup? nova) {
    final t = context.bentoTheme;
    if (nova == null) return t.textTertiary;
    switch (nova.group) {
      case 1:
        return t.positive;
      case 2:
        return const Color(0xFF0284C7);
      case 3:
        return const Color(0xFF7C3AED);
      case 4:
        return const Color(0xFFE11D48);
      default:
        return t.textTertiary;
    }
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.color, required this.value, required this.label});

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNumber = RegExp(r'^\d+$').hasMatch(value);
    final fontSize = isNumber ? 16.sp : 10.5.sp;

    final bgStart = color.withValues(alpha: isDark ? 0.22 : 0.12);
    final bgEnd = color.withValues(alpha: isDark ? 0.12 : 0.04);

    return Container(
      height: 100.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [bgStart, bgEnd]),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.12 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.28 : 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18.sp, color: color),
          ),
          Gap.h2,
          SizedBox(
            height: 28.h,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                value,
                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: fontSize, fontWeight: FontWeight.w900, height: 1.1, color: color),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Gap.h2,
          Text(
            label,
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: t.textSecondary),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ScanFactor {
  _ScanFactor({required this.icon, required this.iconColor, required this.title, required this.subtitle, this.valueText, this.badgeColor, this.trailing, this.onTap});

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? valueText;
  final Color? badgeColor;
  final Widget? trailing;
  final VoidCallback? onTap;
}

Widget _buildModernFactorCard(BuildContext context, _ScanFactor item, {required bool isPositive}) {
  final t = context.bentoTheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final accentColor = item.badgeColor ?? item.iconColor;
  final cardShade = accentColor.withValues(alpha: isDark ? 0.16 : 0.08);
  final iconBgColor = accentColor.withValues(alpha: isDark ? 0.28 : 0.16);
  final valueBgColor = accentColor.withValues(alpha: isDark ? 0.25 : 0.14);

  final content = Row(
    children: [
      Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
        child: Icon(item.icon, size: 16.sp, color: accentColor),
      ),
      Gap.w12,
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w700, color: t.textPrimary, height: 1.2),
            ),
            Gap.h2,
            Text(
              item.subtitle,
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w400, color: t.textSecondary, height: 1.3),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      if (item.valueText != null) ...[
        Gap.w8,
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(color: valueBgColor, borderRadius: BorderRadius.circular(8.r)),
          child: Text(
            item.valueText!,
            style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w800, color: accentColor),
          ),
        ),
      ],
      if (item.onTap != null || item.trailing != null) ...[
        Gap.w8,
        item.trailing ??
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isDark ? 0.22 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(AppIcons.chevronRight, size: 14.sp, color: accentColor),
            ),
      ],
    ],
  );

  return Container(
    margin: EdgeInsets.only(bottom: 8.h),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
          decoration: BoxDecoration(color: cardShade, borderRadius: BorderRadius.circular(14.r)),
          child: content,
        ),
      ),
    ),
  );
}

/// 🌟 Section 4: "What works for you" (positive factors).
