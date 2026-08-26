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
import 'package:shimmer/shimmer.dart';

class MealDetailScreen extends StatelessWidget {
  const MealDetailScreen({super.key, required this.meal});

  final MealLog meal;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final hasPhoto = meal.photoUrl != null && meal.photoUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: scheme.cardBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const GutSliverAppBar(title: 'MEAL DETAILS', centerTitle: true),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p24, vertical: AppSizes.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashboardEntrance(delay: 50, child: _MealHeader(meal: meal)),
                  Gap.h32,
                  if (hasPhoto) DashboardEntrance(delay: 100, child: _MealPhotoSection(photoUrl: meal.photoUrl!)),
                  DashboardEntrance(delay: 150, child: _MealItemsSection(items: meal.items)),
                  if (meal.analysisResult != null && meal.analysisResult!.isNotEmpty) ...[Gap.h32, DashboardEntrance(delay: 200, child: _MealIntelligenceCard(analysis: meal.analysisResult!))],
                  if (meal.notes != null && meal.notes!.isNotEmpty) ...[Gap.h32, DashboardEntrance(delay: 250, child: _MealNotesSection(notes: meal.notes!))],
                  Gap.h40,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealHeader extends StatelessWidget {
  const _MealHeader({required this.meal});
  final MealLog meal;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final mealType = meal.mealType?.toUpperCase() ?? 'MEAL';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: scheme.textPrimary, borderRadius: BorderRadius.circular(4)),
              child: Text(
                mealType,
                style: context.caption.copyWith(color: scheme.cardBackground, fontWeight: FontWeight.w900, fontSize: 10.sp),
              ),
            ),
            Gap.w12,
            Text(DateFormatter.formatFull(meal.createdAt).toUpperCase(), style: context.eyebrow.copyWith(color: scheme.textMuted)),
          ],
        ),
        Gap.h16,
        Text(
          meal.items.isEmpty ? 'UNNAMED MEAL' : meal.items.join(', ').toUpperCase(),
          style: context.displaySm.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1.5, height: 1.0, color: scheme.textPrimary),
        ),
        Gap.h12,
        Row(
          children: [
            Icon(AppIcons.info, size: 14, color: scheme.textMuted),
            Gap.w6,
            Text(
              'LOGGED VIA ${meal.source?.toUpperCase() ?? 'CHAT'}',
              style: context.caption.copyWith(color: scheme.textMuted, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}

class _MealPhotoSection extends StatelessWidget {
  const _MealPhotoSection({required this.photoUrl});
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetSectionHeader(title: 'PHOTO', color: Colors.transparent),
        Container(
          height: 280.h,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.r32),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.r32),
            child: CachedNetworkImage(
              imageUrl: photoUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: scheme.border.withValues(alpha: 0.2),
                highlightColor: scheme.border.withValues(alpha: 0.1),
                child: Container(color: Colors.white),
              ),
              errorWidget: (_, _, _) => Container(
                color: scheme.elevatedSurface,
                child: Icon(AppIcons.image, size: 48, color: scheme.textMuted),
              ),
            ),
          ),
        ),
        Gap.h32,
      ],
    );
  }
}

class _MealItemsSection extends StatelessWidget {
  const _MealItemsSection({required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetSectionHeader(title: 'INGREDIENTS', color: Colors.transparent),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: items
              .map(
                (item) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: scheme.elevatedSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.border.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    item.toUpperCase(),
                    style: context.caption.copyWith(fontWeight: FontWeight.bold, color: scheme.textPrimary),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _MealIntelligenceCard extends StatelessWidget {
  const _MealIntelligenceCard({required this.analysis});
  final String analysis;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppPalette.lime.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.r32),
        border: Border.all(color: AppPalette.lime.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.sparkles, color: AppPalette.lime, size: 20),
              Gap.w12,
              Text('GUTGOOD INTELLIGENCE', style: context.eyebrow.copyWith(color: AppPalette.lime, letterSpacing: 1.5)),
            ],
          ),
          Gap.h20,
          Text(
            analysis,
            style: context.body.copyWith(color: scheme.textPrimary, height: 1.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _MealNotesSection extends StatelessWidget {
  const _MealNotesSection({required this.notes});
  final String notes;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetSectionHeader(title: 'PERSONAL NOTES', color: Colors.transparent),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.elevatedSurface,
            borderRadius: BorderRadius.circular(AppSizes.r24),
            border: Border.all(color: scheme.border.withValues(alpha: 0.5)),
          ),
          child: Text(
            '"$notes"',
            style: context.body.copyWith(color: scheme.textSecondary, fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }
}
