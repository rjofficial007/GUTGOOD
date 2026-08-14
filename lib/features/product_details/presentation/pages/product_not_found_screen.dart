import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/widgets/widgets.dart';

class ProductNotFoundScreen extends StatelessWidget {
  const ProductNotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appColorScheme.cardBackground,
    body: CustomScrollView(
      slivers: [
        const GutSliverAppBar(),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.p24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([Gap.h40, const _NotFoundMascot(), Gap.h32, const _NotFoundHeader(), Gap.h64, const _ContributeSection(), Gap.h32, const _ActionsSection(), Gap.h40]),
          ),
        ),
      ],
    ),
  );
}

class _NotFoundMascot extends StatelessWidget {
  const _NotFoundMascot();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: AppSizes.p120,
      height: AppSizes.p120,
      decoration: BoxDecoration(
        color: context.appColorScheme.cardBackground,
        shape: BoxShape.circle,
        border: Border.all(color: context.appColorScheme.border),
      ),
      child: Icon(AppIcons.search, size: AppSizes.icon48, color: context.appColorScheme.textMuted),
    ),
  );
}

class _NotFoundHeader extends StatelessWidget {
  const _NotFoundHeader();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        AppStrings.productNotFound,
        textAlign: TextAlign.center,
        style: context.headingMd.copyWith(fontWeight: FontWeight.w800),
      ),
      Gap.h12,
      Text(
        AppStrings.productNotFoundSubtitle,
        textAlign: TextAlign.center,
        style: context.body.copyWith(color: context.appColorScheme.textSecondary),
      ),
    ],
  );
}

class _ContributeSection extends StatelessWidget {
  const _ContributeSection();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;
    return Container(
      padding: EdgeInsets.all(AppSizes.p20),
      decoration: BoxDecoration(
        color: colorScheme.success.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSizes.r20),
        border: Border.all(color: colorScheme.success.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(AppIcons.sparkles, color: colorScheme.success, size: AppSizes.icon20),
              Gap.w12,
              Expanded(
                child: Text(AppStrings.beAContributor, style: context.bodyBold.copyWith(color: colorScheme.success)),
              ),
            ],
          ),
          Gap.h8,
          Text(AppStrings.contributorSubtitle, style: context.bodySm.copyWith(color: colorScheme.success.withValues(alpha: 0.8))),
          Gap.h16,
          _ContributeButton(
            label: AppStrings.takePhotosAndAdd,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.contributionComingSoon)));
            },
          ),
        ],
      ),
    );
  }
}

class _ActionsSection extends StatelessWidget {
  const _ActionsSection();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _OptionTile(icon: AppIcons.sparkles, title: AppStrings.analyzeWithAi, subtitle: AppStrings.analyzeWithAiSubtitle, onTap: () => context.pop('TRIGGER_CAMERA')),
      Gap.h12,
      _OptionTile(icon: AppIcons.refreshCw, title: AppStrings.tryAgain, subtitle: AppStrings.rescanBarcode, onTap: () => context.pop()),
      Gap.h12,
      _OptionTile(icon: AppIcons.keyboard, title: AppStrings.enterManually, subtitle: AppStrings.enterManuallySubtitle, onTap: () => unawaited(context.push(AppRoutes.manualBarcode))),
    ],
  );
}

class _ContributeButton extends StatelessWidget {
  const _ContributeButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: AppSizes.p12),
      decoration: BoxDecoration(color: context.appColorScheme.success, borderRadius: BorderRadius.circular(AppSizes.r12)),
      child: Center(
        child: Text(label, style: context.bodyBold.copyWith(color: Theme.of(context).colorScheme.onPrimary)),
      ),
    ),
  );
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppSizes.r16),
    child: Container(
      padding: EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: context.appColorScheme.cardBackground,
        border: Border.all(color: context.appColorScheme.border),
        borderRadius: BorderRadius.circular(AppSizes.r16),
      ),
      child: Row(
        children: [
          Icon(icon, color: context.appColorScheme.textSecondary, size: AppSizes.icon24),
          Gap.w16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.bodyBold),
                Text(subtitle, style: context.bodySm.copyWith(color: context.appColorScheme.textMuted)),
              ],
            ),
          ),
          Icon(AppIcons.chevronRight, color: context.appColorScheme.textMuted.withValues(alpha: 0.5), size: AppSizes.icon20),
        ],
      ),
    ),
  );
}
