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
import 'package:gutgood/core/widgets/gut_bottom_sheet.dart';
import 'package:gutgood/core/widgets/gut_button.dart';
import 'package:gutgood/features/auth/presentation/providers/purchase_provider.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Static trigger function to display the premium paywall sheet from anywhere
Future<void> showPaywallBottomSheet(BuildContext context, {required VoidCallback onProceedWithLimited}) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  useRootNavigator: true, // 🟢 Ensures the paywall covers the bottom navigation bar
  backgroundColor: AppPalette.transparent,
  builder: (context) => GutPaywallBottomSheet(onProceedWithLimited: onProceedWithLimited),
);

class GutPaywallBottomSheet extends StatelessWidget {
  const GutPaywallBottomSheet({super.key, required this.onProceedWithLimited});
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

    final success = await purchaseProvider.purchasePackage(package);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text(AppStrings.welcomeToPremium), backgroundColor: context.appColorScheme.success));
      context.pop();
    }
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

    return GutSheetWrapper(
      padding: EdgeInsets.zero,
      children: [
        const GutSheetHeader(title: ''),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.p24),
          child: Column(
            children: [
              Text(
                AppStrings.startHealingGut,
                textAlign: TextAlign.center,
                style: context.h1.copyWith(fontSize: AppSizes.s28, height: 1.1),
              ),
              Gap.h8,
              Text(AppStrings.knowWhatHelps, style: context.body.copyWith(color: context.appColorScheme.textMuted)),
              Gap.h28,

              const _PaywallRow(icon: AppIcons.leaf, title: AppStrings.featureFoodsHurtHeal, subtitle: AppStrings.featureFoodsHurtHealDesc),
              Gap.h18,
              const _PaywallRow(icon: AppIcons.arrowRightLeft, title: AppStrings.featureInstantSwaps, subtitle: AppStrings.featureInstantSwapsDesc),
              Gap.h18,
              const _PaywallRow(icon: AppIcons.barChart, title: AppStrings.featurePersonalInsights, subtitle: AppStrings.featurePersonalInsightsDesc),
              Gap.h28,

              Row(
                children: [
                  SizedBox(
                    width: 70,
                    height: 32,
                    child: Stack(
                      children: List.generate(
                        3,
                        (index) => Positioned(
                          left: index * 18,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: context.appColorScheme.cardBackground,
                            child: CircleAvatar(radius: 14, backgroundColor: context.appColorScheme.border, backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=${index + 10}')),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Gap.w4,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(5, (_) => Icon(Icons.star_rounded, color: AppPalette.yellow, size: AppSizes.icon16)),
                        ),
                        Gap.h2,
                        Text(AppStrings.dailyUsedNote, style: context.bodyBold.copyWith(fontSize: AppSizes.s12)),
                        Text(
                          AppStrings.happyMembersCount,
                          style: context.caption.copyWith(fontSize: AppSizes.s11, color: context.appColorScheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Gap.h24,

              if (purchaseProvider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(purchaseProvider.errorMessage!, style: context.body.copyWith(color: context.appColorScheme.error)),
                ),

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
                    final trial = _getTrialPeriodString(package);
                    final period = _getPeriodString(package);

                    // Find monthly package for savings calculation
                    Package? monthly;
                    try {
                      monthly = packages.firstWhere((p) => p.packageType == PackageType.monthly);
                    } catch (_) {}

                    return _PlanCard(
                      package: package,
                      isSelected: isSelected,
                      trialString: trial,
                      periodString: period,
                      monthlyPackage: monthly,
                      onTap: () => purchaseProvider.selectPackage(package.identifier),
                    );
                  },
                )
              else
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),

              GutButton(
                label: isLoaded ? (hasTrial ? AppStrings.startFreeTrial : AppStrings.subscribeNow) : AppStrings.refreshPlans,
                isLoading: purchaseProvider.isLoading || purchaseProvider.isPurchasing,
                onTap: (purchaseProvider.isLoading || purchaseProvider.isPurchasing)
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
              TextButton(
                onPressed: () {
                  context.pop();
                  onProceedWithLimited();
                },
                child: Text(
                  AppStrings.continueLimitedAccess,
                  style: context.bodySm.copyWith(color: context.appColorScheme.textMuted, fontWeight: FontWeight.w600),
                ),
              ),
              Gap.h16,

              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: context.overline.copyWith(fontSize: AppSizes.s10, color: context.appColorScheme.textMuted, letterSpacing: 0.2),
                    children: [
                      const TextSpan(text: AppStrings.paywallFooterPrefix),
                      TextSpan(text: AppStrings.paywallRestore, style: context.underline, recognizer: TapGestureRecognizer()..onTap = () => unawaited(purchaseProvider.restorePurchases())),
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
              Gap.h24,
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.package, required this.isSelected, required this.trialString, required this.periodString, this.monthlyPackage, required this.onTap});
  final Package package;
  final bool isSelected;
  final String trialString;
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

    String? savingsText;
    String? originalPriceText;

    if (isAnnual && monthlyPackage != null) {
      final monthlyPrice = monthlyPackage!.storeProduct.price;
      final annualPrice = storeProduct.price;
      final fullAnnualPrice = monthlyPrice * 12;
      final savings = ((fullAnnualPrice - annualPrice) / fullAnnualPrice * 100).round();
      if (savings > 0) {
        savingsText = 'Save $savings%';
        originalPriceText = '${monthlyPackage!.storeProduct.currencyCode == 'USD' ? r'$' : ''}${fullAnnualPrice.toStringAsFixed(2)} / year';
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? scheme.success.withValues(alpha: 0.05) : scheme.cardBackground,
          borderRadius: BorderRadius.circular(AppSizes.r20),
          border: Border.all(color: isSelected ? scheme.success : scheme.border, width: isSelected ? 1.5 : 1.0),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Radio Indicator
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? scheme.success : scheme.textMuted.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? scheme.success : Colors.transparent),
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
                          Text(isAnnual ? 'Yearly' : 'Monthly', style: context.bodyBold.copyWith(fontSize: 16, color: scheme.textPrimary)),
                          if (isAnnual) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: scheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100)),
                              child: Text(
                                'BEST VALUE',
                                style: context.overline.copyWith(color: scheme.success, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (savingsText != null)
                        Text(savingsText, style: context.bodyBold.copyWith(color: scheme.success, fontSize: 13))
                      else if (!hasFreeTrial)
                        Text('${storeProduct.priceString} / month', style: context.bodySm.copyWith(color: scheme.textMuted)),
                      if (hasFreeTrial)
                        Text(
                          '${intro.periodNumberOfUnits} ${intro.periodUnit.name.toLowerCase()}s FREE TRIAL',
                          style: context.bodyBold.copyWith(color: scheme.success, fontSize: 13, letterSpacing: 0.2),
                        ),
                    ],
                  ),
                ),

                // Price Column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(storeProduct.priceString, style: context.bodyBold.copyWith(fontSize: 18, color: scheme.textPrimary)),
                    Text(periodString, style: context.caption.copyWith(color: scheme.textMuted)),
                    if (originalPriceText != null)
                      Text(
                        originalPriceText,
                        style: context.caption.copyWith(color: scheme.textMuted.withValues(alpha: 0.6), decoration: TextDecoration.lineThrough),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaywallRow extends StatelessWidget {
  const _PaywallRow({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: context.appColorScheme.success.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: context.appColorScheme.success, size: 20),
      ),
      Gap.w14,
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.bodyBold.copyWith(fontSize: AppSizes.s14)),
            Gap.h2,
            Text(
              subtitle,
              style: context.caption.copyWith(fontSize: AppSizes.s12, color: context.appColorScheme.textMuted),
            ),
          ],
        ),
      ),
    ],
  );
}
