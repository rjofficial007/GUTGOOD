import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';

class DashboardEntrance extends StatefulWidget {
  const DashboardEntrance({super.key, required this.child, required this.delay});
  final Widget child;
  final int delay;

  @override
  State<DashboardEntrance> createState() => _DashboardEntranceState();
}

class _DashboardEntranceState extends State<DashboardEntrance> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _offset = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: SlideTransition(position: _offset, child: widget.child),
  );
}

class DashboardCard extends StatelessWidget {
  const DashboardCard({super.key, required this.child, this.footer, this.onFooterTap, this.footerLabel});
  final Widget child;
  final Widget? footer;
  final VoidCallback? onFooterTap;
  final String? footerLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: scheme.textPrimary.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                  border: Border(top: BorderSide(color: scheme.border.withValues(alpha: 0.5))),
                ),
                child:
                    footer ??
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          footerLabel ?? 'View All',
                          style: context.caption.copyWith(fontWeight: FontWeight.bold, color: scheme.textPrimary),
                        ),
                        Icon(AppIcons.chevronRight, color: scheme.textPrimary, size: 16.0.w),
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
  const DashboardDetailItem({super.key, required this.title, required this.subtitle, required this.icon, required this.color, this.onTap});
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.0.w),
          decoration: BoxDecoration(
            color: context.appColorScheme.elevatedSurface,
            borderRadius: BorderRadius.circular(8.0.r),
            border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
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
                style: context.caption.copyWith(fontSize: 10.0.sp, color: context.appColorScheme.textMuted, height: 1.1),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class GutDashboardSection extends StatelessWidget {
  const GutDashboardSection({super.key, required this.title, required this.subtitle, required this.visualization, required this.items, this.footerLabel, this.onFooterTap, this.titleColor});
  final String title;
  final String subtitle;
  final Widget visualization;
  final List<Widget> items;
  final String? footerLabel;
  final VoidCallback? onFooterTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) => DashboardCard(
    onFooterTap: onFooterTap,
    footerLabel: footerLabel,
    child: Padding(
      padding: EdgeInsets.all(AppSizes.p20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: context.bodyBold.copyWith(fontSize: AppSizes.s16, fontWeight: FontWeight.w900, letterSpacing: -1, color: titleColor ?? context.appColorScheme.textPrimary),
                ),
                Text(
                  subtitle.toUpperCase(),
                  style: context.caption.copyWith(color: context.appColorScheme.textMuted, fontSize: AppSizes.s12),
                ),
                Gap.h24,
                visualization,
              ],
            ),
          ),
          Gap.w16,
          Expanded(flex: 5, child: Column(children: items)),
        ],
      ),
    ),
  );
}

class DashboardVisualizationBar extends StatelessWidget {
  const DashboardVisualizationBar({super.key, required this.ratio, required this.label});
  final double ratio;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      GutProgressBar(ratio: ratio),
      Gap.h12,
      Text(
        label,
        style: context.caption.copyWith(fontSize: 10.0.sp, color: context.appColorScheme.textMuted),
      ),
    ],
  );
}

class GutProgressBar extends StatelessWidget {
  const GutProgressBar({super.key, required this.ratio, this.height = 8.0, this.animate = true});
  final double ratio;
  final double height;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final trackColor = Theme.of(context).brightness == Brightness.light ? AppPalette.gray100 : AppPalette.gray800;

    final content = Container(
      height: height.h,
      width: double.infinity,
      decoration: BoxDecoration(color: trackColor, borderRadius: BorderRadius.circular(100)),
      child: LayoutBuilder(
        builder: (context, constraints) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: ratio.clamp(0.0, 1.0)),
          duration: animate ? const Duration(milliseconds: 1200) : Duration.zero,
          curve: Curves.easeOutExpo,
          builder: (context, value, _) => FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(color: context.appColorScheme.textPrimary, borderRadius: BorderRadius.circular(100)),
            ),
          ),
        ),
      ),
    );

    return content;
  }
}

class DashboardIconVisualization extends StatelessWidget {
  const DashboardIconVisualization({super.key, required this.icon, this.color});
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(AppSizes.p12),
    decoration: BoxDecoration(
      color: context.appColorScheme.elevatedSurface,
      shape: BoxShape.circle,
      border: Border.all(color: context.appColorScheme.border),
    ),
    child: Icon(icon, color: color ?? context.appColorScheme.textPrimary, size: AppSizes.icon32),
  );
}

class TopPerformersVisualization extends StatelessWidget {
  const TopPerformersVisualization({super.key});

  @override
  Widget build(BuildContext context) => const DashboardIconVisualization(icon: AppIcons.trophy);
}

class CautionRiskIcon extends StatelessWidget {
  const CautionRiskIcon({super.key, required this.isSafe});
  final bool isSafe;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: 1.0),
    duration: const Duration(milliseconds: 800),
    curve: Curves.elasticOut,
    builder: (context, value, child) => Transform.scale(scale: value, child: child),
    child: DashboardIconVisualization(icon: isSafe ? AppIcons.shieldCheck : AppIcons.alertCircle),
  );
}

class SheetHeroSection extends StatelessWidget {
  const SheetHeroSection({super.key, required this.title, required this.subtitle, required this.color, required this.icon});
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        padding: EdgeInsets.all(20.0.w),
        decoration: BoxDecoration(
          color: context.appColorScheme.elevatedSurface,
          shape: BoxShape.circle,
          border: Border.all(color: context.appColorScheme.border),
        ),
        child: Icon(icon, color: context.appColorScheme.textPrimary, size: 40.0.w),
      ),
      Gap.h16,
      Text(
        title,
        style: context.bodyBold.copyWith(fontSize: 40.0.sp, fontWeight: FontWeight.w900, letterSpacing: -1),
      ),
      Text(subtitle, style: context.eyebrow.copyWith(color: context.appColorScheme.textMuted, letterSpacing: 1.5)),
    ],
  );
}

class SheetSectionHeader extends StatelessWidget {
  const SheetSectionHeader({super.key, required this.title, required this.color});
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: 10.0.h),
    child: Row(
      children: [
        Container(
          width: 4.0.w,
          height: 16.0.h,
          decoration: BoxDecoration(color: context.appColorScheme.textPrimary, borderRadius: BorderRadius.circular(2.0.r)),
        ),
        Gap.w12,
        Text(
          title.toUpperCase(),
          style: context.bodyBold.copyWith(fontSize: 13.0.sp, color: context.appColorScheme.textPrimary, letterSpacing: 1.0),
        ),
      ],
    ),
  );
}
