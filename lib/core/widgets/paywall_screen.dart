import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/services/app_services.dart';
import 'package:gutgood/core/services/config_service.dart';
import 'package:gutgood/core/services/internet_connection_checker.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/haptic_helper.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/auth/presentation/providers/purchase_provider.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Entry point to display the premium paywall screen from anywhere.
///
/// Presented as a full-screen modal dialog (covers the bottom navigation
/// bar, like the old bottom sheet did). Completes when the page is popped.
Future<void> showPaywallScreen(BuildContext context, {required VoidCallback onProceedWithLimited}) =>
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => GutPaywallScreen(onProceedWithLimited: onProceedWithLimited)));

class GutPaywallScreen extends StatelessWidget {
  const GutPaywallScreen({super.key, required this.onProceedWithLimited});
  final VoidCallback onProceedWithLimited;

  Future<void> _handlePurchase(BuildContext context, PurchaseProvider purchaseProvider, Package? package) async {
    if (package == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text(AppStrings.planUnavailable), backgroundColor: context.appColorScheme.error));
      return;
    }

    // Check internet before purchase
    if (!sl<InternetConnectionChecker>().isInternetAvailable.value) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text(AppStrings.noInternetConnection), backgroundColor: context.appColorScheme.error));
      return;
    }

    bool success;
    try {
      success = await purchaseProvider.purchasePackage(package);
    } catch (_) {
      // Real failure (a user cancellation returns false instead, never
      // throws). Tell the user instead of leaving them guessing.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text(AppStrings.purchaseFailed), backgroundColor: context.appColorScheme.error));
      }
      return;
    }

    // `false` without an error means the user dismissed the store sheet:
    // stay silent and let them keep browsing.
    if (!success) return;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text(AppStrings.welcomeToPremium), backgroundColor: context.appColorScheme.success));
      context.pop();
    }
  }

  Future<void> _handleRestore(BuildContext context, PurchaseProvider purchaseProvider) async {
    if (purchaseProvider.isPurchasing) return;

    final restored = await purchaseProvider.restorePurchases();

    if (!context.mounted) return;

    if (restored) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text(AppStrings.restoreSuccess), backgroundColor: context.appColorScheme.success));
      context.pop();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text(AppStrings.restoreFailed), backgroundColor: context.appColorScheme.error));
  }

  String _getTrialPeriodString(Package? package) {
    final intro = package?.storeProduct.introductoryPrice;
    if (intro != null && intro.price == 0) {
      final count = intro.periodNumberOfUnits;
      final unit = intro.periodUnit.toString().split('.').last.toLowerCase();
      return '$count-$unit${AppStrings.freeTrialSuffix}'.toUpperCase();
    }
    return '';
  }

  String _getPeriodString(Package? package) {
    final period = package?.storeProduct.subscriptionPeriod;
    if (period == null) return AppStrings.perMonth;
    if (period.contains('Y')) return AppStrings.perYear;
    if (period.contains('M')) return AppStrings.perMonth;
    if (period.contains('W')) return AppStrings.perWeek;
    return AppStrings.perPeriod;
  }

  @override
  Widget build(BuildContext context) {
    final purchaseProvider = context.watch<PurchaseProvider>();
    final packages = purchaseProvider.packages;
    final selectedId = purchaseProvider.selectedPackageIdentifier;

    final selectedPackage = packages.isEmpty ? null : packages.firstWhere((p) => p.identifier == selectedId, orElse: () => packages.first);

    final isLoaded = packages.isNotEmpty;
    final trialString = _getTrialPeriodString(selectedPackage);
    final hasTrial = trialString.isNotEmpty;
    final isBusy = purchaseProvider.isLoading || purchaseProvider.isPurchasing;
    final isRestoring = purchaseProvider.isPurchasing && purchaseProvider.actionType == PurchaseActionType.restore;

    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(AppSizes.p16, AppSizes.p8, AppSizes.p16, AppSizes.p24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PaywallHeader(),
              Gap.h20,
              Text(
                AppStrings.paywallEyebrow,
                style: context.eyebrow.copyWith(fontSize: AppSizes.s11, fontWeight: .w600),
              ),
              Gap.h8,
              Text(AppStrings.startHealingGut, style: context.displayMd.copyWith(fontSize: 40.0.sp)),
              Gap.h8,
              Text(AppStrings.knowWhatHelps, style: context.bodyLg.copyWith(color: context.appColorScheme.textMuted)),
              Gap.h20,

              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _FeatureCard(
                        background: context.appColorScheme.softSuccess,
                        icon: AppIcons.leaf,
                        iconColor: context.appColorScheme.success,
                        title: AppStrings.featureFoodsHurtHeal,
                        subtitle: AppStrings.featureFoodsHurtHealDesc,
                      ),
                    ),
                    Gap.w10,
                    Expanded(
                      child: _FeatureCard(
                        background: context.appColorScheme.softWarning,
                        icon: AppIcons.arrowRightLeft,
                        iconColor: context.appColorScheme.warning,
                        title: AppStrings.featureInstantSwaps,
                        subtitle: AppStrings.featureInstantSwapsDesc,
                      ),
                    ),
                    Gap.w10,
                    Expanded(
                      child: _FeatureCard(
                        background: context.appColorScheme.lavender,
                        icon: AppIcons.barChart,
                        iconColor: context.appColorScheme.lavenderDark,
                        title: AppStrings.featurePersonalInsights,
                        subtitle: AppStrings.featurePersonalInsightsDesc,
                      ),
                    ),
                  ],
                ),
              ),
              Gap.h20,

              // Plan Selection
              if (isLoaded)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: packages.length,
                  separatorBuilder: (_, _) => Gap.h12,
                  itemBuilder: (context, index) {
                    final package = packages[index];
                    final isSelected = package.identifier == selectedId;
                    final period = _getPeriodString(package);

                    // Find monthly package for savings calculation
                    Package? monthly;
                    try {
                      monthly = packages.firstWhere((p) => p.packageType == PackageType.monthly);
                    } catch (_) {}

                    return _PaywallPlanCard(package: package, isSelected: isSelected, periodString: period, monthlyPackage: monthly, onTap: () => purchaseProvider.selectPackage(package.identifier));
                  },
                )
              else if (purchaseProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (purchaseProvider.errorMessage != null)
                // Fetch finished with no plans: show the failure (the
                // button below switches to Refresh Plans) instead of
                // spinning forever.
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(AppIcons.alertCircle, size: AppSizes.icon28, color: context.appColorScheme.error),
                        Gap.h8,
                        Text(
                          purchaseProvider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: context.body.copyWith(color: context.appColorScheme.error),
                        ),
                      ],
                    ),
                  ),
                )
              else
                // No plans, not loading, no error: transient while another
                // action (e.g. restore) superseded the fetch error. Neutral
                // text — a spinner and an error never appear together.
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Center(
                    child: Text(
                      AppStrings.planUnavailable,
                      textAlign: TextAlign.center,
                      style: context.body.copyWith(color: context.appColorScheme.textMuted),
                    ),
                  ),
                ),
              Gap.h16,

              _SubscribeButton(
                label: isLoaded ? (hasTrial ? AppStrings.startFreeTrial : AppStrings.subscribeNow) : AppStrings.refreshPlans,
                isLoading: isBusy && !isRestoring,
                onTap: isBusy
                    ? null
                    : () {
                        if (isLoaded) {
                          _handlePurchase(context, purchaseProvider, selectedPackage);
                        } else {
                          purchaseProvider.retryFetchOfferings();
                        }
                      },
              ),
              Gap.h8,
              Center(
                child: TextButton(
                  onPressed: () {
                    context.pop();
                    onProceedWithLimited();
                  },
                  child: Text(
                    AppStrings.continueLimitedAccess,
                    style: context.bodySm.copyWith(color: context.appColorScheme.textMuted, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                  ),
                ),
              ),
              Gap.h10,

              const _TrustRow(),
              Gap.h16,

              Center(
                child: isRestoring
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: context.appColorScheme.textMuted)),
                          Gap.w8,
                          Text(
                            AppStrings.restoringPurchases,
                            style: context.bodySm.copyWith(fontSize: AppSizes.s12, color: context.appColorScheme.textMuted),
                          ),
                        ],
                      )
                    : RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: context.bodySm.copyWith(fontSize: AppSizes.s12, color: context.appColorScheme.textMuted),
                          children: [
                            TextSpan(text: AppStrings.paywallRestore, style: context.underline, recognizer: TapGestureRecognizer()..onTap = () => unawaited(_handleRestore(context, purchaseProvider))),
                            const TextSpan(text: '  |  '),
                            TextSpan(
                              text: AppStrings.paywallTerms,
                              style: context.underline,
                              recognizer: TapGestureRecognizer()..onTap = () => unawaited(sl<AppService>().urlLauncher(context, sl<ConfigService>().termsConditionUrl)),
                            ),
                            const TextSpan(text: '  |  '),
                            TextSpan(
                              text: AppStrings.paywallPrivacy,
                              style: context.underline,
                              recognizer: TapGestureRecognizer()..onTap = () => unawaited(sl<AppService>().urlLauncher(context, sl<ConfigService>().privacyPolicyUrl)),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// HEADER
// =============================================================================

class _PaywallHeader extends StatelessWidget {
  const _PaywallHeader();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(AppStrings.gutgoodTitle, style: context.headingLg),
        Semantics(
          button: true,
          label: AppStrings.close,
          child: GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: isDark ? AppPalette.darkElevated : AppPalette.gray100, shape: BoxShape.circle),
              child: Icon(AppIcons.x, size: AppSizes.icon18, color: context.appColorScheme.textPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// FEATURE CARDS
// =============================================================================

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.background, required this.icon, required this.iconColor, required this.title, required this.subtitle});

  final Color background;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(AppSizes.p12),
    decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppSizes.r16)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Color.alphaBlend(iconColor.withAlpha(40), background), shape: BoxShape.circle),
          child: Icon(icon, size: AppSizes.icon18, color: iconColor),
        ),
        Gap.h8,
        Text(title, style: context.bodyBold.copyWith(fontSize: AppSizes.s13)),
        Gap.h4,
        Text(
          subtitle,
          style: context.caption.copyWith(fontSize: AppSizes.s11, color: context.appColorScheme.textMuted),
        ),
      ],
    ),
  );
}

// =============================================================================
// PLAN CARD
// =============================================================================

class _PaywallPlanCard extends StatelessWidget {
  const _PaywallPlanCard({required this.package, required this.isSelected, required this.periodString, this.monthlyPackage, required this.onTap});
  final Package package;
  final bool isSelected;
  final String periodString;
  final Package? monthlyPackage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final storeProduct = package.storeProduct;
    final isAnnual = package.packageType == PackageType.annual;
    final intro = storeProduct.introductoryPrice;
    final hasFreeTrial = intro != null && intro.price == 0;

    int? savingsAmt;
    String? originalPriceText;
    String? monthlyEquivalentText;

    if (isAnnual && monthlyPackage != null) {
      final monthlyPrice = monthlyPackage!.storeProduct.price;
      final annualPrice = storeProduct.price;
      final fullAnnualPrice = monthlyPrice * 12;
      final s = ((fullAnnualPrice - annualPrice) / fullAnnualPrice * 100).round();
      if (s > 0) {
        final currency = monthlyPackage!.storeProduct.currencyCode == 'USD' ? r'$' : '';
        savingsAmt = s;
        originalPriceText = '$currency${fullAnnualPrice.toStringAsFixed(2)}/year';
        monthlyEquivalentText = AppStrings.lessThanPerMonth('$currency${(annualPrice / 12).toStringAsFixed(2)}');
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? scheme.successSubtle : scheme.cardBackground,
          borderRadius: BorderRadius.circular(AppSizes.r16),
          border: Border.all(color: isSelected ? scheme.success : scheme.border, width: isSelected ? 1.5 : 1.0),
        ),
        child: Row(
          children: [
            // Radio Indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? scheme.success : scheme.textMuted.withAlpha(102), width: 1.5),
              ),
              child: Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? scheme.success : AppPalette.transparent),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(isAnnual ? AppStrings.yearly : AppStrings.monthly, style: context.bodyBold.copyWith(fontSize: AppSizes.s16)),
                      if (isAnnual) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: scheme.successSubtle, borderRadius: BorderRadius.circular(100)),
                          child: Text(
                            AppStrings.bestValue,
                            style: context.captionBold.copyWith(fontSize: AppSizes.s10, color: scheme.success),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (hasFreeTrial)
                    Text(
                      '${intro.periodNumberOfUnits} ${intro.periodUnit.name.toLowerCase()}${intro.periodNumberOfUnits == 1 ? '' : 's'} FREE TRIAL',
                      style: context.bodyBold.copyWith(color: scheme.success, fontSize: AppSizes.s13, letterSpacing: 0.2),
                    ),
                  if (savingsAmt != null)
                    Text(
                      AppStrings.savePercent(savingsAmt),
                      style: context.bodyBold.copyWith(color: scheme.success, fontSize: AppSizes.s13),
                    )
                  else if (!isAnnual)
                    Text(AppStrings.cancelAnytime, style: context.bodySm.copyWith(color: scheme.textMuted)),
                  if (monthlyEquivalentText != null) Text(monthlyEquivalentText, style: context.bodySm.copyWith(color: scheme.textMuted)),
                ],
              ),
            ),

            // Price Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(storeProduct.priceString, style: context.bodyBold.copyWith(fontSize: AppSizes.s20)),
                Text(periodString.trim(), style: context.bodySm.copyWith(color: scheme.textMuted)),
                if (originalPriceText != null)
                  Text(
                    originalPriceText,
                    style: context.bodySm.copyWith(color: scheme.textMuted.withAlpha(153), decoration: TextDecoration.lineThrough),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SUBSCRIBE BUTTON
// =============================================================================

class _SubscribeButton extends StatelessWidget {
  const _SubscribeButton({required this.label, required this.isLoading, required this.onTap});

  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;

    return Semantics(
      button: true,
      label: label,
      enabled: !isLoading && onTap != null,
      child: GestureDetector(
        onTap: isLoading
            ? null
            : () {
                HapticHelper.light();
                onTap?.call();
              },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: AppSizes.p16),
          decoration: BoxDecoration(color: colorScheme.textPrimary, borderRadius: BorderRadius.circular(AppSizes.r16)),
          alignment: Alignment.center,
          child: isLoading
              ? SizedBox(
                  width: AppSizes.icon20,
                  height: AppSizes.icon20,
                  child: CircularProgressIndicator(color: colorScheme.cardBackground, strokeWidth: 2),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: context.bodyBold.copyWith(fontSize: AppSizes.s18, color: colorScheme.cardBackground),
                    ),
                    Gap.w10,
                    Icon(AppIcons.arrowRight, size: AppSizes.icon20, color: colorScheme.cardBackground),
                  ],
                ),
        ),
      ),
    );
  }
}

// =============================================================================
// TRUST ROW
// =============================================================================

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    Widget item(IconData icon, String label) => Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: AppSizes.icon28, color: scheme.textMuted),
          Gap.w8,
          Text(
            label,
            textAlign: TextAlign.start,
            style: context.bodySm.copyWith(fontSize: AppSizes.s12, color: scheme.textMuted),
          ),
        ],
      ),
    );

    return Row(
      children: [
        item(AppIcons.lock, AppStrings.trustSecurePayment),
        Container(width: 1, height: 48, color: scheme.border),
        item(AppIcons.shieldCheck, AppStrings.trustCancelAnytime),
        Container(width: 1, height: 48, color: scheme.border),
        item(AppIcons.heart, AppStrings.trustHealthierYou),
      ],
    );
  }
}
