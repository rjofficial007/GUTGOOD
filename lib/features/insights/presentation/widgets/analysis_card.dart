import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';

class AnalysisCard extends StatelessWidget {
  const AnalysisCard({super.key, required this.metric, required this.label, required this.icon, required this.glowColor, required this.items, this.onTap, this.headerColor});

  final String metric;
  final String label;
  final IconData icon;
  final Color glowColor;
  final List<AnalysisItem> items;
  final VoidCallback? onTap;
  final Color? headerColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = context.appColorScheme;

    final cardColor = scheme.cardBackground;
    final borderColor = scheme.borderSubtle;
    final textColor = scheme.textPrimary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppSizes.r24),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: scheme.surfaceSubtle,
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label.toUpperCase(), style: context.captionBold.copyWith(color: scheme.textSecondary)),
                Icon(icon, color: scheme.textSecondary, size: 14),
              ],
            ),
            Gap.h24,
            Text(
              metric,
              style: context.headingMd.copyWith(color: textColor, fontWeight: FontWeight.w900, letterSpacing: -1.5, height: 1, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
            Gap.h12,
            ...items.map(
              (t) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _AnalysisTaskRow(data: t, textColor: textColor, borderColor: borderColor),
              ),
            ),
          ],
        ),
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

    final isLong = (data.subtitle?.length ?? 0) > 50 || data.title.length > 35;
    final radius = isLong ? 24.0 : 50.0;

    final circleBgColor = data.color ?? textColor;

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
              width: 36,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: circleBgColor.withAlpha(26),
                border: Border.all(color: circleBgColor.withAlpha(51), width: 1.5),
              ),
              child: Center(
                child: data.leading ?? (data.icon != null ? Icon(data.icon, size: 14, color: circleBgColor) : (checked ? Icon(AppIcons.check, size: 14, color: circleBgColor) : null)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data.title,
                    style: context.labelBold.copyWith(color: textColor),
                  ),
                  if (data.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle!,
                      style: context.label.copyWith(color: textColor.withAlpha(127)),
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
  const AnalysisItem({required this.title, this.subtitle, this.isDone = false, this.icon, this.onTap, this.color, this.leading});

  final String title;
  final String? subtitle;
  final bool isDone;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? color;
  final Widget? leading;
}
