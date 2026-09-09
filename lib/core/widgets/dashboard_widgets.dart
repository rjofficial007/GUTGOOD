import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
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
          style: context.label.copyWith(color: context.appColorScheme.textPrimary, fontWeight: FontWeight.w700, letterSpacing: 1.0),
        ),
      ],
    ),
  );
}
