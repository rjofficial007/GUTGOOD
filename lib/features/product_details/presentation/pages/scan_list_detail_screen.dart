import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/bento_widgets.dart' hide BentoCard;
import 'package:gutgood/features/product_details/presentation/pages/additive_level_colors.dart';
import 'package:gutgood/features/product_details/presentation/utils/scan_result_utils.dart';

/// Generic full-list screen for a scan's ingredients, allergens or additives.
/// (Args + kind live in scan_result_widgets.dart to avoid an import cycle.)
class ScanListDetailScreen extends StatelessWidget {
  const ScanListDetailScreen({super.key, required this.args});
  final ScanListDetailArgs args;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: t.cardBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          GutSliverAppBar(title: _title, centerTitle: true, backgroundColor: t.cardBackground.withValues(alpha: 0.8)),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.w, 16.w, 32.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (args.kind == ScanListKind.allergens)
                    DashboardEntrance(
                      delay: 50,
                      child: Container(
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: t.negative.withValues(alpha: isDark ? 0.18 : 0.09),
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(6.w),
                              decoration: BoxDecoration(
                                color: t.negative.withValues(alpha: isDark ? 0.25 : 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.warning_amber_rounded, size: 16.sp, color: t.negative),
                            ),
                            Gap.w12,
                            Expanded(
                              child: Text(
                                AppStrings.allergenCaution,
                                style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, color: t.textSecondary, fontSize: 12.sp, height: 1.4, fontWeight: FontWeight.w400),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (args.kind == ScanListKind.allergens) Gap.h12,
                  ..._rows(context),
                  Gap.h40,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _title {
    switch (args.kind) {
      case ScanListKind.ingredients:
        return AppStrings.ingredientsTitle;
      case ScanListKind.allergens:
        return AppStrings.allergenInfo;
      case ScanListKind.additives:
        return AppStrings.allAdditives;
    }
  }

  List<Widget> _rows(BuildContext context) {
    switch (args.kind) {
      case ScanListKind.ingredients:
        return args.scan.ingredients.map((ing) => _IngredientRow(name: ing.name, impact: ing.impact, colorName: ing.colorName)).toList();
      case ScanListKind.allergens:
        return parseAllergenItems(args.scan.allergens).map((name) => _AllergenRow(name: name)).toList();
      case ScanListKind.additives:
        final sorted = [...args.scan.additiveConcerns]..sort((a, b) => additiveConcernRank(b.level).compareTo(additiveConcernRank(a.level)));
        return sorted.map((concern) => _ConcernRow(concern: concern)).toList();
    }
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.name, required this.impact, required this.colorName});
  final String name;
  final String impact;
  final String colorName;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final signalColor = ingredientSignalColor(context, colorName);
    final cardShade = signalColor.withValues(alpha: isDark ? 0.16 : 0.08);
    final iconBgColor = signalColor.withValues(alpha: isDark ? 0.28 : 0.16);

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(color: cardShade, borderRadius: BorderRadius.circular(14.r)),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(7.w),
            decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
            child: Icon(AppIcons.leaf, size: 15.sp, color: signalColor),
          ),
          Gap.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w700, color: t.textPrimary, letterSpacing: -0.2),
                ),
                if (impact.isNotEmpty) ...[
                  Gap.h2,
                  Text(
                    impact,
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w400, color: t.textSecondary, height: 1.3),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AllergenRow extends StatelessWidget {
  const _AllergenRow({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = t.negative;
    final cardShade = accentColor.withValues(alpha: isDark ? 0.18 : 0.09);
    final iconBgColor = accentColor.withValues(alpha: isDark ? 0.28 : 0.16);

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(color: cardShade, borderRadius: BorderRadius.circular(14.r)),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(7.w),
            decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
            child: Icon(Icons.warning_amber_rounded, size: 16.sp, color: accentColor),
          ),
          Gap.w12,
          Expanded(
            child: Text(
              name,
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w700, color: t.textPrimary, letterSpacing: -0.2),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDark ? 0.25 : 0.14),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              'ALLERGEN',
              style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w900, letterSpacing: 0.6, color: accentColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConcernRow extends StatelessWidget {
  const _ConcernRow({required this.concern});
  final AdditiveConcern concern;

  @override
  Widget build(BuildContext context) {
    final t = context.bentoTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = additiveConcernColor(context, concern.level);
    final cardShade = accentColor.withValues(alpha: isDark ? 0.18 : 0.09);
    final iconBgColor = accentColor.withValues(alpha: isDark ? 0.28 : 0.16);
    final subtitle = concern.whyFlagged.isNotEmpty ? concern.whyFlagged : concern.whatItIs;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(AppRoutes.additiveDetail, extra: concern),
          borderRadius: BorderRadius.circular(14.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(color: cardShade, borderRadius: BorderRadius.circular(14.r)),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                  child: Icon(AdditiveLevelColors.iconFor(concern.level), size: 16.sp, color: accentColor),
                ),
                Gap.w12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        concern.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w700, color: t.textPrimary, letterSpacing: -0.2),
                      ),
                      Gap.h2,
                      Text(
                        subtitle,
                        style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w400, color: t.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Gap.w8,
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: isDark ? 0.25 : 0.14),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    concern.level.label.toUpperCase(),
                    style: TextStyle(fontFamily: InsightBentoTheme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w900, letterSpacing: 0.6, color: accentColor),
                  ),
                ),
                Gap.w8,
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: isDark ? 0.22 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(AppIcons.chevronRight, size: 14.sp, color: accentColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
