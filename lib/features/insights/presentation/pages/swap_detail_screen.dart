import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/di/di_instance.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/theme/insight_theme.dart';
import 'package:gutgood/core/utils/image_utils.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_feed/insight_ui_kit.dart';
import 'package:gutgood/infrastructure/firebase/firestore/history_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/notification_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Swap Details screen matching the exact UI/UX mockup.
class SwapDetailScreen extends StatefulWidget {
  const SwapDetailScreen({
    super.key,
    required this.alternative,
    this.sourceFoodName = '',
  });

  final SwapAlternative alternative;
  final String sourceFoodName;

  @override
  State<SwapDetailScreen> createState() => _SwapDetailScreenState();
}

class _SwapDetailScreenState extends State<SwapDetailScreen> {
  bool _isCheckingMealStatus = true;
  bool _mealStatusCheckFailed = false;
  bool _isLoggingMeal = false;
  bool _isMealLogged = false;

  @override
  void initState() {
    super.initState();
    AppLogger.data('SwapDetailScreen', {
      'sourceFoodName': widget.sourceFoodName,
      'alternative': widget.alternative.toMap(),
    });
    _checkMealLoggedToday();
  }

  Future<void> _checkMealLoggedToday() async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    try {
      final meals = await sl<HistoryFirestoreService>().getRecentMealLogs(
        limit: 150,
        since: startOfToday,
        throwOnError: true,
      );
      final foodName = widget.alternative.name.trim().toLowerCase();
      final alreadyLogged = meals.any(
        (meal) =>
            meal.source?.toLowerCase() == 'swap' &&
            meal.items.any((item) => item.trim().toLowerCase() == foodName),
      );
      if (mounted) {
        setState(() {
          _isMealLogged = alreadyLogged;
          _mealStatusCheckFailed = false;
        });
      }
    } catch (error) {
      AppLogger.error(
        'SwapDetailScreen: Failed to check today\'s meal logs',
        error: error,
      );
      if (mounted) setState(() => _mealStatusCheckFailed = true);
    } finally {
      if (mounted) setState(() => _isCheckingMealStatus = false);
    }
  }

  Future<void> _logMeal(SwapAlternative alternative) async {
    if (_isCheckingMealStatus || _isLoggingMeal || _isMealLogged) return;
    if (_mealStatusCheckFailed) {
      await _checkMealLoggedToday();
      return;
    }
    setState(() => _isLoggingMeal = true);
    try {
      final suppliedImageUrl = alternative.imageUrl?.trim();
      final imageHost = Uri.tryParse(
        suppliedImageUrl ?? '',
      )?.host.toLowerCase();
      final hasPlaceholderImage =
          suppliedImageUrl == null ||
          suppliedImageUrl.isEmpty ||
          imageHost == 'example.com' ||
          imageHost?.endsWith('.example.com') == true ||
          suppliedImageUrl.contains('unsplash.com');
      var imageUrl = suppliedImageUrl;
      if (hasPlaceholderImage) {
        try {
          imageUrl = await getDynamicImageUrl(alternative.name);
        } catch (error) {
          AppLogger.warning(
            'Could not resolve a meal image for ${alternative.name}: $error',
          );
          imageUrl = null;
        }
      }
      final logId = await sl<HistoryFirestoreService>().logMeal(
        MealLog(
          items: [alternative.name],
          photoUrl: imageUrl?.isNotEmpty == true ? imageUrl : null,
          mealType: _currentMealType(),
          source: 'swap',
          createdAt: DateTime.now(),
        ),
      );
      if (logId == null) throw StateError('Meal log was not persisted');
      sl<AppStateService>().notifyChatUpdated();
      unawaited(sl<NotificationService>().scheduleNoMealLoggedReminder());
      if (mounted) {
        setState(() {
          _isMealLogged = true;
          _isLoggingMeal = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${alternative.name} added to History.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoggingMeal = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't log this meal — try again."),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final alternative = widget.alternative;
    final sourceFoodName = widget.sourceFoodName;
    final theme = context.insightTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = alternative.imageUrl;

    final benefits = _swapDetailBenefits(alternative);

    final whyBetter = alternative.whyBetterOption?.trim().isNotEmpty == true
        ? alternative.whyBetterOption!
        : alternative.reason?.trim().isNotEmpty == true
        ? alternative.reason!
        : sourceFoodName.trim().isNotEmpty
        ? 'No specific comparison details are available for ${alternative.name} and $sourceFoodName.'
        : 'No specific comparison details are available for this alternative yet.';

    final nutrition = alternative.nutrition;
    final nutritionBasis = [
      nutrition.servingSize,
      if (nutrition.basis?.trim().isNotEmpty == true &&
          !(nutrition.servingSize?.toLowerCase().contains(
                nutrition.basis!.trim().toLowerCase(),
              ) ??
              false))
        nutrition.basis,
    ].where((value) => value?.trim().isNotEmpty == true).join(' · ');
    final nutritionItems = <(String, String, Color)>[
      if (nutrition.calories != null)
        (nutrition.calories.toString(), 'Calories', theme.textPrimary),
      if (nutrition.protein?.trim().isNotEmpty == true)
        (
          nutrition.protein!,
          'Protein',
          isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
        ),
      if (nutrition.carbohydrates?.trim().isNotEmpty == true)
        (nutrition.carbohydrates!, 'Carbs', theme.textPrimary),
      if (nutrition.totalFat?.trim().isNotEmpty == true)
        (
          nutrition.totalFat!,
          'Total fat',
          isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
        ),
      if (nutrition.saturatedFat?.trim().isNotEmpty == true)
        (nutrition.saturatedFat!, 'Sat. fat', theme.textPrimary),
      if (nutrition.fiber?.trim().isNotEmpty == true)
        (
          nutrition.fiber!,
          'Fiber',
          isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
        ),
      if (nutrition.sugars?.trim().isNotEmpty == true)
        (nutrition.sugars!, 'Sugars', theme.textPrimary),
      if (nutrition.sodium?.trim().isNotEmpty == true)
        (nutrition.sodium!, 'Sodium', theme.textPrimary),
    ];
    final productTags = <String>{
      if (alternative.category.trim().isNotEmpty) alternative.category.trim(),
      if (alternative.badge?.trim().isNotEmpty == true)
        alternative.badge!.trim(),
      if (alternative.tag?.trim().isNotEmpty == true) alternative.tag!.trim(),
      if (alternative.impactLevel.trim().isNotEmpty &&
          alternative.impactLevel != 'unknown')
        alternative.impactLevel.trim(),
      if (alternative.nutriscore?.trim().isNotEmpty == true)
        'Nutri-Score ${alternative.nutriscore!.trim().toUpperCase()}',
    }.toList();

    final scaffoldBg = theme.scaffold;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          GutSliverAppBar(
            title: 'SWAP DETAILS',
            centerTitle: true,
            showBrandingIcon: false,
            backgroundColor: scaffoldBg,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w, 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Food image with a consistent landscape crop.
                  Container(
                    height: 205.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.w),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.25 : 0.08,
                          ),
                          blurRadius: 10.w,
                          offset: Offset(0, 3.w),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InsightUiKit.foodImage(
                      alternative.name,
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: Container(color: theme.cardSubtle),
                      errorWidget: Container(
                        color: theme.cardSubtle,
                        child: Icon(
                          LucideIcons.utensils,
                          color: theme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  Gap.h12,

                  // 2. Title & Subtitle
                  Text(
                    alternative.name,
                    style: TextStyle(
                      fontFamily: InsightTheme.fontFamily,
                      fontSize: 23.sp,
                      fontWeight: FontWeight.w900,
                      color: theme.textPrimary,
                      height: 1.15,
                    ),
                  ),
                  Gap.h4,
                  Text(
                    sourceFoodName.trim().isEmpty
                        ? 'Suggested alternative'
                        : 'Suggested alternative to $sourceFoodName',
                    style: TextStyle(
                      fontFamily: InsightTheme.fontFamily,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: theme.textSecondary,
                    ),
                  ),
                  if (productTags.isNotEmpty ||
                      alternative.barcode?.trim().isNotEmpty == true) ...[
                    Gap.h8,
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 6.w,
                      children: [
                        for (final tag in productTags)
                          _SwapDetailTag(label: tag),
                        if (alternative.barcode?.trim().isNotEmpty == true)
                          _SwapDetailTag(
                            label: 'Barcode ${alternative.barcode}',
                          ),
                      ],
                    ),
                  ],
                  Gap.h12,

                  // 3. Evidence-backed benefit and nutrition highlights.
                  if (benefits.isNotEmpty)
                    ...[
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var index = 0; index < benefits.length; index++) ...[
                              if (index > 0) Gap.w8,
                              Expanded(
                                child: _SwapBenefitCard(
                                  benefit: benefits[index],
                                  isDark: isDark,
                                  icon: _getBenefitIcon(benefits[index].icon),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Gap.h12,
                    ],

                  // 4. "Why this may be a better option" Card
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF15803D).withValues(alpha: 0.10)
                          : const Color(0xFFF1F8F4),
                      borderRadius: BorderRadius.circular(16.w),
                      border: Border.all(color: theme.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28.w,
                          height: 28.w,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(
                                    0xFFD97706,
                                  ).withValues(alpha: 0.20)
                                : const Color(0xFFFEF3C7),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            LucideIcons.lightbulb,
                            size: 14.w,
                            color: isDark
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFFD97706),
                          ),
                        ),
                        Gap.w10,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Why this may be a better option',
                                style: TextStyle(
                                  fontFamily: InsightTheme.fontFamily,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w800,
                                  color: theme.textPrimary,
                                ),
                              ),
                              Gap.h4,
                              Text(
                                whyBetter,
                                style: TextStyle(
                                  fontFamily: InsightTheme.fontFamily,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w400,
                                  color: theme.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Gap.h12,

                  // 5. Only show nutrition when values were supplied.
                  if (nutritionItems.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: theme.cardSubtle,
                        borderRadius: BorderRadius.circular(16.w),
                        border: Border.all(color: theme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nutrition Highlights',
                            style: TextStyle(
                              fontFamily: InsightTheme.fontFamily,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                              color: theme.textPrimary,
                            ),
                          ),
                          Gap.h10,
                          Text(
                            nutritionBasis.isEmpty
                                ? 'Serving size and nutrition basis not supplied.'
                                : nutritionBasis,
                            style: TextStyle(
                              fontFamily: InsightTheme.fontFamily,
                              fontSize: 10.sp,
                              color: theme.textSecondary,
                            ),
                          ),
                          Gap.h8,
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final columns = nutritionItems.length < 4
                                  ? nutritionItems.length
                                  : 4;
                              final itemWidth =
                                  (constraints.maxWidth - (columns - 1) * 8.w) /
                                  columns;
                              return Wrap(
                                spacing: 8.w,
                                runSpacing: 16.w,
                                children: [
                                  for (final item in nutritionItems)
                                    SizedBox(
                                      width: itemWidth,
                                      child: _nutritionItem(
                                        context,
                                        item.$1,
                                        item.$2,
                                        valueColor: item.$3,
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  Gap.h16,

                  // 6. Log This Meal Button & Footer
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _isCheckingMealStatus ||
                              _isLoggingMeal ||
                              _isMealLogged
                          ? null
                          : () => _mealStatusCheckFailed
                                ? _checkMealLoggedToday()
                                : _logMeal(alternative),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isMealLogged
                            ? (isDark
                                  ? const Color(0xFF166534)
                                  : const Color(0xFF15803D))
                            : (isDark ? Colors.white : const Color(0xFF0F172A)),
                        foregroundColor: _isMealLogged
                            ? Colors.white
                            : (isDark ? const Color(0xFF0F172A) : Colors.white),
                        padding: EdgeInsets.symmetric(vertical: 16.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100.w),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isCheckingMealStatus || _isLoggingMeal)
                            SizedBox(
                              width: 16.w,
                              height: 16.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.w,
                                color: isDark
                                    ? const Color(0xFF0F172A)
                                    : Colors.white,
                              ),
                            )
                          else
                            Icon(
                              _isMealLogged
                                  ? LucideIcons.check
                                  : LucideIcons.utensils,
                              size: 16.w,
                            ),
                          Gap.w8,
                          Text(
                            _isCheckingMealStatus
                                ? 'Checking meal status…'
                                : _isLoggingMeal
                                ? 'Logging meal…'
                                : _isMealLogged
                                ? 'Meal Logged'
                                : _mealStatusCheckFailed
                                ? 'Tap to retry check'
                                : 'Log This Meal',
                            style: TextStyle(
                              fontFamily: InsightTheme.fontFamily,
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Gap.h8,
                  Center(
                    child: Text(
                      _isMealLogged
                          ? 'Saved to History. Log how you feel later to inform Food Impact.'
                          : 'Only log if you actually eat it.',
                      style: TextStyle(
                        fontFamily: InsightTheme.fontFamily,
                        fontSize: 10.sp,
                        color: theme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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

List<SwapBenefit> _swapDetailBenefits(SwapAlternative alternative) {
  final suppliedBenefits = alternative.benefits
      .where((benefit) => benefit.title.trim().isNotEmpty)
      .take(3)
      .toList();
  if (suppliedBenefits.isNotEmpty) return suppliedBenefits;

  final taggedBenefits = alternative.benefitTags
      .where((tag) => tag.trim().isNotEmpty)
      .take(3)
      .map((tag) {
        final lower = tag.toLowerCase();
        final icon = lower.contains('protein')
            ? 'dumbbell'
            : (lower.contains('lower') || lower.contains('less')) &&
                  lower.contains('fat')
            ? 'arrow_down'
            : 'leaf';
        return SwapBenefit(
          title: tag.trim(),
          description: '',
          icon: icon,
        );
      })
      .toList();
  return taggedBenefits;
}

IconData _getBenefitIcon(String iconStr) {
  switch (iconStr.toLowerCase()) {
    case 'dumbbell':
    case 'muscle':
      return LucideIcons.dumbbell;
    case 'arrow_down':
    case 'trending_down':
      return LucideIcons.trendingDown;
    case 'fiber':
    case 'sprout':
      return LucideIcons.sprout;
    case 'leaf':
      return LucideIcons.leaf;
    case 'flame':
      return LucideIcons.flame;
    default:
      return LucideIcons.checkCircle;
  }
}

class _SwapBenefitCard extends StatelessWidget {
  const _SwapBenefitCard({
    required this.benefit,
    required this.isDark,
    required this.icon,
  });

  final SwapBenefit benefit;
  final bool isDark;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = context.insightTheme;
    final isComparisonHighlight = icon == LucideIcons.trendingDown;
    final accent = isComparisonHighlight
        ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706))
        : (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D));
    final background = isDark
        ? accent.withValues(alpha: 0.09)
        : (isComparisonHighlight
              ? const Color(0xFFFFF8E8)
              : const Color(0xFFF1F8F4));

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.w),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14.w),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.16 : 0.10),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 17.w, color: accent),
          ),
          Gap.h6,
          Text(
            benefit.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: InsightTheme.fontFamily,
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w800,
              color: theme.textPrimary,
              height: 1.12,
            ),
          ),
          if (benefit.description.trim().isNotEmpty) ...[
            Gap.h3,
            Text(
              benefit.description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: InsightTheme.fontFamily,
                fontSize: 10.sp,
                fontWeight: FontWeight.w400,
                color: theme.textSecondary,
                height: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SwapDetailTag extends StatelessWidget {
  const _SwapDetailTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.w),
    decoration: BoxDecoration(
      color: context.insightTheme.cardSubtle,
      borderRadius: BorderRadius.circular(100.w),
      border: Border.all(color: context.insightTheme.border),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontFamily: InsightTheme.fontFamily,
        fontSize: 9.5.sp,
        fontWeight: FontWeight.w700,
        color: context.insightTheme.textSecondary,
      ),
    ),
  );
}

Widget _nutritionItem(
  BuildContext context,
  String value,
  String label, {
  Color? valueColor,
}) => Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    Text(
      value,
      style: TextStyle(
        fontFamily: InsightTheme.fontFamily,
        fontSize: 15.sp,
        fontWeight: FontWeight.w900,
        color: valueColor ?? context.insightTheme.textPrimary,
      ),
    ),
    Gap.h2,
    Text(
      label,
      style: TextStyle(
        fontFamily: InsightTheme.fontFamily,
        fontSize: 10.sp,
        fontWeight: FontWeight.w500,
        color: context.insightTheme.textSecondary,
      ),
    ),
  ],
);

String _currentMealType() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 11) return 'breakfast';
  if (hour >= 11 && hour < 16) return 'lunch';
  if (hour >= 16 && hour < 21) return 'dinner';
  return 'snack';
}
