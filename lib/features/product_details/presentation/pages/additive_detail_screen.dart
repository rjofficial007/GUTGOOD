import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/data/additive_concern_db.dart';
import 'package:gutgood/core/models/route_arguments.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/product_details/presentation/pages/additive_level_colors.dart';

/// Additive detail screen redesigned to match brand style: header, 2x2 grid,
/// tip, and related list, all within responsive containers.
class AdditiveDetailScreen extends StatelessWidget {
  const AdditiveDetailScreen({super.key, required this.concern});

  final AdditiveConcern concern;

  static String _take(AdditiveConcern c) => c.whyFlagged.isNotEmpty ? c.whyFlagged : AppStrings.noConcernsTypicalAmounts;

  static String _carefulFor(AdditiveConcern c) {
    if (c.carefulFor.isNotEmpty) return c.carefulFor;
    return switch (c.level) {
      AdditiveConcernLevel.higher => AppStrings.carefulHighFallback,
      AdditiveConcernLevel.moderate => AppStrings.carefulModerateFallback,
      AdditiveConcernLevel.low => AppStrings.carefulLowFallback,
      AdditiveConcernLevel.unknown => AppStrings.carefulUnknownFallback,
    };
  }

  static String _tip(AdditiveConcern c) {
    if (c.tip.isNotEmpty) return c.tip;
    return switch (c.level) {
      AdditiveConcernLevel.higher => AppStrings.tipHighFallback,
      AdditiveConcernLevel.moderate => AppStrings.tipModerateFallback,
      AdditiveConcernLevel.low => AppStrings.tipLowFallback,
      AdditiveConcernLevel.unknown => AppStrings.tipUnknownFallback,
    };
  }

  static String _impactBody(AdditiveConcernLevel level) => switch (level) {
    AdditiveConcernLevel.higher => AppStrings.impactHighBody,
    AdditiveConcernLevel.moderate => AppStrings.impactModerateBody,
    AdditiveConcernLevel.low => AppStrings.impactLowBody,
    AdditiveConcernLevel.unknown => AppStrings.impactUnknownBody,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final colors = AdditiveLevelColors.of(context, concern.level);
    final green = AdditiveLevelColors.of(context, AdditiveConcernLevel.low);
    final amber = AdditiveLevelColors.of(context, AdditiveConcernLevel.moderate);
    final pink = AdditiveLevelColors.of(context, AdditiveConcernLevel.higher);
    final related = AdditiveConcernDb.relatedTo(concern);
    final relatedAll = AdditiveConcernDb.relatedTo(concern, limit: 100);
    final description = '${concern.whatItIs} ${concern.whyUsed}';

    return Scaffold(
      backgroundColor: scheme.cardBackground,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const GutSliverAppBar(),
            SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double horizontalPadding = constraints.maxWidth < 400 ? AppSizes.p12 : AppSizes.p16;

                  return Padding(
                    padding: EdgeInsets.fromLTRB(horizontalPadding, AppSizes.p8, horizontalPadding, AppSizes.p20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DashboardEntrance(delay: 40, child: _buildMainCard(context, colors, green, amber, pink, description, constraints.maxWidth)),
                        const SizedBox(height: 20),
                        DashboardEntrance(delay: 240, child: _buildTipCard(context, green, constraints.maxWidth)),
                        if (related.isNotEmpty) ...[const SizedBox(height: 28), DashboardEntrance(delay: 300, child: _buildRelatedSection(context, related, relatedAll, constraints.maxWidth))],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard(BuildContext context, AdditiveLevelColors colors, AdditiveLevelColors green, AdditiveLevelColors amber, AdditiveLevelColors pink, String description, double width) {
    final scheme = context.appColorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: colors.mainCardBackground, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _iconCircle(icon: AdditiveLevelColors.iconFor(concern.level), iconColor: colors.accent, background: colors.iconBackground, size: 64),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              concern.name,
                              style: TextStyle(color: scheme.textPrimary, fontSize: width < 380 ? 16 : 16, fontWeight: FontWeight.w800, height: 1.1),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              concern.category,
                              style: TextStyle(color: scheme.textSecondary, fontSize: width < 380 ? 13 : 15, fontWeight: FontWeight.w400),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      AdditiveConcernPill(label: concern.riskLabel, colors: colors, fontSize: 11, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Description
          Text(
            description,
            style: TextStyle(color: scheme.textPrimary.withOpacity(0.8), fontSize: width < 380 ? 13 : 14, height: 1.35, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 10),
          // Grid
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: _insightCard(context, title: AppStrings.whyItsUsed, text: concern.whyUsed, icon: AppIcons.leaf, iconColor: green.accent, background: green.background),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _insightCard(context, title: AppStrings.whoToBeCareful, text: _carefulFor(concern), icon: AppIcons.user, iconColor: pink.accent, background: pink.background),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: _insightCard(context, title: AppStrings.gutGoodTake, text: _take(concern), icon: AppIcons.alertCircle, iconColor: amber.accent, background: amber.background),
                      ),
                      const SizedBox(height: 8),
                      Expanded(child: _scoreCard(context, colors)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightCard(BuildContext context, {required String title, required String text, required IconData icon, required Color iconColor, required Color background}) {
    final scheme = context.appColorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(color: scheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w800, height: 1.1),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: TextStyle(color: scheme.textSecondary, fontSize: 13, height: 1.3, fontWeight: FontWeight.w400),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _scoreCard(BuildContext context, AdditiveLevelColors colors) {
    final scheme = context.appColorScheme;
    final grey = AdditiveLevelColors.of(context, AdditiveConcernLevel.unknown);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: grey.background, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: scheme.textPrimary.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: Icon(AppIcons.barChart, color: scheme.textPrimary, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: colors.pillBackground, borderRadius: BorderRadius.circular(30)),
                child: Text(
                  AppStrings.scorePointsShort(concern.scoreImpactPts),
                  style: TextStyle(color: colors.accent, fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            AppStrings.impactOnYourScore,
            style: TextStyle(color: scheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w800, height: 1.1),
          ),
          const SizedBox(height: 6),
          Text(_impactBody(concern.level), style: TextStyle(color: scheme.textSecondary, fontSize: 13, height: 1.3)),
        ],
      ),
    );
  }

  Widget _buildTipCard(BuildContext context, AdditiveLevelColors green, double width) {
    final scheme = context.appColorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(color: green.background, borderRadius: BorderRadius.circular(20)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.lightbulb, color: green.accent, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  AppStrings.tipTitle,
                  style: TextStyle(color: scheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  _tip(concern),
                  style: TextStyle(color: scheme.textSecondary, fontSize: width < 380 ? 13 : 14, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedSection(BuildContext context, List<AdditiveConcern> related, List<AdditiveConcern> relatedAll, double width) {
    final scheme = context.appColorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.relatedAdditives,
                  style: TextStyle(color: scheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              if (relatedAll.length > related.length)
                TextButton(
                  onPressed: () => context.push(
                    AppRoutes.additivesList,
                    extra: AdditiveListArgs(items: relatedAll, title: AppStrings.relatedAdditives),
                  ),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: Row(
                    children: [
                      Text(
                        AppStrings.seeAll,
                        style: TextStyle(color: scheme.success, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, color: scheme.success, size: 18),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: scheme.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.border, width: 1.0),
          ),
          child: Column(
            children: List.generate(related.length, (index) => _relatedAdditiveRow(context, related[index], showDivider: index != related.length - 1, width: width)),
          ),
        ),
      ],
    );
  }

  Widget _relatedAdditiveRow(BuildContext context, AdditiveConcern additive, {required bool showDivider, required double width}) {
    final scheme = context.appColorScheme;
    final colors = AdditiveLevelColors.of(context, additive.level);
    return InkWell(
      onTap: () => context.push(AppRoutes.additiveDetail, extra: additive),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _iconCircle(icon: AdditiveLevelColors.iconFor(additive.level), iconColor: colors.accent, background: colors.iconBackground, size: 40),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        additive.name,
                        style: TextStyle(color: scheme.textPrimary, fontSize: width < 380 ? 13 : 15, fontWeight: FontWeight.w500, height: 1.15),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        additive.category,
                        style: TextStyle(color: scheme.textSecondary, fontSize: width < 380 ? 11 : 13, height: 1.15),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  additive.riskLabel,
                  style: TextStyle(color: colors.accent, fontSize: width < 380 ? 11 : 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: scheme.textMuted, size: 22),
              ],
            ),
          ),
          if (showDivider) Divider(height: 1, thickness: 1, indent: 16, endIndent: 16, color: scheme.border),
        ],
      ),
    );
  }

  Widget _iconCircle({required IconData icon, required Color iconColor, required Color background, required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, color: iconColor, size: size * 0.52),
    );
  }
}
