import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/models/pattern_occurrence.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:gutgood/core/widgets/widgets.dart';

class PatternDiscoveryScreen extends StatelessWidget {
  const PatternDiscoveryScreen({super.key, required this.pattern});
  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final patternColor = InsightUiUtils.getPatternColor(pattern.type);

    return Scaffold(
      backgroundColor: scheme.cardBackground,
      appBar: GutAppBar(
        title: '${pattern.type.toUpperCase()} PATTERN',
        showBrandingIcon: false,
        actions: [
          IconButton(
            icon: Icon(AppIcons.refreshCw, size: AppSizes.icon20),
            onPressed: () {},
          ),
          Gap.w8,
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.p24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PatternHeader(pattern: pattern, color: patternColor),
            Gap.h32,
            _DiscoverySummaryCard(pattern: pattern, color: patternColor),
            Gap.h40,
            _WhatHappenedSection(pattern: pattern, color: patternColor),
            Gap.h40,
            _CommonFactorsSection(pattern: pattern, color: patternColor),
            Gap.h40,
            _PatternStrengthSection(pattern: pattern, color: patternColor),
            Gap.h40,
            _NextStepsSection(pattern: pattern, color: patternColor),
            Gap.h48,
          ],
        ),
      ),
    );
  }
}

class _PatternHeader extends StatelessWidget {
  const _PatternHeader({required this.pattern, required this.color});
  final BodyPattern pattern;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final icon = InsightUiUtils.getPatternTypeIcon(pattern.type);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(AppSizes.p12),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: AppSizes.icon32),
        ),
        Gap.w20,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You may have a pattern\nworth watching.', style: context.h2.copyWith(height: 1.1)),
              Gap.h12,
              Text('GutGood noticed you\'ve reported ${pattern.type} after similar meals more than once.', style: context.body.copyWith(color: scheme.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _DiscoverySummaryCard extends StatelessWidget {
  const _DiscoverySummaryCard({required this.pattern, required this.color});
  final BodyPattern pattern;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    return Container(
      padding: EdgeInsets.all(AppSizes.p24),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(AppSizes.r24),
        border: Border.all(color: scheme.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Text(
            '${pattern.frequency}',
            style: context.h1.copyWith(fontSize: 64, color: color, fontWeight: FontWeight.w900),
          ),
          Gap.w16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('times noticed', style: context.bodyBold.copyWith(color: color)),
                Text('in the last ${pattern.timeframeDays} days', style: context.caption.copyWith(color: scheme.textSecondary)),
              ],
            ),
          ),
          Icon(AppIcons.user, size: 64, color: scheme.textSecondary.withValues(alpha: 0.2)),
        ],
      ),
    );
  }
}

class _WhatHappenedSection extends StatelessWidget {
  const _WhatHappenedSection({required this.pattern, required this.color});
  final BodyPattern pattern;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('WHAT HAPPENED', style: context.label.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          Text(
            'View timeline',
            style: context.caption.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      Gap.h16,
      ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: pattern.occurrences.length,
        separatorBuilder: (_, _) => Gap.h12,
        itemBuilder: (context, index) {
          final occurrence = pattern.occurrences[index];
          return _OccurrenceTile(occurrence: occurrence, color: color, pattern: pattern, isLast: index == pattern.occurrences.length - 1);
        },
      ),
    ],
  );
}

class _OccurrenceTile extends StatelessWidget {
  const _OccurrenceTile({required this.occurrence, required this.color, required this.pattern, required this.isLast});
  final PatternOccurrence occurrence;
  final Color color;
  final BodyPattern pattern;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              if (!isLast) Expanded(child: Container(width: 1, color: scheme.border)),
            ],
          ),
          Gap.w16,
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: scheme.elevatedSurface,
              borderRadius: BorderRadius.circular(AppSizes.r12),
              image: occurrence.imageUrl != null ? DecorationImage(image: NetworkImage(occurrence.imageUrl!), fit: BoxFit.cover) : null,
            ),
            child: occurrence.imageUrl == null ? Icon(AppIcons.image, color: scheme.textSecondary.withValues(alpha: 0.3)) : null,
          ),
          Gap.w16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(occurrence.date, style: context.caption.copyWith(fontWeight: FontWeight.bold)),
                Text(occurrence.mealName, style: context.bodyBold),
                Gap.h4,
                Container(
                  padding: EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p2),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppSizes.r12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(InsightUiUtils.getPatternTypeIcon(pattern.type), size: AppSizes.icon12, color: color),
                      Gap.w4,
                      Text(
                        occurrence.reaction,
                        style: context.caption.copyWith(color: color, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('About', style: context.caption),
              Text(occurrence.timeAfter, style: context.caption.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          Gap.w8,
          Icon(AppIcons.chevronRight, size: AppSizes.icon16, color: scheme.textSecondary),
        ],
      ),
    );
  }
}

class _CommonFactorsSection extends StatelessWidget {
  const _CommonFactorsSection({required this.pattern, required this.color});
  final BodyPattern pattern;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text('WHAT THESE MEALS HAD IN COMMON', style: context.label.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          Gap.w4,
          Icon(AppIcons.info, size: AppSizes.icon14, color: context.appColorScheme.textSecondary),
        ],
      ),
      Gap.h16,
      SizedBox(
        height: 100,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: pattern.commonFactors.length,
          separatorBuilder: (_, _) => Gap.w12,
          itemBuilder: (context, index) {
            final factor = pattern.commonFactors[index];
            return _FactorChip(factor: factor, color: color);
          },
        ),
      ),
    ],
  );
}

class _FactorChip extends StatelessWidget {
  const _FactorChip({required this.factor, required this.color});
  final CommonFactor factor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    return Container(
      width: 100,
      padding: EdgeInsets.all(AppSizes.p12),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(AppSizes.r16),
        border: Border.all(color: scheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(InsightUiUtils.getReactionIcon(factor.icon), color: color),
          Gap.h8,
          Text(
            factor.label,
            textAlign: TextAlign.center,
            style: context.caption.copyWith(fontWeight: FontWeight.bold, fontSize: 10, height: 1.1),
          ),
        ],
      ),
    );
  }
}

class _PatternStrengthSection extends StatelessWidget {
  const _PatternStrengthSection({required this.pattern, required this.color});
  final BodyPattern pattern;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final percentage = pattern.totalSimilarMeals > 0 ? pattern.frequency / pattern.totalSimilarMeals : 0.0;

    return Container(
      padding: EdgeInsets.all(AppSizes.p24),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(AppSizes.r24),
        border: Border.all(color: scheme.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(value: percentage, strokeWidth: 8, backgroundColor: scheme.border, valueColor: AlwaysStoppedAnimation(color)),
              ),
            ],
          ),
          Gap.w24,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YOUR PATTERN', style: context.label.copyWith(fontWeight: FontWeight.bold)),
                Gap.h4,
                Text('${pattern.frequency} of ${pattern.totalSimilarMeals} similar meals were followed by ${pattern.type}.', style: context.body.copyWith(height: 1.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextStepsSection extends StatelessWidget {
  const _NextStepsSection({required this.pattern, required this.color});
  final BodyPattern pattern;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final recommendation = pattern.recommendation ?? 'Log how you feel after similar meals so GutGood can learn your unique patterns.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('WHAT TO DO NEXT', style: context.label.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        Gap.h16,
        Container(
          padding: EdgeInsets.all(AppSizes.p20),
          decoration: BoxDecoration(
            color: scheme.elevatedSurface,
            borderRadius: BorderRadius.circular(AppSizes.r24),
            border: Border.all(color: scheme.border.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSizes.p12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Icon(AppIcons.heartPulse, color: color, size: AppSizes.icon24),
              ),
              Gap.w20,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pattern.recommendation != null ? 'Recommendation' : 'Keep watching.', style: context.bodyBold),
                    Gap.h4,
                    Text(recommendation, style: context.caption.copyWith(color: scheme.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
