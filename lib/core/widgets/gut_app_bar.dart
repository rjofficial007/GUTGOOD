import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_assets.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';

class GutAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GutAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.showBrandingIcon = false,
    this.centerTitle = false,
    this.elevation = 0,
    this.backgroundColor,
    this.automaticallyImplyLeading = true,
    this.streak,
  });
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBrandingIcon;
  final bool? centerTitle;
  final double? elevation;
  final Color? backgroundColor;
  final bool automaticallyImplyLeading;
  final int? streak;

  @override
  Widget build(BuildContext context) => AppBar(
    title: titleWidget ?? _buildTitle(context),
    actions: actions,
    leading: leading,
    centerTitle: centerTitle,
    elevation: elevation,
    backgroundColor: backgroundColor ?? context.appColorScheme.cardBackground.withAlpha(204),
    automaticallyImplyLeading: automaticallyImplyLeading,
    flexibleSpace: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(color: AppPalette.transparent),
      ),
    ),
  );

  Widget _buildTitle(BuildContext context) {
    if (title == null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showBrandingIcon) ...[Image.asset(AppAssets.appIconBg, height: 24.0.w, width: 24.0.w, color: context.appColorScheme.textPrimary), Gap.w10],
        Text(title!.toUpperCase(), style: context.title.copyWith(letterSpacing: 0.1)),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight.h);
}

class GutSliverAppBar extends StatelessWidget {
  const GutSliverAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.showBrandingIcon = false,
    this.centerTitle = false,
    this.floating = true,
    this.pinned = true,
    this.snap = true,
    this.forceElevated = false,
    this.automaticallyImplyLeading = true,
    this.streak,
  });
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBrandingIcon;
  final bool? centerTitle;
  final bool floating;
  final bool pinned;
  final bool snap;
  final bool forceElevated;
  final bool automaticallyImplyLeading;
  final int? streak;

  @override
  Widget build(BuildContext context) => SliverAppBar(
    title: titleWidget ?? _buildTitle(context),
    actions: actions,
    leading: leading,
    centerTitle: centerTitle,
    floating: floating,
    pinned: pinned,
    snap: snap,
    elevation: 0,
    forceElevated: forceElevated,
    backgroundColor: context.appColorScheme.cardBackground.withAlpha(204),
    automaticallyImplyLeading: automaticallyImplyLeading,
    flexibleSpace: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(color: AppPalette.transparent),
      ),
    ),
  );

  Widget _buildTitle(BuildContext context) {
    if (title == null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showBrandingIcon) ...[Image.asset(AppAssets.appIconBg, height: 24.0.w, width: 24.0.w, color: context.appColorScheme.textPrimary), Gap.w10],
        // Flexible so a long title ellipsises instead of overflowing the bar on
        // narrow devices; the streak badge keeps its own width.
        Flexible(
          child: Text(
            title!.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.title.copyWith(letterSpacing: 0.1),
          ),
        ),
        if (streak != null) ...[Gap.w12, _StreakBadge(streak: streak!)],
      ],
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10.0.w, vertical: 4.0.h),
    decoration: BoxDecoration(
      color: AppPalette.orange.withAlpha(26),
      borderRadius: BorderRadius.circular(100),
      border: Border.all(color: AppPalette.orange.withAlpha(77), width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(AppIcons.flame, color: AppPalette.orange, size: 14.0.w),
        Gap.w6,
        Text(
          streak.toString(),
          style: context.labelBold.copyWith(color: AppPalette.orange),
        ),
      ],
    ),
  );
}
