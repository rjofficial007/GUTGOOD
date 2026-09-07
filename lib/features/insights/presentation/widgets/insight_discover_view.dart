import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/models/health_alert.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/gut_score_utils.dart';
import 'package:gutgood/core/utils/image_utils.dart';
import 'package:gutgood/core/utils/insight_ui_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';

String _upperFirst(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
String _lowerFirst(String s) => s.isEmpty ? s : '${s[0].toLowerCase()}${s.substring(1)}';

/// Discover-style Insights feed: a compact score header with a 7-day chart,
/// a hero pattern card, a tappable quadrant grid (improving / watch / rest /
/// working) and a top-foods strip.
///
/// Every card routes to an existing detail screen. Sections with no data are
/// hidden instead of showing demo content.
class InsightDiscoverSliver extends StatelessWidget {
  const InsightDiscoverSliver({super.key, required this.data, required this.notifier, this.patterns = const []});

  final AIInsight data;
  final InsightsNotifier notifier;
  final List<BodyPattern> patterns;

  @override
  Widget build(BuildContext context) {
    final hero = patterns.isNotEmpty ? patterns.first : null;
    final quads = _buildQuadCards(context, hero);

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(AppSizes.p16, AppSizes.p8, AppSizes.p16, AppSizes.p24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardEntrance(
              delay: 0,
              child: _ScoreHeader(data: data, notifier: notifier),
            ),
            if (hero != null) ...[Gap.h12, DashboardEntrance(delay: 80, child: _PatternHero(pattern: hero))],
            if (quads.isNotEmpty) ...[
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.92,
                children: [for (var i = 0; i < quads.length; i++) DashboardEntrance(delay: 120 + i * 60, child: quads[i])],
              ),
            ],
            Gap.h12,
            DashboardEntrance(
              delay: 220,
              child: _TopFoodsSection(data: data, patterns: patterns),
            ),
          ],
        ),
      ),
    );
  }

  List<_QuadCard> _buildQuadCards(BuildContext context, BodyPattern? hero) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cards = <_QuadCard>[];

    final improving = _improvingCopy();
    if (improving != null) {
      cards.add(
        _QuadCard(
          icon: AppIcons.leaf,
          background: isDark ? scheme.softSuccess : const Color(0xFFF0FAF2),
          iconBackground: isDark ? scheme.success.withAlpha(40) : const Color(0xFFDDF4E4),
          iconColor: isDark ? scheme.success : const Color(0xFF278A5C),
          title: improving.title,
          value: improving.headline,
          highlightValue: improving.metric,
          description: improving.body,
          onTap: () => context.push(AppRoutes.weeklyRecap, extra: data),
        ),
      );
    }

    final alerts = notifier.healthAlerts;
    HealthAlert? alert;
    for (final a in alerts) {
      if (!a.isRead) {
        alert = a;
        break;
      }
    }
    alert ??= alerts.isNotEmpty ? alerts.first : null;
    if (alert != null) {
      cards.add(
        _QuadCard(
          icon: AppIcons.alertTriangle,
          background: isDark ? scheme.softError : const Color(0xFFFFEFF0),
          iconBackground: isDark ? scheme.error.withAlpha(40) : const Color(0xFFFFDCDD),
          iconColor: isDark ? scheme.error : const Color(0xFFD33B32),
          title: AppStrings.somethingToWatch,
          value: alert.title,
          description: alert.message,
          onTap: () => context.push(AppRoutes.notificationArchive),
        ),
      );
    } else {
      final trigger = data.topTrigger;
      final fallbackHeadline = (trigger != null && trigger.food.isNotEmpty) ? trigger.food : data.triggerTrend;
      if (fallbackHeadline != null && fallbackHeadline.isNotEmpty) {
        cards.add(
          _QuadCard(
            icon: AppIcons.alertTriangle,
            background: isDark ? scheme.softError : const Color(0xFFFFEFF0),
            iconBackground: isDark ? scheme.error.withAlpha(40) : const Color(0xFFFFDCDD),
            iconColor: isDark ? scheme.error : const Color(0xFFD33B32),
            title: AppStrings.somethingToWatch,
            value: fallbackHeadline,
            description: trigger?.effects ?? '',
            onTap: () => context.push(AppRoutes.weeklyRecap, extra: data),
          ),
        );
      }
    }

    final rest = _restPattern(hero);
    if (rest != null) {
      final isSleep = rest.type.toLowerCase().contains('sleep');
      cards.add(
        _QuadCard(
          icon: AppIcons.moon,
          background: isDark ? scheme.lavender : const Color(0xFFF2F1FF),
          iconBackground: isDark ? scheme.lavenderDark.withAlpha(40) : const Color(0xFFE2E0FF),
          iconColor: isDark ? scheme.lavenderDark : const Color(0xFF5544B6),
          title: isSleep ? AppStrings.restSleepTitle : AppStrings.restEnergyTitle,
          value: '${rest.trigger} → ${rest.reaction}',
          description: rest.description,
          onTap: () => context.push(AppRoutes.patternDetail, extra: rest),
        ),
      );
    }

    final top = data.topInsight;
    if (top != null) {
      cards.add(
        _QuadCard(
          icon: AppIcons.zap,
          background: isDark ? scheme.softInfo : const Color(0xFFEFF7FF),
          iconBackground: isDark ? scheme.info.withAlpha(40) : const Color(0xFFDCEEFF),
          iconColor: isDark ? scheme.info : const Color(0xFF1673D4),
          title: AppStrings.whatsWorking,
          value: top.title,
          description: top.description,
          onTap: () => context.push(AppRoutes.smartInsightDetail, extra: top),
        ),
      );
    }

    return cards;
  }

  ({String title, String headline, String body, bool metric})? _improvingCopy() {
    final top = data.topHealing;
    if (top != null && top.food.isNotEmpty) {
      final title = AppStrings.youAteMoreThisWeek(_lowerFirst(top.food.trim()));
      final frequency = top.frequency.trim();
      if (frequency.isNotEmpty) {
        return (title: title, headline: '↑ $frequency', body: top.effects, metric: true);
      }
      final headline = top.effects.trim().isNotEmpty ? top.effects : (data.healingTrend ?? '');
      if (headline.isEmpty) return null;
      return (title: title, headline: headline, body: '', metric: false);
    }
    final trend = data.healingTrend;
    if (trend != null && trend.isNotEmpty) {
      return (title: AppStrings.whatsImproving, headline: trend, body: '', metric: false);
    }
    if (data.healingFoods.isNotEmpty) {
      final first = data.healingFoods.first;
      if (first.effect.isEmpty) return null;
      return (title: AppStrings.youAteMoreThisWeek(_lowerFirst(first.name.trim())), headline: first.effect, body: '', metric: false);
    }
    return null;
  }

  BodyPattern? _restPattern(BodyPattern? hero) {
    for (final p in patterns) {
      if (hero != null && p.trigger == hero.trigger && p.type == hero.type) continue;
      final type = p.type.toLowerCase();
      if (type.contains('sleep') || type.contains('energy')) return p;
    }
    return null;
  }
}

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader({required this.data, required this.notifier});
  final AIInsight data;
  final InsightsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileNotifier = context.watch<ProfileNotifier>();
    final profileScore = profileNotifier.profile?.gutScore ?? 0;
    final score = profileScore > 0 ? profileScore : profileNotifier.avgFoodScore;
    final band = GutScoreBand.fromScore(score);
    final diff = _parseDiff(data.scoreDiff);
    final bars = _weekBars();
    final recapSub = data.weeklyRecap?.scoreSub ?? '';
    final caption = recapSub.isNotEmpty ? recapSub : (data.healingTrend ?? '');

    return InkWell(
      onTap: () => context.push(AppRoutes.weeklyRecap, extra: data),
      borderRadius: BorderRadius.circular(AppSizes.r24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
        decoration: BoxDecoration(
          color: scheme.cardBackground,
          borderRadius: BorderRadius.circular(AppSizes.r24),
          border: Border.all(color: isDark ? scheme.border : const Color(0xFFE8E9EC), width: 1.2),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 15, offset: const Offset(0, 4))],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 56,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            AppStrings.yourGutGoodScore,
                            style: context.bodyBold.copyWith(fontSize: 14.sp, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                          ),
                        ),
                        Gap.w8,
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF7C8491), width: 1.5),
                          ),
                          child: const Center(
                            child: Text(
                              'i',
                              style: TextStyle(fontSize: 11, color: Color(0xFF707887), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Gap.h8,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('$score', style: context.displayMd.copyWith(fontSize: 46.sp, height: 1.0, letterSpacing: -1.5)),
                        if (diff != null && diff != 0) ...[
                          Gap.w8,
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _DiffPill(diff: diff),
                                Gap.h4,
                                Text(
                                  AppStrings.fromLastWeek,
                                  style: context.bodySm.copyWith(fontSize: 12.sp, color: scheme.textSecondary),
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Gap.h10,
                    Container(
                      height: 8,
                      decoration: BoxDecoration(color: isDark ? Colors.white.withAlpha(16) : const Color(0xFFF0F0F3), borderRadius: BorderRadius.circular(AppSizes.r100)),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: (score / 100).clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(color: band.color, borderRadius: BorderRadius.circular(AppSizes.r100)),
                          ),
                        ),
                      ),
                    ),
                    if (caption.isNotEmpty) ...[
                      Gap.h8,
                      Text(
                        caption,
                        style: context.bodySm.copyWith(fontSize: 12.sp, height: 1.35, color: scheme.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (bars.length >= 2) ...[
                Gap.w10,
                Expanded(
                  flex: 42,
                  child: _WeekChart(bars: bars, diff: diff),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  int? _parseDiff(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return int.tryParse(raw.replaceAll('+', '').trim());
  }

  List<_DayBar> _weekBars() {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final items = notifier.insightHistory.take(7).toList().reversed.toList();
    return [for (final item in items) _DayBar(score: item.gutScore, label: labels[item.updatedAt.weekday - 1])];
  }
}

class _DayBar {
  const _DayBar({required this.score, required this.label});
  final int score;
  final String label;
}

class _DiffPill extends StatelessWidget {
  const _DiffPill({required this.diff});
  final int diff;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final up = diff > 0;
    final color = up ? (isDark ? scheme.success : const Color(0xFF299564)) : scheme.error;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p4),
      decoration: BoxDecoration(
        color: up ? (isDark ? scheme.successSubtle : const Color(0xFFE4F6EC)) : (isDark ? scheme.softError : const Color(0xFFFFE4E0)),
        borderRadius: BorderRadius.circular(AppSizes.r100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            up ? '↑' : '↓',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: color),
          ),
          Gap.w4,
          Text(
            '${diff.abs()}',
            style: context.captionBold.copyWith(fontSize: 13.sp, color: color),
          ),
        ],
      ),
    );
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.bars, required this.diff});
  final List<_DayBar> bars;
  final int? diff;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showChip = (diff ?? 0) > 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      decoration: BoxDecoration(color: isDark ? scheme.softSuccess : const Color(0xFFF1F9F3), borderRadius: BorderRadius.circular(AppSizes.r20)),
      child: Column(
        children: [
          if (showChip)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: isDark ? scheme.success.withAlpha(35) : const Color(0xFFD9F2E2), borderRadius: BorderRadius.circular(AppSizes.r100)),
              child: Text(
                AppStrings.scoreUpChip,
                style: context.captionBold.copyWith(fontSize: 11.sp, color: isDark ? scheme.success : const Color(0xFF299564)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (showChip) Gap.h8,
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < bars.length; i++)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            // NOTE: no widthFactor — the Row above gives unbounded width,
                            // so widthFactor would compute 1 x Infinity and crash layout.
                            // The bar width comes from the fixed-width Container below.
                            heightFactor: (bars[i].score / 100).clamp(0.12, 1.0),
                            child: Container(
                              width: 12,
                              decoration: BoxDecoration(
                                color: i == bars.length - 1 ? (isDark ? scheme.success : const Color(0xFF4EAB78)) : (isDark ? scheme.success.withAlpha(70) : const Color(0xFFD7E9DB)),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Gap.h6,
                      Text(
                        bars[i].label,
                        style: context.caption.copyWith(fontSize: 10.sp, fontWeight: FontWeight.w500, color: scheme.textSecondary),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternHero extends StatelessWidget {
  const _PatternHero({required this.pattern});
  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF3A2A1E) : const Color(0xFFFFF0E5);
    final accent = isDark ? scheme.warning : const Color(0xFFD35F27);

    return InkWell(
      onTap: () => context.push(AppRoutes.patternDetail, extra: pattern),
      borderRadius: BorderRadius.circular(AppSizes.r24),
      child: LayoutBuilder(
        builder: (context, constraints) => Container(
          constraints: const BoxConstraints(minHeight: 150),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppSizes.r24)),
          child: Stack(
            children: [
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: constraints.maxWidth * 0.44,
                child: _HeroVisual(pattern: pattern),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [background, background.withAlpha(250), background.withAlpha(77), Colors.transparent],
                      stops: const [0.0, 0.43, 0.68, 1.0],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.patternWeNoticed,
                      style: context.captionBold.copyWith(fontSize: 11.sp, letterSpacing: 1.0, color: accent),
                    ),
                    Gap.h6,
                    Text(
                      _headline(),
                      style: context.displayMd.copyWith(fontSize: 20.sp, height: 1.15, letterSpacing: -0.3, color: scheme.textPrimary),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap.h6,
                    Text(
                      AppStrings.patternFrequencyTimes(pattern.frequency, pattern.timeframeDays),
                      style: context.bodySm.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w500, color: scheme.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap.h10,
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: scheme.cardBackground, shape: BoxShape.circle),
                          child: Icon(AppIcons.arrowRight, size: 18, color: isDark ? scheme.textPrimary : const Color(0xFF162033)),
                        ),
                        Gap.w10,
                        Flexible(
                          child: Text(
                            AppStrings.exploreThisPattern,
                            style: context.bodyBold.copyWith(fontSize: 14.sp, fontWeight: FontWeight.w600, color: scheme.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _headline() {
    final trigger = pattern.trigger.trim();
    final reaction = pattern.reaction.trim();
    if (trigger.isEmpty || reaction.isEmpty) return pattern.description;
    return AppStrings.patternHeadline(_upperFirst(trigger), _lowerFirst(reaction));
  }
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual({required this.pattern});
  final BodyPattern pattern;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fallback = Container(
      color: isDark ? const Color(0xFF3A2A1E) : const Color(0xFFF7DCC8),
      child: Center(child: Icon(InsightUiUtils.getPatternTypeIcon(pattern.type), size: 46, color: isDark ? scheme.warning : const Color(0xFFD35F27))),
    );
    final photo = _photoUrl();
    if (photo == null) return fallback;
    return Image.network(photo, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback);
  }

  String? _photoUrl() {
    for (final o in pattern.occurrences) {
      if (o.imageUrl != null && o.imageUrl!.isNotEmpty) return o.imageUrl;
    }
    return null;
  }
}

class _QuadCard extends StatelessWidget {
  const _QuadCard({
    required this.icon,
    required this.background,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.description,
    required this.onTap,
    this.highlightValue = false,
  });

  final IconData icon;
  final Color background;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String value;
  final String description;
  final VoidCallback onTap;
  final bool highlightValue;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.r24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppSizes.r24)),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: iconBackground, shape: BoxShape.circle),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                Gap.h8,
                Text(
                  title,
                  style: context.bodyBold.copyWith(fontSize: 14.sp, height: 1.15, color: scheme.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Gap.h6,
                Text(
                  value,
                  style: context.displayMd.copyWith(
                    fontSize: 17.sp,
                    height: 1.1,
                    letterSpacing: -0.5,
                    color: highlightValue ? (isDark ? scheme.success : const Color(0xFF278A5C)) : scheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description.isNotEmpty) ...[
                  Gap.h6,
                  Expanded(
                    child: Text(
                      description,
                      style: context.bodySm.copyWith(fontSize: 12.sp, height: 1.25, color: scheme.textSecondary),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(color: isDark ? Colors.white.withAlpha(40) : Colors.white.withAlpha(165), shape: BoxShape.circle),
                child: Icon(AppIcons.arrowRight, size: 16, color: isDark ? scheme.textPrimary : const Color(0xFF5B6473)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopFoodsSection extends StatelessWidget {
  const _TopFoodsSection({required this.data, required this.patterns});
  final AIInsight data;
  final List<BodyPattern> patterns;

  @override
  Widget build(BuildContext context) {
    final foods = _collectFoods();
    if (foods.isEmpty) return const SizedBox.shrink();
    final scheme = context.appColorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppStrings.topFoodsThisWeek,
              style: context.displayMd.copyWith(fontSize: 17.sp, letterSpacing: -0.3, color: scheme.textPrimary),
            ),
            const Spacer(),
            InkWell(
              onTap: () => context.go(AppRoutes.history),
              borderRadius: BorderRadius.circular(AppSizes.r8),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.seeAll,
                      style: context.bodySm.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w500, color: scheme.textSecondary),
                    ),
                    Gap.w2,
                    Icon(AppIcons.chevronRight, size: 16, color: scheme.textSecondary),
                  ],
                ),
              ),
            ),
          ],
        ),
        Gap.h10,
        SizedBox(
          height: 178,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: foods.length,
            separatorBuilder: (_, __) => Gap.w12,
            itemBuilder: (context, index) {
              final food = foods[index];
              return _FoodCard(food: food, onTap: () => _openFood(context, food));
            },
          ),
        ),
      ],
    );
  }

  List<_TopFood> _collectFoods() {
    final impacts = data.foodImpacts;
    if (impacts.isNotEmpty) {
      final counts = <String, int>{};
      final firstSeen = <String, FoodImpact>{};
      for (final impact in impacts) {
        final key = impact.food.toLowerCase().trim();
        if (key.isEmpty) continue;
        counts[key] = (counts[key] ?? 0) + 1;
        firstSeen.putIfAbsent(key, () => impact);
      }
      final entries = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return [
        for (final entry in entries.take(8))
          _TopFood(
            name: firstSeen[entry.key]!.food,
            subtitle: AppStrings.scansCount(entry.value),
            isPositive: firstSeen[entry.key]!.impactType.toLowerCase() != 'negative',
            imageUrl: firstSeen[entry.key]!.imageUrl,
          ),
      ];
    }
    final foods = <_TopFood>[
      for (final f in data.healingFoods) _TopFood(name: f.name, subtitle: f.effect, isPositive: true, imageUrl: f.imageUrl),
      for (final f in data.triggerFoods) _TopFood(name: f.name, subtitle: f.effect, isPositive: false, imageUrl: f.imageUrl),
    ];
    return foods.take(8).toList();
  }

  void _openFood(BuildContext context, _TopFood food) {
    final name = food.name.toLowerCase();
    if (name.isNotEmpty) {
      for (final pattern in patterns) {
        final inFoods = pattern.involvedFoods.any((f) => f.toLowerCase() == name);
        final trigger = pattern.trigger.toLowerCase();
        if (inFoods || (trigger.isNotEmpty && (trigger.contains(name) || name.contains(trigger)))) {
          context.push(AppRoutes.patternDetail, extra: pattern);
          return;
        }
      }
    }
    context.go(AppRoutes.history);
  }
}

class _TopFood {
  const _TopFood({required this.name, required this.subtitle, required this.isPositive, this.imageUrl});
  final String name;
  final String subtitle;
  final bool isPositive;
  final String? imageUrl;
}

class _FoodCard extends StatelessWidget {
  const _FoodCard({required this.food, required this.onTap});
  final _TopFood food;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = food.isPositive ? (isDark ? scheme.success : const Color(0xFF268A59)) : (isDark ? scheme.error : const Color(0xFFD64B3D));
    final bg = food.isPositive ? (isDark ? scheme.softSuccess : const Color(0xFFE1F5E8)) : (isDark ? scheme.softError : const Color(0xFFFFE4E0));
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.r20),
      child: Container(
        width: 116,
        decoration: BoxDecoration(
          color: scheme.cardBackground,
          borderRadius: BorderRadius.circular(AppSizes.r20),
          border: Border.all(color: isDark ? scheme.border : const Color(0xFFE7E8EB)),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(9), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 80,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: (food.imageUrl != null && food.imageUrl!.isNotEmpty) ? food.imageUrl! : getDynamicImageUrl(food.name),
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  color: bg,
                  child: Center(child: Icon(food.isPositive ? AppIcons.salad : AppIcons.alertTriangle, size: 28, color: accent)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: context.bodyBold.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap.h2,
                  Text(
                    food.subtitle,
                    style: context.caption.copyWith(fontSize: 11.sp, color: scheme.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap.h6,
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppSizes.r20)),
                    child: Text(
                      food.isPositive ? AppStrings.positiveLabel : AppStrings.watchLabel,
                      style: context.captionBold.copyWith(fontSize: 11.sp, color: accent),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
