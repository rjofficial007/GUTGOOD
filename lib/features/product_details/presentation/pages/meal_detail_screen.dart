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
import '../widgets/scan_result_widgets.dart';

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
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashboardEntrance(delay: 50, child: _MealHeroSection(meal: meal)),
                  Gap.h12,
                  if (hasPhoto) ...[
                    DashboardEntrance(
                      delay: 100,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _MealPhotoSection(photoUrl: meal.photoUrl!)),
                          Gap.w12,
                          Expanded(flex: 2, child: _MealItemsSection(items: meal.items)),
                        ],
                      ),
                    ),
                  ] else ...[
                    DashboardEntrance(delay: 100, child: _MealItemsSection(items: meal.items)),
                  ],
                  Gap.h12,
                  DashboardEntrance(
                    delay: 200,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (meal.analysisResult != null && meal.analysisResult!.isNotEmpty)
                          Expanded(child: _MealIntelligenceCard(analysis: meal.analysisResult!)),
                        if (meal.notes != null && meal.notes!.isNotEmpty) ...[
                          if (meal.analysisResult != null && meal.analysisResult!.isNotEmpty) Gap.w12,
                          Expanded(child: _MealNotesSection(notes: meal.notes!)),
                        ],
                      ],
                    ),
                  ),
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

class _MealHeroSection extends StatelessWidget {
  const _MealHeroSection({required this.meal});
  final MealLog meal;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final mealType = meal.mealType?.toUpperCase() ?? 'MEAL';
    final hasPhoto = meal.photoUrl != null && meal.photoUrl!.isNotEmpty;
    
    // Aesthetic Color Selection
    final Color accentColor = switch (mealType.toLowerCase()) {
      'breakfast' => const Color(0xFFB4F1B4),
      'lunch' => const Color(0xFFC4B5FD),
      'dinner' => const Color(0xFF98B7FF),
      _ => AppPalette.orange
    };

    return BentoCard(
      padding: const EdgeInsets.all(12),
      height: 200.h,
      backgroundColor: scheme.cardBackground,
      child: Row(
        children: [
          // Left Panel: The "Wallet Card" aesthetic
          AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(16)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Text(
                        'MEAL LOG',
                        style: TextStyle(color: Colors.black.withValues(alpha: 0.4), fontSize: 7.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      left: 10,
                      child: Icon(
                        switch (mealType.toLowerCase()) {
                          'breakfast' => Icons.wb_sunny_outlined,
                          'lunch' => Icons.lunch_dining_outlined,
                          'dinner' => Icons.restaurant_outlined,
                          'snack' => Icons.cookie_outlined,
                          _ => AppIcons.utensils,
                        },
                        size: 48.sp,
                        color: Colors.black.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Gap.w16,
          // Right Panel: Identity
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasPhoto) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(height: 52, width: 52, imageUrl: meal.photoUrl!, fit: BoxFit.cover),
                  ),
                  Gap.h12,
                ],
                Text(
                  mealType,
                  style: TextStyle(color: scheme.textSecondary, fontSize: 8.5.sp, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                ),
                Gap.h4,
                Text(
                  meal.items.isEmpty ? 'UNNAMED MEAL' : meal.items.join(', ').toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.bodyBold.copyWith(
                    color: scheme.textPrimary,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: -0.8,
                  ),
                ),
                Gap.h8,
                Text(
                  DateFormatter.formatFull(meal.createdAt),
                  style: context.caption.copyWith(
                    color: scheme.textSecondary,
                    fontSize: 10.5.sp,
                    height: 1.4,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
          Gap.w4,
        ],
      ),
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
        const SheetSectionHeader(title: 'VISUAL EVIDENCE', color: Colors.transparent),
        BentoCard(
          padding: EdgeInsets.zero,
          height: 280.h,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CachedNetworkImage(
              imageUrl: photoUrl,
              width: double.infinity,
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
        const SheetSectionHeader(title: 'COMPONENTS', color: Colors.transparent),
        BentoCard(
          padding: const EdgeInsets.all(16),
          height: 280.h,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VERIFIED ITEMS',
                style: context.caption.copyWith(
                  color: scheme.textMuted,
                  fontWeight: FontWeight.w900,
                  fontSize: 8.sp,
                  letterSpacing: 1.0,
                ),
              ),
              Gap.h16,
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: items
                        .map(
                          (item) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: scheme.elevatedSurface,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: scheme.border.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              item.toUpperCase(),
                              style: context.caption.copyWith(
                                fontWeight: FontWeight.w900,
                                color: scheme.textPrimary,
                                fontSize: 9.sp,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
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

    return BentoCard(
      height: 240.h,
      padding: const EdgeInsets.all(20),
      backgroundColor: const Color(0xFFC4B5FD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EXPERT ANALYSIS',
                style: context.caption.copyWith(
                  color: Colors.black.withOpacity(0.6),
                  fontWeight: FontWeight.w900,
                  fontSize: 9.sp,
                  letterSpacing: 1.2,
                ),
              ),
              const Icon(AppIcons.sparkles, color: Colors.black45, size: 14),
            ],
          ),
          const Spacer(),
          Text(
            analysis,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: context.body.copyWith(
              color: Colors.black,
              height: 1.5,
              fontWeight: FontWeight.w500,
              fontSize: 13.sp,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
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
    return BentoCard(
      height: 240.h,
      padding: const EdgeInsets.all(24),
      backgroundColor: scheme.elevatedSurface,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Icon(Icons.format_quote_rounded, color: scheme.textMuted.withValues(alpha: 0.2), size: 48),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PERSONAL MEMO',
                style: context.caption.copyWith(
                  color: scheme.textSecondary,
                  fontWeight: FontWeight.w900,
                  fontSize: 9.sp,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                notes,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: context.body.copyWith(
                  color: scheme.textPrimary,
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 2,
                    decoration: BoxDecoration(color: scheme.textMuted.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2)),
                  ),
                  Gap.w8,
                  Text(
                    'USER NOTES',
                    style: context.caption.copyWith(color: scheme.textMuted, fontSize: 7.sp, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
