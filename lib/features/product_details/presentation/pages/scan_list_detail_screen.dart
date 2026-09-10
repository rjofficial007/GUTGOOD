import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/data/additive_concern_db.dart';
import 'package:gutgood/core/models/scan_list_args.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/bento_card.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/product_details/presentation/utils/scan_result_utils.dart';

/// Generic full-list screen for a scan's ingredients, allergens or additives.
/// (Args + kind live in scan_result_widgets.dart to avoid an import cycle.)
class ScanListDetailScreen extends StatelessWidget {
  const ScanListDetailScreen({super.key, required this.args});
  final ScanListDetailArgs args;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Scaffold(
      backgroundColor: scheme.cardBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          GutSliverAppBar(title: _title, centerTitle: true),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (args.kind == ScanListKind.allergens)
                    DashboardEntrance(
                      delay: 50,
                      child: BentoCard(
                        padding: const EdgeInsets.all(16),
                        borderRadius: 20,
                        backgroundColor: scheme.error.withAlpha(14),
                        borderColor: scheme.error.withAlpha(50),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 18.sp, color: scheme.error),
                            Gap.w10,
                            Expanded(
                              child: Text(
                                AppStrings.allergenCaution,
                                style: context.caption.copyWith(color: scheme.textSecondary, fontSize: 12.sp, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (args.kind == ScanListKind.allergens) Gap.h12,
                  DashboardEntrance(
                    delay: 100,
                    child: BentoCard(
                      padding: const EdgeInsets.all(16),
                      borderRadius: 20,
                      child: Column(children: _rows(context)),
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
        final sorted = [...args.scan.additiveConcerns]..sort((a, b) => _rank(b.level).compareTo(_rank(a.level)));
        return sorted.map((concern) => _ConcernRow(concern: concern)).toList();
    }
  }

  int _rank(AdditiveConcernLevel level) {
    switch (level) {
      case AdditiveConcernLevel.higher:
        return 3;
      case AdditiveConcernLevel.moderate:
        return 2;
      case AdditiveConcernLevel.low:
        return 1;
      case AdditiveConcernLevel.unknown:
        return 0;
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
    final scheme = context.appColorScheme;
    final color = ingredientSignalColor(context, colorName);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Gap.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: context.labelBold.copyWith(fontWeight: FontWeight.w800, fontSize: 13.sp),
                ),
                if (impact.isNotEmpty)
                  Text(
                    impact,
                    style: context.caption.copyWith(color: scheme.textMuted, fontSize: 11.5.sp, height: 1.4),
                  ),
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
    final scheme = context.appColorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: scheme.error.withAlpha(20), shape: BoxShape.circle),
            child: Icon(Icons.warning_amber_rounded, size: 15.sp, color: scheme.error),
          ),
          Gap.w12,
          Expanded(
            child: Text(
              name,
              style: context.labelBold.copyWith(fontWeight: FontWeight.w800, fontSize: 13.sp),
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
    final scheme = context.appColorScheme;
    final color = additiveConcernColor(context, concern.level);
    final subtitle = concern.whyFlagged.isNotEmpty ? concern.whyFlagged : concern.whatItIs;
    return InkWell(
      onTap: () => context.push(AppRoutes.additiveDetail, extra: concern),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    concern.displayTitle,
                    style: context.labelBold.copyWith(fontWeight: FontWeight.w800, fontSize: 13.sp),
                  ),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.caption.copyWith(color: scheme.textMuted, fontSize: 11.5.sp),
                  ),
                ],
              ),
            ),
            Gap.w8,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withAlpha(22), borderRadius: BorderRadius.circular(6)),
              child: Text(
                concern.level.label,
                style: context.captionBold.copyWith(color: color, fontSize: 10.sp),
              ),
            ),
            Gap.w4,
            Icon(AppIcons.chevronRight, size: 18.sp, color: scheme.textMuted),
          ],
        ),
      ),
    );
  }
}
