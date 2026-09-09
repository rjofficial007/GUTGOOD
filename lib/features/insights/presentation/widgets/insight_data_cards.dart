import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';

/// Colorful data cards for the Insights discover feed.
///
/// Each card surfaces a slice of [AIInsight] that the score header, hero and
/// quadrant grid don't show: the healing goal, top-insight evidence, healing
/// vs trigger foods, the weekly recap and the remaining patterns. Colors are
/// meaningful (green = healing, red = watch, amber = moderate, blue = info)
/// and assigned by the app, never by the AI. Cards render nothing when their
/// slice is empty — the feed never shows placeholder content.

/// Healing goal banner (blue): the primary objective for this period.
class InsightGoalCard extends StatelessWidget {
  const InsightGoalCard({super.key, required this.data});
  final AIInsight data;

  @override
  Widget build(BuildContext context) {
    final goal = data.healingGoal?.trim() ?? '';
    if (goal.isEmpty) return const SizedBox.shrink();
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? scheme.softInfo : const Color(0xFFEBF4FF);
    final accent = isDark ? scheme.info : const Color(0xFF1673D4);
    return InkWell(
      onTap: () => context.push(AppRoutes.insightDetail, extra: data),
      borderRadius: BorderRadius.circular(AppSizes.r24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppSizes.r24)),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: isDark ? scheme.info.withAlpha(40) : const Color(0xFFD8E9FF), shape: BoxShape.circle),
              child: Icon(AppIcons.target, size: 22, color: accent),
            ),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.activeGoal.toUpperCase(), style: context.captionBold.copyWith(fontSize: 11.sp, letterSpacing: 1.0, color: accent)),
                  Gap.h4,
                  Text(goal, style: context.bodyBold.copyWith(fontSize: 15.sp, height: 1.3), maxLines: 3, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Gap.w8,
            Icon(AppIcons.chevronRight, size: 18, color: accent),
          ],
        ),
      ),
    );
  }
}

/// Top-insight evidence card, tinted by strength (green High, amber Moderate,
/// blue Early): title, description, observed-vs-total evidence bar, involved
/// foods and next steps.
class InsightEvidenceCard extends StatelessWidget {
  const InsightEvidenceCard({super.key, required this.data});
  final AIInsight data;

  @override
  Widget build(BuildContext context) {
    final top = data.topInsight;
    if (top == null || top.title.trim().isEmpty) return const SizedBox.shrink();
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strength = top.strength?.trim().toLowerCase() ?? '';

    late final Color background;
    late final Color accent;
    late final Color chip;
    if (strength.startsWith('high')) {
      background = isDark ? scheme.softSuccess : const Color(0xFFF0FAF2);
      accent = isDark ? scheme.success : const Color(0xFF278A5C);
      chip = isDark ? scheme.success.withAlpha(40) : const Color(0xFFDDF4E4);
    } else if (strength.startsWith('moder')) {
      background = isDark ? scheme.softWarning : const Color(0xFFFFF5E4);
      accent = isDark ? scheme.warning : const Color(0xFFC07A1A);
      chip = isDark ? scheme.warning.withAlpha(40) : const Color(0xFFFBE8C8);
    } else {
      background = isDark ? scheme.softInfo : const Color(0xFFEFF7FF);
      accent = isDark ? scheme.info : const Color(0xFF1673D4);
      chip = isDark ? scheme.info.withAlpha(40) : const Color(0xFFDCEEFF);
    }

    final pos = top.positiveCount ?? 0;
    final neg = top.negativeCount ?? 0;
    final total = pos + neg;
    final foods = top.involvedFoods.where((f) => f.trim().isNotEmpty).take(4).toList();
    final steps = top.nextSteps.where((s) => s.trim().isNotEmpty).take(3).toList();
    final observation = top.observation?.trim() ?? '';

    return InkWell(
      onTap: () => context.push(AppRoutes.smartInsightDetail, extra: top),
      borderRadius: BorderRadius.circular(AppSizes.r24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppSizes.r24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: chip, shape: BoxShape.circle),
                  child: Icon(AppIcons.shieldCheck, size: 20, color: accent),
                ),
                Gap.w10,
                Expanded(
                  child: Text(top.title, style: context.bodyBold.copyWith(fontSize: 16.sp, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
                if (top.strength?.trim().isNotEmpty ?? false) ...[
                  Gap.w8,
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: chip, borderRadius: BorderRadius.circular(AppSizes.r100)),
                    child: Text(top.strength!.trim(), style: context.captionBold.copyWith(fontSize: 11.sp, color: accent)),
                  ),
                ],
              ],
            ),
            if (top.description.trim().isNotEmpty) ...[
              Gap.h8,
              Text(top.description.trim(), style: context.bodySm.copyWith(fontSize: 13.sp, height: 1.4, color: scheme.textSecondary), maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
            if (total > 0) ...[
              Gap.h10,
              Row(
                children: [
                  Text(
                    AppStrings.evidenceTimes(pos, total),
                    style: context.captionBold.copyWith(fontSize: 12.sp, color: accent),
                  ),
                  const Spacer(),
                  Text('${((pos / total) * 100).round()}%', style: context.captionBold.copyWith(fontSize: 12.sp, color: scheme.textSecondary)),
                ],
              ),
              Gap.h6,
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.r100),
                child: SizedBox(
                  height: 8,
                  child: Row(
                    children: [
                      if (pos > 0) Expanded(flex: pos, child: Container(color: isDark ? scheme.success : const Color(0xFF35A56C))),
                      if (neg > 0) Expanded(flex: neg, child: Container(color: isDark ? scheme.error : const Color(0xFFE86A5E))),
                    ],
                  ),
                ),
              ),
            ],
            if (observation.isNotEmpty) ...[
              Gap.h8,
              Text(
                '"$observation"',
                style: context.bodySm.copyWith(fontSize: 12.sp, height: 1.4, fontStyle: FontStyle.italic, color: scheme.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (foods.isNotEmpty) ...[
              Gap.h10,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final f in foods) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: chip, borderRadius: BorderRadius.circular(AppSizes.r100)), child: Text(f.trim(), style: context.captionBold.copyWith(fontSize: 11.sp, color: accent)))],
              ),
            ],
            if (steps.isNotEmpty) ...[
              Gap.h10,
              Text(AppStrings.nextStepsTitle.toUpperCase(), style: context.captionBold.copyWith(fontSize: 11.sp, letterSpacing: 1.0, color: accent)),
              Gap.h6,
              for (final s in steps)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(padding: const EdgeInsets.only(top: 1), child: Icon(AppIcons.checkCircle2, size: 15, color: accent)),
                      Gap.w8,
                      Expanded(child: Text(s.trim(), style: context.bodySm.copyWith(fontSize: 13.sp, height: 1.35), maxLines: 2, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Healing (green) vs trigger (red) foods split card, with the tracked
/// symptom named on the trigger half when present.
class InsightFoodsCard extends StatelessWidget {
  const InsightFoodsCard({super.key, required this.data});
  final AIInsight data;

  @override
  Widget build(BuildContext context) {
    final healing = data.healingFoods.where((f) => f.name.trim().isNotEmpty).take(3).toList();
    final trigger = data.triggerFoods.where((f) => f.name.trim().isNotEmpty).take(3).toList();
    if (healing.isEmpty && trigger.isEmpty) return const SizedBox.shrink();
    return InkWell(
      onTap: () => context.push(AppRoutes.insightDetail, extra: data),
      borderRadius: BorderRadius.circular(AppSizes.r24),
      child: Column(
        children: [
          if (healing.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? context.appColorScheme.softSuccess : const Color(0xFFF0FAF2),
                borderRadius: BorderRadius.vertical(top: const Radius.circular(24), bottom: Radius.circular(trigger.isNotEmpty ? 0 : 24)),
              ),
              child: _FoodGroup(icon: AppIcons.leaf, title: AppStrings.healingFoodsTitle, names: [for (final f in healing) (f.name.trim(), f.effect.trim())], positive: true),
            ),
          if (trigger.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? context.appColorScheme.softError : const Color(0xFFFFEFF0),
                borderRadius: BorderRadius.vertical(top: Radius.circular(healing.isNotEmpty ? 0 : 24), bottom: const Radius.circular(24)),
              ),
              child: _FoodGroup(
                icon: AppIcons.flame,
                title: AppStrings.triggerFoodsTitle,
                names: [for (final f in trigger) (f.name.trim(), f.effect.trim())],
                positive: false,
                symptom: data.triggerSymptom?.trim() ?? '',
              ),
            ),
        ],
      ),
    );
  }
}

class _FoodGroup extends StatelessWidget {
  const _FoodGroup({required this.icon, required this.title, required this.names, required this.positive, this.symptom = ''});
  final IconData icon;
  final String title;
  final List<(String, String)> names;
  final bool positive;
  final String symptom;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = positive ? (isDark ? scheme.success : const Color(0xFF278A5C)) : (isDark ? scheme.error : const Color(0xFFD33B32));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: accent),
            Gap.w8,
            Expanded(child: Text(title.toUpperCase(), style: context.captionBold.copyWith(fontSize: 11.sp, letterSpacing: 1.0, color: accent))),
          ],
        ),
        if (symptom.isNotEmpty) ...[
          Gap.h6,
          Row(
            children: [
              Icon(AppIcons.alertTriangle, size: 14, color: accent),
              Gap.w6,
              Expanded(child: Text(symptom, style: context.bodyBold.copyWith(fontSize: 13.sp, color: scheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ],
        Gap.h8,
        for (final (name, effect) in names)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(padding: const EdgeInsets.only(top: 6), child: Container(width: 6, height: 6, decoration: BoxDecoration(color: accent, shape: BoxShape.circle))),
                Gap.w8,
                Expanded(child: Text(name, style: context.bodyBold.copyWith(fontSize: 14.sp), maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (effect.isNotEmpty) ...[
                  Gap.w8,
                  Flexible(child: Text(effect, style: context.bodySm.copyWith(fontSize: 12.sp, color: scheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right)),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// Weekly recap card (lavender): best day, foods logged and highlights.
class InsightRecapCard extends StatelessWidget {
  const InsightRecapCard({super.key, required this.data});
  final AIInsight data;

  @override
  Widget build(BuildContext context) {
    final recap = data.weeklyRecap;
    if (recap == null) return const SizedBox.shrink();
    final bestDay = recap.bestDay.trim();
    final highlights = recap.highlights.where((h) => h.text.trim().isNotEmpty).take(3).toList();
    // scoreSub-only recaps duplicate the score header caption — hide those.
    if (bestDay.isEmpty && recap.foodsLogged <= 0 && highlights.isEmpty && recap.dateRange.trim().isEmpty) return const SizedBox.shrink();
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? scheme.lavender : const Color(0xFFF2F1FF);
    final accent = isDark ? scheme.lavenderDark : const Color(0xFF5544B6);
    final tile = isDark ? Colors.white.withAlpha(30) : Colors.white.withAlpha(200);
    return InkWell(
      onTap: () => context.push(AppRoutes.weeklyRecap, extra: data),
      borderRadius: BorderRadius.circular(AppSizes.r24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppSizes.r24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(AppIcons.calendar, size: 18, color: accent),
                Gap.w8,
                Expanded(child: Text(AppStrings.weeklyHighlights, style: context.bodyBold.copyWith(fontSize: 15.sp))),
                if (recap.dateRange.trim().isNotEmpty)
                  Text(recap.dateRange.trim(), style: context.caption.copyWith(fontSize: 11.sp, color: scheme.textSecondary)),
              ],
            ),
            if (bestDay.isNotEmpty || recap.foodsLogged > 0) ...[
              Gap.h10,
              Row(
                children: [
                  if (bestDay.isNotEmpty)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(color: tile, borderRadius: BorderRadius.circular(AppSizes.r16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [Icon(AppIcons.sparkles, size: 13, color: accent), Gap.w4, Text(AppStrings.bestDayLabel.toUpperCase(), style: context.captionBold.copyWith(fontSize: 10.sp, letterSpacing: 0.8, color: accent))]),
                            Gap.h4,
                            Text(bestDay, style: context.bodyBold.copyWith(fontSize: 14.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ),
                  if (bestDay.isNotEmpty && recap.foodsLogged > 0) Gap.w10,
                  if (recap.foodsLogged > 0)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(color: tile, borderRadius: BorderRadius.circular(AppSizes.r16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [Icon(AppIcons.clipboardList, size: 13, color: accent), Gap.w4, Text(AppStrings.foodsLogged.toUpperCase(), style: context.captionBold.copyWith(fontSize: 10.sp, letterSpacing: 0.8, color: accent))]),
                            Gap.h4,
                            Text('${recap.foodsLogged}', style: context.bodyBold.copyWith(fontSize: 14.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (highlights.isNotEmpty) ...[
              Gap.h10,
              for (final h in highlights)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(padding: const EdgeInsets.only(top: 1), child: Icon(AppIcons.checkCircle2, size: 15, color: accent)),
                      Gap.w8,
                      Expanded(child: Text(h.text.trim(), style: context.bodySm.copyWith(fontSize: 13.sp, height: 1.35), maxLines: 2, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact rows for the remaining prioritized patterns (the hero shows the
/// first). Confidence drives the icon tint: green High, amber Medium, blue Low.
class InsightPatternsSection extends StatelessWidget {
  const InsightPatternsSection({super.key, required this.patterns});
  final List<BodyPattern> patterns;

  @override
  Widget build(BuildContext context) {
    final items = patterns.skip(1).take(4).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    final scheme = context.appColorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(AppStrings.observedPatterns, style: context.displayMd.copyWith(fontSize: 17.sp, letterSpacing: -0.3, color: scheme.textPrimary)),
        ),
        for (final p in items) ...[
          _PatternRow(pattern: p),
          Gap.h10,
        ],
      ],
    );
  }
}

class _PatternRow extends StatelessWidget {
  const _PatternRow({required this.pattern});
  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    late final Color tint;
    late final Color accent;
    if (pattern.confidence == BodyPattern.confidenceHigh) {
      tint = isDark ? scheme.success.withAlpha(40) : const Color(0xFFDDF4E4);
      accent = isDark ? scheme.success : const Color(0xFF278A5C);
    } else if (pattern.confidence == BodyPattern.confidenceMedium) {
      tint = isDark ? scheme.warning.withAlpha(40) : const Color(0xFFFBE8C8);
      accent = isDark ? scheme.warning : const Color(0xFFC07A1A);
    } else {
      tint = isDark ? scheme.info.withAlpha(40) : const Color(0xFFDCEEFF);
      accent = isDark ? scheme.info : const Color(0xFF1673D4);
    }
    final trigger = pattern.trigger.trim();
    final reaction = pattern.reaction.trim();
    final headline = (trigger.isEmpty || reaction.isEmpty) ? pattern.description : '$trigger → $reaction';
    return InkWell(
      onTap: () => context.push(AppRoutes.patternDetail, extra: pattern),
      borderRadius: BorderRadius.circular(AppSizes.r20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.cardBackground,
          borderRadius: BorderRadius.circular(AppSizes.r20),
          border: Border.all(color: isDark ? scheme.border : const Color(0xFFE7E8EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
              child: Icon(InsightUiUtils.getPatternTypeIcon(pattern.type), size: 21, color: accent),
            ),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(headline, style: context.bodyBold.copyWith(fontSize: 14.sp, height: 1.25), maxLines: 2, overflow: TextOverflow.ellipsis),
                  Gap.h2,
                  Text(
                    '${pattern.confidence} • ${AppStrings.patternFrequencyTimes(pattern.frequency, pattern.timeframeDays)}',
                    style: context.caption.copyWith(fontSize: 11.sp, color: scheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Gap.w8,
            Icon(AppIcons.chevronRight, size: 17, color: scheme.textMuted),
          ],
        ),
      ),
    );
  }
}
