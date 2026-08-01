import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_assets.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';

class GutAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBrandingIcon;
  final bool? centerTitle;
  final double? elevation;
  final Color? backgroundColor;
  final bool automaticallyImplyLeading;

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
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: titleWidget ?? _buildTitle(context),
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      elevation: elevation,
      backgroundColor: backgroundColor ?? context.appColorScheme.cardBackground.withValues(alpha: 0.8),
      automaticallyImplyLeading: automaticallyImplyLeading,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: AppPalette.transparent),
        ),
      ),
    );
  }

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
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      title: titleWidget ?? _buildTitle(context),
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      floating: floating,
      pinned: pinned,
      snap: snap,
      elevation: 0,
      forceElevated: forceElevated,
      backgroundColor: context.appColorScheme.cardBackground.withValues(alpha: 0.8),
      automaticallyImplyLeading: automaticallyImplyLeading,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: AppPalette.transparent),
        ),
      ),
    );
  }

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
}
