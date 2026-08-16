import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';

class AnalysisCard extends StatelessWidget {
  const AnalysisCard({super.key, required this.metric, required this.label, required this.icon, required this.glowColor, required this.items, this.onTap});

  final String metric;
  final String label;
  final IconData icon;
  final Color glowColor;
  final List<AnalysisItem> items;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = context.appColorScheme;

    // Matched exactly with Insight History Tile (elevatedSurface + 0.5 border)
    final cardColor = scheme.elevatedSurface;
    final borderColor = scheme.border.withValues(alpha: 0.5);
    final textColor = scheme.textPrimary;
    final invertedColor = scheme.cardBackground;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.r32),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
      child: Column(
        children: [
          // Header Section (Dynamic Height)
          Container(
            constraints: const BoxConstraints(minHeight: 100),
            decoration: BoxDecoration(
              color: scheme.border.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: borderColor),
            ),
            padding: const EdgeInsets.fromLTRB(20, 18, 18, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        metric,
                        style: context.displaySm.copyWith(color: textColor, fontWeight: FontWeight.w900, letterSpacing: -1.5, height: 1, fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                      Gap.h8,
                      Text(
                        label.toUpperCase(),
                        style: context.eyebrow.copyWith(color: textColor.withValues(alpha: 0.6), fontWeight: FontWeight.w900, letterSpacing: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: textColor, shape: BoxShape.circle),
                  child: Icon(icon, color: invertedColor, size: 19),
                ),
              ],
            ),
          ),
          // ...
          ...items.map(
            (t) => Padding(
              padding: const EdgeInsets.only(top: 5),
              child: _AnalysisTaskRow(data: t, textColor: textColor, borderColor: borderColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisTaskRow extends StatelessWidget {
  const _AnalysisTaskRow({required this.data, required this.textColor, required this.borderColor});

  final AnalysisItem data;
  final Color textColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final checked = data.isDone;

    // Smart Radius Heuristic: If it has a subtitle or very long title, it's likely 2+ lines.
    // Use a smaller radius (24) for multi-line items and a pill shape (50) for single lines.
    final isLong = data.subtitle!.length > 50 || data.title.length > 35;
    final radius = isLong ? 24.0 : 50.0;

    // If icon is provided, use it. If checked, default to check icon.
    final iconData = data.icon ?? (checked ? AppIcons.check : null);

    // Determine the background color of the circle (monochromatic theme)
    final circleBgColor = textColor;
    final circleBorderColor = textColor;
    final iconColor = context.appColorScheme.cardBackground;

    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: context.appColorScheme.elevatedSurface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: circleBgColor,
                border: Border.all(color: circleBorderColor, width: 1.5),
              ),
              child: iconData != null ? Icon(iconData, size: 14, color: iconColor) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data.title,
                    style: context.bodySm.copyWith(fontWeight: FontWeight.w600, color: textColor),
                  ),
                  if (data.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle!,
                      style: context.caption.copyWith(color: textColor.withValues(alpha: 0.5), fontSize: 11.sp),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class AnalysisItem {
  const AnalysisItem({required this.title, this.subtitle, this.isDone = false, this.icon, this.onTap});

  final String title;
  final String? subtitle;
  final bool isDone;
  final IconData? icon;
  final VoidCallback? onTap;
}
