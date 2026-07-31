import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';

import '../../../../core/theme/app_color_scheme.dart';

class SideBySideComparison extends StatelessWidget {
  final String healingGoal;
  final List<HealingFood> healingFoods;
  final String healingTrend;
  final String triggerSymptom;
  final List<TriggerFood> triggerFoods;
  final String triggerTrend;

  const SideBySideComparison({
    super.key,
    required this.healingGoal,
    required this.healingFoods,
    required this.healingTrend,
    required this.triggerSymptom,
    required this.triggerFoods,
    required this.triggerTrend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ComparisonCard(
          title: AppStrings.foodsLinkedTo,
          subtitle: healingGoal,
          foods: healingFoods.map((e) => _FoodItem(name: e.name, effect: e.effect, emoji: e.emoji)).toList(),
          trend: healingTrend,
          color: context.appColorScheme.success,
          bgColor: context.appColorScheme.success.withValues(alpha: 0.05),
        ),
        Gap.h12,
        _ComparisonCard(
          title: AppStrings.foodsLinkedTo,
          subtitle: triggerSymptom,
          foods: triggerFoods.map((e) => _FoodItem(name: e.name, effect: e.effect, emoji: e.emoji)).toList(),
          trend: triggerTrend,
          color: context.appColorScheme.error,
          bgColor: context.appColorScheme.error.withValues(alpha: 0.05),
        ),
      ],
    );
  }
}

class _FoodItem {
  final String name;
  final String effect;
  final String emoji;
  _FoodItem({required this.name, required this.effect, required this.emoji});
}

class _ComparisonCard extends StatelessWidget {
  final String title, subtitle, trend;
  final List<_FoodItem> foods;
  final Color color, bgColor;

  const _ComparisonCard({required this.title, required this.subtitle, required this.foods, required this.trend, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(AppSizes.r16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.caption.copyWith(color: color.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.bold),
          ),
          Text(subtitle, style: context.bodyBold.copyWith(color: color, fontSize: 14)),
          Gap.h16,
          if (foods.isEmpty)
            Text(AppStrings.loggingMoreMeals, style: context.caption.copyWith(fontSize: 10, color: context.appColorScheme.textMuted))
          else
            ...foods.map(
              (food) => Padding(
                padding: EdgeInsets.only(bottom: AppSizes.p12),
                child: Row(
                  children: [
                    Text(food.emoji, style: TextStyle(fontSize: 22)),
                    Gap.w8,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(food.name, style: context.bodyBold.copyWith(fontSize: 12)),
                          Text(food.effect, style: context.caption.copyWith(fontSize: 10, height: 1.1)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Gap.h12,
          Container(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p10, vertical: AppSizes.p8),
            decoration: BoxDecoration(color: context.appColorScheme.cardBackground.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(AppSizes.r12)),
            child: Row(
              children: [
                Icon(trend.startsWith('+') ? AppIcons.trendingUp : AppIcons.trendingDown, size: AppSizes.icon12, color: color),
                Gap.w4,
                Text(
                  '$trend ${subtitle.toLowerCase()} days',
                  style: context.caption.copyWith(color: color, fontWeight: FontWeight.w900, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
