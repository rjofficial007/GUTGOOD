import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:gutgood/core/services/notification_service.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Swap Details screen matching the exact UI/UX mockup.
class SwapDetailScreen extends StatelessWidget {
  const SwapDetailScreen({super.key, required this.alternative, this.sourceFoodName = 'Double Cheeseburger'});

  final SwapAlternative alternative;
  final String sourceFoodName;

  @override
  Widget build(BuildContext context) {
    final v2 = context.v2Theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = alternative.imageUrl ?? V2Kit.foodImageUrl(alternative.name);

    final benefits = alternative.benefits.isNotEmpty
        ? alternative.benefits
        : [
            const SwapBenefit(title: 'Higher Protein', description: 'Helps keep you full longer', icon: 'dumbbell'),
            const SwapBenefit(title: 'Lower Saturated Fat', description: 'Easier on your digestion', icon: 'arrow_down'),
            const SwapBenefit(title: 'Fewer Additives', description: 'More whole food ingredients', icon: 'leaf'),
          ];

    final whyBetter =
        alternative.whyBetterOption ??
        'This ${alternative.name.toLowerCase()} is higher in protein and lower in saturated fat compared to a $sourceFoodName. It also has fewer processed ingredients, which may be easier on your digestion and help reduce headache triggers for you.';

    final nutrition = alternative.nutrition;

    final scaffoldBg = v2.scaffold;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          GutSliverAppBar(title: 'SWAP DETAILS', centerTitle: true, showBrandingIcon: false, backgroundColor: scaffoldBg),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w, 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Hero Image Container (Compact 160.w height)
                  Container(
                    height: 160.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.w),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                          blurRadius: 10.w,
                          offset: Offset(0, 3.w),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, _) => Container(color: v2.cardSubtle),
                      errorWidget: (_, _, _) => Container(
                        color: v2.cardSubtle,
                        child: Icon(LucideIcons.utensils, color: v2.textSecondary),
                      ),
                    ),
                  ),
                  Gap.h12,

                  // 2. Title & Subtitle
                  Text(
                    alternative.name,
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 20.sp, fontWeight: FontWeight.w900, color: v2.textPrimary, height: 1.15),
                  ),
                  Gap.h2,
                  Text(
                    'A better choice for you',
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w500, color: v2.textSecondary),
                  ),
                  Gap.h12,

                  // 3. 3 Feature Highlight Pills Row (Compact)
                  Row(
                    children: [
                      for (final b in benefits.take(3))
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.only(right: b == benefits.take(3).last ? 0 : 6.w),
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 10.w),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF102319) : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(14.w),
                              border: Border.all(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.3) : const Color(0xFFBBF7D0)),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 30.w,
                                  height: 30.w,
                                  decoration: BoxDecoration(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.2) : const Color(0xFFDCFCE7), shape: BoxShape.circle),
                                  alignment: Alignment.center,
                                  child: Icon(_getBenefitIcon(b.icon), size: 15.w, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
                                ),
                                Gap.h6,
                                Text(
                                  b.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w800, color: v2.textPrimary, height: 1.15),
                                ),
                                Gap.h2,
                                Text(
                                  b.description,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w400, color: v2.textSecondary, height: 1.2),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  Gap.h12,

                  // 4. "Why this may be a better option" Card
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: v2.card,
                      borderRadius: BorderRadius.circular(16.w),
                      border: Border.all(color: v2.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28.w,
                          height: 28.w,
                          decoration: BoxDecoration(color: isDark ? const Color(0xFFD97706).withValues(alpha: 0.20) : const Color(0xFFFEF3C7), shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Icon(LucideIcons.lightbulb, size: 14.w, color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)),
                        ),
                        Gap.w10,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Why this may be a better option',
                                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: v2.textPrimary),
                              ),
                              Gap.h4,
                              Text(
                                whyBetter,
                                style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w400, color: v2.textSecondary, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Gap.h12,

                  // 5. Nutrition Highlights (typical) Card
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: v2.card,
                      borderRadius: BorderRadius.circular(16.w),
                      border: Border.all(color: v2.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nutrition Highlights (typical)',
                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: v2.textPrimary),
                        ),
                        Gap.h10,
                        Row(
                          children: [
                            Expanded(child: _nutritionItem(context, nutrition.calories?.toString() ?? '—', 'Calories', valueColor: v2.textPrimary)),
                            _nutritionDivider(context),
                            Expanded(child: _nutritionItem(context, nutrition.protein ?? '—', 'Protein', valueColor: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))),
                            _nutritionDivider(context),
                            Expanded(child: _nutritionItem(context, nutrition.totalFat ?? '—', 'Total Fat', valueColor: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706))),
                            _nutritionDivider(context),
                            Expanded(child: _nutritionItem(context, nutrition.fiber ?? '—', 'Fiber', valueColor: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Gap.h16,

                  // 6. Log This Meal Button & Footer
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await sl<HistoryFirestoreService>().logMeal(
                            MealLog(items: [alternative.name], notes: alternative.reason ?? 'Better food swap selection', mealType: _currentMealType(), source: 'swap', createdAt: DateTime.now()),
                          );
                          unawaited(sl<NotificationService>().scheduleNoMealLoggedReminder());
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logged ${alternative.name} to journal successfully!'), behavior: SnackBarBehavior.floating));
                            context.pop();
                          }
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't log this meal — try again."), behavior: SnackBarBehavior.floating));
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                        foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.w),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100.w)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.utensils, size: 16.w),
                          Gap.w8,
                          Text(
                            'Log This Meal',
                            style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Gap.h8,
                  Center(
                    child: Text(
                      'Only log if you actually eat it.',
                      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, color: v2.textSecondary, fontWeight: FontWeight.w500),
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

IconData _getBenefitIcon(String iconStr) {
  switch (iconStr.toLowerCase()) {
    case 'dumbbell':
    case 'muscle':
      return LucideIcons.dumbbell;
    case 'arrow_down':
    case 'trending_down':
      return LucideIcons.trendingDown;
    case 'leaf':
      return LucideIcons.leaf;
    case 'flame':
      return LucideIcons.flame;
    default:
      return LucideIcons.checkCircle;
  }
}

Widget _nutritionDivider(BuildContext context) => Container(width: 1.w, height: 26.w, color: context.v2Theme.border);

Widget _nutritionItem(BuildContext context, String value, String label, {Color? valueColor}) => Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    Text(
      value,
      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 15.sp, fontWeight: FontWeight.w900, color: valueColor ?? context.v2Theme.textPrimary),
    ),
    Gap.h2,
    Text(
      label,
      style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w500, color: context.v2Theme.textSecondary),
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
