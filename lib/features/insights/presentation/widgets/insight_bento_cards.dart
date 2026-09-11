import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/image_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/bento_card.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/super_card.dart';

class BentoFoodCard extends StatelessWidget {
  const BentoFoodCard({super.key, required this.foods, required this.title, required this.trend, required this.isPositive, required this.icon, this.score, this.highlight});

  final List<dynamic> foods;
  final String title;
  final String? trend;
  final bool isPositive;
  final IconData icon;
  final int? score;
  final TopHighlight? highlight;

  @override
  Widget build(BuildContext context) {
    final items = foods.map((f) {
      if (f is HealingFood) {
        final img = f.imageUrl?.toString();
        return SuperCyclerItemData(name: f.name, effect: f.effect, imageUrl: (img != null && img.isNotEmpty) ? img : null);
      } else if (f is TriggerFood) {
        final img = f.imageUrl?.toString();
        return SuperCyclerItemData(name: f.name, effect: f.effect, imageUrl: (img != null && img.isNotEmpty) ? img : null);
      } else if (f is FoodImpact) {
        final img = f.imageUrl?.toString();
        return SuperCyclerItemData(name: f.food, effect: f.effect, imageUrl: (img != null && img.isNotEmpty) ? img : null);
      } else if (f is ProductSwap) {
        final img = f.imageUrl;
        return SuperCyclerItemData(name: f.title, effect: f.subtitle, imageUrl: (img != null && img.isNotEmpty) ? img : getDynamicImageUrl(f.imageKeyword.isNotEmpty ? f.imageKeyword : f.title));
      } else if (f is RecapHighlight) {
        return SuperCyclerItemData(name: f.text, effect: '');
      }
      return SuperCyclerItemData(name: 'Unknown', effect: '');
    }).toList();

    if (title.toUpperCase() == 'HEALING' || title.toUpperCase() == 'TRIGGERS' || title.toUpperCase() == 'RECENT LOGS' || title.toUpperCase() == 'BETTER SWAPS') {
      final displayScore = score ?? (isPositive ? 85 : 25);
      var statusColor = isPositive ? const Color(0xFF27F15B) : const Color(0xFFE9579A);

      if (title.toUpperCase() == 'RECENT LOGS') {
        statusColor = const Color(0xFF0759E8); // Premium Blue for History
      }

      return DashboardEntrance(
        delay: 200,
        child: SuperFoodGaugeCard(
          title: title,
          label:
              highlight?.timeframe.toUpperCase() ??
              (title.toUpperCase() == 'RECENT LOGS' ? 'HISTORY' : (title.toUpperCase() == 'BETTER SWAPS' ? 'RECOMMENDED' : (isPositive ? 'POSITIVE PATTERNS' : 'NEGATIVE PATTERNS'))),
          score: displayScore,
          statusColor: statusColor,
          foods: items,
        ),
      );
    }

    return DashboardEntrance(
      delay: 200,
      child: SuperFoodCyclerCard(items: items, title: title, trend: trend, isPositive: isPositive, icon: icon),
    );
  }
}

class BentoActivityCard extends StatelessWidget {
  const BentoActivityCard({super.key, required this.impacts, this.score});

  final List<FoodImpact> impacts;
  final int? score;

  @override
  Widget build(BuildContext context) => BentoFoodCard(foods: impacts, title: 'RECENT LOGS', trend: null, isPositive: true, icon: AppIcons.history, score: score);
}

class TrackingInProgressCard extends StatelessWidget {
  const TrackingInProgressCard({super.key, required this.mealsLogged, required this.symptomsLogged, required this.scansDone});

  final int mealsLogged;
  final int symptomsLogged;
  final int scansDone;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const totalTarget = 4;
    final currentProgress = (scansDone + mealsLogged + symptomsLogged).clamp(0, totalTarget);
    final progressPercent = (currentProgress / totalTarget).clamp(0.0, 1.0);

    return BentoCard(
      padding: const EdgeInsets.all(20),
      backgroundColor: isDark ? AppPalette.darkCard : scheme.cardBackground,
      borderColor: AppPalette.purple.withAlpha(50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppPalette.purple.withAlpha(26), shape: BoxShape.circle),
                child: Icon(AppIcons.brain, size: 16.sp, color: AppPalette.purple),
              ),
              Gap.w10,
              Text(
                'PATTERN ENGINE INITIALIZING',
                style: context.captionBold.copyWith(color: AppPalette.purple, letterSpacing: 1.2, fontSize: 9.sp, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          Gap.h12,
          Text(
            'Keep Logging Your Meals & Feelings',
            style: context.headingSm.copyWith(color: scheme.textPrimary, fontWeight: FontWeight.w900),
          ),
          Gap.h6,
          Text(
            'GutGood needs at least 3 meals and 1 feeling log to discover your unique body patterns. Progress: $currentProgress / $totalTarget items tracked.',
            style: context.bodySm.copyWith(color: scheme.textSecondary, height: 1.3),
          ),
          Gap.h16,
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: progressPercent, minHeight: 8.h, backgroundColor: scheme.borderSubtle, valueColor: const AlwaysStoppedAnimation<Color>(AppPalette.purple)),
          ),
        ],
      ),
    );
  }
}
