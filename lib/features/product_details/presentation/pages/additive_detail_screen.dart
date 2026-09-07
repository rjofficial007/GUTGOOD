import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/data/additive_concern_db.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/product_details/presentation/widgets/scan_result_widgets.dart';

/// Deep-dive for one additive: what it is, why it's used, concern + score impact.
class AdditiveDetailScreen extends StatelessWidget {
  const AdditiveDetailScreen({super.key, required this.concern});
  final AdditiveConcern concern;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final color = additiveConcernColor(context, concern.level);

    return Scaffold(
      backgroundColor: scheme.cardBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const GutSliverAppBar(title: AppStrings.aboutThisAdditive, centerTitle: true),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashboardEntrance(
                    delay: 50,
                    child: BentoCard(
                      padding: const EdgeInsets.all(18),
                      borderRadius: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                              Gap.w8,
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: color.withAlpha(22), borderRadius: BorderRadius.circular(8)),
                                child: Text(
                                  '${AppStrings.concernLevel}: ${concern.level.label}',
                                  style: context.captionBold.copyWith(color: color, fontSize: 11.sp),
                                ),
                              ),
                            ],
                          ),
                          Gap.h12,
                          Text(concern.displayTitle, style: context.headingSm.copyWith(fontSize: 20.sp, fontWeight: FontWeight.w900, height: 1.2)),
                          Gap.h10,
                          Text(concern.explanation, style: context.bodySm.copyWith(color: scheme.textSecondary, height: 1.6, fontSize: 13.5.sp)),
                        ],
                      ),
                    ),
                  ),
                  Gap.h12,
                  DashboardEntrance(
                    delay: 100,
                    child: BentoCard(
                      padding: const EdgeInsets.all(18),
                      borderRadius: 20,
                      child: Column(
                        children: [
                          _InfoRow(label: AppStrings.whatItIs, body: concern.whatItIs),
                          Divider(color: scheme.borderSubtle, height: 24),
                          _InfoRow(label: AppStrings.whyItsUsed, body: concern.whyUsed),
                          if (concern.whyFlagged.isNotEmpty) ...[
                            Divider(color: scheme.borderSubtle, height: 24),
                            _InfoRow(label: AppStrings.whyFlagged, body: concern.whyFlagged, bodyColor: AppPalette.orange),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Gap.h12,
                  DashboardEntrance(
                    delay: 150,
                    child: BentoCard(
                      padding: const EdgeInsets.all(18),
                      borderRadius: 20,
                      backgroundColor: color.withAlpha(16),
                      borderColor: color.withAlpha(50),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: color.withAlpha(26), shape: BoxShape.circle),
                            child: Icon(Icons.info_outline_rounded, size: 16.sp, color: color),
                          ),
                          Gap.w12,
                          Expanded(child: Text(_scoreNote, style: context.caption.copyWith(color: scheme.textSecondary, fontSize: 12.sp, height: 1.5))),
                        ],
                      ),
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

  String get _scoreNote {
    switch (concern.level) {
      case AdditiveConcernLevel.low:
        return 'Low-concern additives barely move your score — just 1 point each, capped at 3 total.';
      case AdditiveConcernLevel.moderate:
        return 'Moderate-concern additives cost your score 3 points each (capped at 12) — worth knowing about.';
      case AdditiveConcernLevel.higher:
        return 'Higher-concern additives cost your score 8 points each (capped at 24) — the strongest additive penalty.';
      case AdditiveConcernLevel.unknown:
        return 'Limited data, so this is scored gently at just 1 point — never over-penalized for being unknown.';
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.body, this.bodyColor});
  final String label;
  final String body;
  final Color? bodyColor;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: context.captionBold.copyWith(color: scheme.textMuted, fontSize: 10.sp, letterSpacing: 1.0)),
        Gap.h6,
        Text(body, style: context.bodySm.copyWith(color: bodyColor ?? scheme.textPrimary, height: 1.5, fontSize: 13.5.sp, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
