import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/date_formatter.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/widgets/analysis_card.dart';
import 'package:shimmer/shimmer.dart';

class MealDetailScreen extends StatelessWidget {
  const MealDetailScreen({super.key, required this.meal});
  final MealLog meal;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    return Scaffold(
      backgroundColor: scheme.cardBackground,
      body: CustomScrollView(
        slivers: [
          const GutSliverAppBar(title: '', showBrandingIcon: false),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p10),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                DashboardEntrance(delay: 50, child: _MealHeroCard(meal: meal)),
                Gap.h20,
                if (meal.photoUrl != null && meal.photoUrl!.isNotEmpty) ...[DashboardEntrance(delay: 100, child: _MealPhotoCard(photoUrl: meal.photoUrl!)), Gap.h20],
                DashboardEntrance(delay: 150, child: _MealItemsCard(items: meal.items)),
                Gap.h20,
                if (meal.analysisResult != null && meal.analysisResult!.isNotEmpty) ...[DashboardEntrance(delay: 200, child: _MealAnalysisCard(analysis: meal.analysisResult!)), Gap.h20],
                if (meal.notes != null && meal.notes!.isNotEmpty) ...[DashboardEntrance(delay: 250, child: _MealNotesCard(notes: meal.notes!)), Gap.h40],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealHeroCard extends StatelessWidget {
  const _MealHeroCard({required this.meal});
  final MealLog meal;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final mealType = meal.mealType?.toUpperCase() ?? 'MEAL';

    return ModernInsightCard(
      title: mealType,
      icon: AppIcons.utensils,
      iconColor: scheme.textPrimary,
      backgroundColor: scheme.cardBackground,
      footer: Text(
        DateFormatter.formatFull(meal.createdAt).toUpperCase(),
        style: context.caption.copyWith(color: scheme.cardBackground, fontWeight: FontWeight.w900, fontSize: 10.sp, letterSpacing: 1.2),
      ),
      footerColor: scheme.textPrimary,
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Gap.h24,
            Text(
              meal.items.take(2).join(', ').toUpperCase(),
              style: context.displaySm.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1.5, height: 0.9),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Gap.h8,
            Text('LOGGED FROM ${meal.source?.toUpperCase() ?? 'CHAT'}', style: context.eyebrow),
            Gap.h32,
          ],
        ),
      ),
    );
  }
}

class _MealPhotoCard extends StatelessWidget {
  const _MealPhotoCard({required this.photoUrl});
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PHOTO', style: context.eyebrow),
        Gap.h16,
        Container(
          height: 250.h,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.r24),
            border: Border.all(color: scheme.border.withValues(alpha: 0.5)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.r24),
            child: CachedNetworkImage(
              imageUrl: photoUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: scheme.border.withValues(alpha: 0.2),
                highlightColor: scheme.border.withValues(alpha: 0.1),
                child: Container(color: AppPalette.white),
              ),
              errorWidget: (_, _, _) => Icon(AppIcons.image, size: AppSizes.icon48, color: scheme.textMuted),
            ),
          ),
        ),
      ],
    );
  }
}

class _MealItemsCard extends StatelessWidget {
  const _MealItemsCard({required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ITEMS', style: context.eyebrow),
        Gap.h16,
        AnalysisCard(
          metric: items.length.toString(),
          label: 'DETECTED ITEMS',
          icon: AppIcons.package,
          glowColor: scheme.textPrimary,
          items: items.map((i) => AnalysisItem(title: i.toUpperCase(), subtitle: 'Part of this meal', icon: AppIcons.checkCircle, color: scheme.textPrimary)).toList(),
        ),
      ],
    );
  }
}

class _MealAnalysisCard extends StatelessWidget {
  const _MealAnalysisCard({required this.analysis});
  final String analysis;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AI ANALYSIS', style: context.eyebrow),
        Gap.h16,
        AnalysisCard(
          metric: 'AI',
          label: 'INSIGHTS',
          icon: AppIcons.brain,
          glowColor: scheme.textPrimary,
          items: [AnalysisItem(title: 'SUMMARY', subtitle: analysis, icon: AppIcons.info, color: scheme.textPrimary)],
        ),
      ],
    );
  }
}

class _MealNotesCard extends StatelessWidget {
  const _MealNotesCard({required this.notes});
  final String notes;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('NOTES', style: context.eyebrow),
        Gap.h16,
        Container(
          padding: EdgeInsets.all(AppSizes.p20),
          width: double.infinity,
          decoration: BoxDecoration(
            color: scheme.elevatedSurface,
            borderRadius: BorderRadius.circular(AppSizes.r24),
            border: Border.all(color: scheme.border.withValues(alpha: 0.5)),
          ),
          child: Text(notes, style: context.body.copyWith(color: scheme.textSecondary)),
        ),
      ],
    );
  }
}
