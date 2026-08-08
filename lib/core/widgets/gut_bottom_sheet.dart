import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';

class GutSheetHeader extends StatelessWidget {
  const GutSheetHeader({
    super.key,
    required this.title,
    this.showCloseButton = true,
    this.onClose,
  });
  final String title;
  final bool showCloseButton;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: AppSizes.p24,
      vertical: AppSizes.p20,
    ),
    child: Column(
      children: [
        // Drag handle
        Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: context.appColorScheme.border,
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
        Gap.h20,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (showCloseButton) Gap.w48,
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: context.headingSm,
              ),
            ),
            if (showCloseButton)
              IconButton(
                onPressed: onClose ?? () => context.pop(),
                icon: Icon(
                  AppIcons.x,
                  size: AppSizes.icon16,
                  color: context.appColorScheme.textSecondary,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: context.appColorScheme.elevatedSurface,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(32, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            if (!showCloseButton) Gap.w4,
          ],
        ),
      ],
    ),
  );
}

class GutSheetWrapper extends StatelessWidget {
  const GutSheetWrapper({
    super.key,
    required this.children,
    this.padding,
    this.footer,
  });
  final List<Widget> children;
  final EdgeInsets? padding;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.appColorScheme.cardBackground,
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r32)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: padding ?? EdgeInsets.symmetric(horizontal: AppSizes.p24),
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
        ?footer,
      ],
    ),
  );
}
