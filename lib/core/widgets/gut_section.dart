import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';

/// A standardized section wrapper that includes an optional title header
/// and can optionally wrap its children in a stylized card.
class GutSection extends StatelessWidget {
  const GutSection({super.key, this.title, this.info, this.child, this.children, this.showCard = false, this.opacity = 1.0, this.topPadding})
    : assert(child == null || children == null, 'Provide either child or children, not both.');

  /// The section title (displayed as an eyebrow).
  final String? title;

  /// Optional info message shown when tapping an info icon next to the title.
  final String? info;

  /// The main content of the section.
  final Widget? child;

  /// A list of widgets to be displayed inside the section (alternative to [child]).
  final List<Widget>? children;

  /// Whether to wrap the content in a [GutSectionCard].
  final bool showCard;

  /// Whether the section card (if shown) should have an opacity fade.
  final double opacity;

  /// Top padding for the entire section.
  final double? topPadding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: topPadding ?? AppSizes.p24),
    child: AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: opacity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[_buildHeader(context), Gap.h8],
          if (showCard) GutSectionCard(children: children ?? [child!]) else child ?? Column(children: children!),
        ],
      ),
    ),
  );

  Widget _buildHeader(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: 4.0.w, bottom: 0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(title!.toUpperCase(), style: context.eyebrow)],
    ),
  );
}

/// A standardized card container for section content.
class GutSectionCard extends StatelessWidget {
  const GutSectionCard({super.key, required this.children, this.padding});
  final List<Widget> children;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding ?? EdgeInsets.symmetric(horizontal: AppSizes.p20),
    decoration: BoxDecoration(
      color: context.appColorScheme.elevatedSurface,
      borderRadius: BorderRadius.circular(AppSizes.r24),
      border: Border.all(color: context.appColorScheme.borderSubtle),
      boxShadow: [BoxShadow(color: AppPalette.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: children),
  );
}
