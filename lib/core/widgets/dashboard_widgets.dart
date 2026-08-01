import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';

import '../constants/app_sizes.dart';

class DashboardEntrance extends StatelessWidget {
  final Widget child;
  final int delay;

  const DashboardEntrance({super.key, required this.child, required this.delay});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class DashboardCard extends StatelessWidget {
  final Widget child;
  final Widget? footer;
  final VoidCallback? onFooterTap;
  final String? footerLabel;

  const DashboardCard({
    super.key,
    required this.child,
    this.footer,
    this.onFooterTap,
    this.footerLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColorScheme.cardBackground,
        borderRadius: BorderRadius.circular(28.0.r),
        border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          if (footer != null || onFooterTap != null)
            GestureDetector(
              onTap: onFooterTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.0.w, vertical: 12.0.h),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: context.appColorScheme.border.withValues(alpha: 0.5))),
                ),
                child: footer ??
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          footerLabel ?? 'View All',
                          style: context.caption.copyWith(fontWeight: FontWeight.bold, color: context.appColorScheme.textPrimary),
                        ),
                        Row(
                          children: [
                            Icon(AppIcons.chevronLeft, color: context.appColorScheme.textMuted.withValues(alpha: 0.5), size: 16.0.w),
                            Gap.w8,
                            Icon(AppIcons.chevronRight, color: context.appColorScheme.textPrimary, size: 16.0.w),
                          ],
                        ),
                      ],
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class DashboardDetailItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const DashboardDetailItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.0.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.0.r),
          ),
          child: Icon(icon, color: color, size: 14.0.w),
        ),
        Gap.w10,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: context.bodyBold.copyWith(fontSize: 12.0.sp, height: 1.1),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: context.caption.copyWith(
                  fontSize: 10.0.sp,
                  color: context.appColorScheme.textMuted,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DashboardVisualizationBar extends StatelessWidget {
  final double ratio;
  final String label;

  const DashboardVisualizationBar({super.key, required this.ratio, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 12.0.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppPalette.gray100,
            borderRadius: BorderRadius.circular(6.0.r),
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: ratio.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutExpo,
            builder: (context, value, _) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppPalette.green500, AppPalette.lime],
                    ),
                    borderRadius: BorderRadius.circular(6.0.r),
                  ),
                ),
              );
            },
          ),
        ),
        Gap.h12,
        Text(
          label,
          style: context.caption.copyWith(fontSize: 10.0.sp, color: context.appColorScheme.textMuted),
        ),
      ],
    );
  }
}

class SheetHeroSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;

  const SheetHeroSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20.0.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 40.0.w),
        ),
        Gap.h16,
        Text(
          title,
          style: context.bodyBold.copyWith(fontSize: 40.0.sp, fontWeight: FontWeight.w900, letterSpacing: -1),
        ),
        Text(
          subtitle,
          style: context.eyebrow.copyWith(color: context.appColorScheme.textMuted, letterSpacing: 1.5),
        ),
      ],
    );
  }
}

class SheetSectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const SheetSectionHeader({super.key, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.0.h),
      child: Row(
        children: [
          Container(
            width: 4.0.w,
            height: 16.0.h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2.0.r),
            ),
          ),
          Gap.w12,
          Text(
            title.toUpperCase(),
            style: context.bodyBold.copyWith(fontSize: 13.0.sp, color: color, letterSpacing: 1.0),
          ),
        ],
      ),
    );
  }
}
