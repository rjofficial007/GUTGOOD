import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';

class NeonGlowCard extends StatelessWidget {
  const NeonGlowCard({
    super.key,
    required this.metric,
    required this.label,
    required this.icon,
    required this.glowColor,
    required this.items,
    this.onTap,
  });

  final String metric;
  final String label;
  final IconData icon;
  final Color glowColor;
  final List<NeonGlowItem> items;
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: Column(
        children: [
          // Header Section
          Container(
            height: 142,
            decoration: BoxDecoration(
              color: scheme.border.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: borderColor),
            ),
            padding: const EdgeInsets.fromLTRB(20, 18, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        metric,
                        style: context.displaySm.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                          height: 1,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: textColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: invertedColor, size: 19),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: context.eyebrow.copyWith(
                        color: textColor.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 28,
                      height: 1,
                      color: textColor.withValues(alpha: 0.1),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.analysisBasedOnLogs,
                  style: context.caption.copyWith(
                    color: textColor.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TaskRow(
                  data: t,
                  textColor: textColor,
                  borderColor: borderColor,
                ),
              )),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.data,
    required this.textColor,
    required this.borderColor,
  });

  final NeonGlowItem data;
  final Color textColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final checked = data.isDone;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.appColorScheme.elevatedSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: checked ? textColor : Colors.transparent,
              border: Border.all(
                color: checked ? textColor : textColor.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: checked 
                ? Icon(Icons.check_rounded, size: 14, color: context.appColorScheme.cardBackground) 
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.bodySm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                if (data.subtitle != null)
                  Text(
                    data.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.caption.copyWith(
                      color: textColor.withValues(alpha: 0.5),
                      fontSize: 11.sp,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: textColor.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

class NeonGlowItem {
  const NeonGlowItem({
    required this.title,
    this.subtitle,
    this.isDone = false,
  });
  final String title;
  final String? subtitle;
  final bool isDone;
}
