import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/data/additive_concern_db.dart';
import 'package:gutgood/core/models/route_arguments.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/product_details/presentation/pages/additive_level_colors.dart';

/// Full additives list screen redesigned for compactness and brand style.
class AdditivesListScreen extends StatelessWidget {
  const AdditivesListScreen({super.key, required this.args});

  final AdditiveListArgs args;

  static int _rank(AdditiveConcernLevel level) => switch (level) {
    AdditiveConcernLevel.higher => 3,
    AdditiveConcernLevel.moderate => 2,
    AdditiveConcernLevel.low => 1,
    AdditiveConcernLevel.unknown => 0,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final sorted = [...args.items]..sort((a, b) => _rank(b.level).compareTo(_rank(a.level)));
    return Scaffold(
      backgroundColor: scheme.cardBackground,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const GutSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(AppSizes.p16, AppSizes.p12, AppSizes.p16, AppSizes.p32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ListHeader(title: args.title, subtitle: args.subtitle, count: sorted.length),
                    const SizedBox(height: 20),
                    if (sorted.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSizes.p40),
                        child: Center(
                          child: Text(AppStrings.noAdditivesFound, style: context.bodySm.copyWith(color: scheme.textSecondary)),
                        ),
                      )
                    else
                      for (var i = 0; i < sorted.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DashboardEntrance(
                            delay: 60 + i * 40,
                            child: _AdditiveCard(concern: sorted[i]),
                          ),
                        ),
                    const SizedBox(height: 12),
                    const DashboardEntrance(delay: 320, child: _WhyItMattersCard()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.title, required this.subtitle, required this.count});

  final String title;
  final String subtitle;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.headingMd.copyWith(fontWeight: FontWeight.w900, fontSize: 32)),
              if (subtitle.isNotEmpty) ...[const SizedBox(height: 6), Text(subtitle, style: context.bodySm.copyWith(color: scheme.textSecondary, fontSize: 16))],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 82,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: scheme.surfaceSubtle, borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              Text(
                '$count',
                style: context.headingSm.copyWith(color: scheme.textPrimary, fontSize: 26, fontWeight: FontWeight.w800),
              ),
              Text(
                'TOTAL\nADDITIVES',
                textAlign: TextAlign.center,
                style: context.captionMicro.copyWith(color: scheme.textSecondary, height: 1.1, fontWeight: FontWeight.w800, fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdditiveCard extends StatelessWidget {
  const _AdditiveCard({required this.concern});

  final AdditiveConcern concern;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final colors = AdditiveLevelColors.of(context, concern.level);
    final title = concern.code.isEmpty ? concern.name : '${concern.name} (${concern.code})';
    final description = concern.whyFlagged.isNotEmpty ? '${concern.whyUsed} ${concern.whyFlagged}.' : concern.whyUsed;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.push(AppRoutes.additiveDetail, extra: concern),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(18)),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: colors.accent.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: Icon(AdditiveLevelColors.iconFor(concern.level), size: 24, color: colors.accent),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: context.title.copyWith(fontWeight: FontWeight.w800, fontSize: 16)),
                          if (concern.category.isNotEmpty)
                            Text(
                              concern.category,
                              style: context.caption.copyWith(color: scheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w400),
                            ),
                          const SizedBox(height: 6),
                          Text(
                            description,
                            style: context.bodySm.copyWith(color: scheme.textSecondary, fontSize: 13, height: 1.3),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(AppIcons.chevronRight, size: 20, color: Color(0xFF8B9095)),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: _ListRiskBadge(label: concern.concernLabel, color: colors.accent, background: colors.pillBackground),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListRiskBadge extends StatelessWidget {
  const _ListRiskBadge({required this.label, required this.color, required this.background});
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800).copyWith(color: color),
          ),
        ],
      ),
    );
}

class _WhyItMattersCard extends StatelessWidget {
  const _WhyItMattersCard();

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: scheme.surfaceSubtle, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: scheme.success.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(AppIcons.brain, size: 24, color: scheme.success),
          ),
          const SizedBox(height: 12),
          Text(AppStrings.whyDoesThisMatter, style: context.title.copyWith(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 6),
          Text(AppStrings.whyAdditivesMatterBody, style: context.bodySm.copyWith(color: scheme.textSecondary, fontSize: 13, height: 1.35)),
        ],
      ),
    );
  }
}
