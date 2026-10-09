part of 'highlight_detail_screen.dart';

/// Trigger and recommended-action sections for the highlight detail page.

extension HighlightTriggerSections on HighlightDetailScreen {
  Widget _buildTriggerDetail(BuildContext context) {
    final theme = context.insightTheme;
    final insight = _highlightInsightOf(context);
    final pattern = insight?.detectedPatterns.where((p) => p.type.toLowerCase().contains('trigger') || p.reaction.isNotEmpty).firstOrNull;

    final loggedFoodName = pattern?.involvedFoods.isNotEmpty == true ? pattern!.involvedFoods.first : (pattern?.trigger.isNotEmpty == true ? pattern!.trigger : '');
    final foodName = loggedFoodName.isEmpty ? 'Food not identified' : loggedFoodName;

    final occurrences = pattern?.occurrences ?? const <PatternOccurrence>[];
    final observationCount = pattern == null ? 0 : (pattern.frequency > 0 ? pattern.frequency : occurrences.length);
    final isSingleObservation = observationCount == 1;

    final reactionText = pattern?.reaction.trim().isNotEmpty == true ? pattern!.reaction : 'Symptom not specified';
    final rawDelay = observationCount < 2 ? 'Building your baseline' : InsightFeedDerivations.reactionTime(insight ?? AIInsight(gutScore: 0, updatedAt: DateTime.now()), pattern);
    final delayText = (rawDelay.toLowerCase() == 'n/a' || rawDelay.toLowerCase() == 'not enough data yet' || rawDelay == '—' || rawDelay.isEmpty) ? 'Building your baseline.' : rawDelay;
    final evidenceLabel = pattern == null || observationCount == 0 ? 'No observation' : pattern.evidenceLabel;

    final title = pattern == null
        ? 'Food and symptom details'
        : isSingleObservation && loggedFoodName.isNotEmpty && reactionText != 'Symptom not specified'
        ? '$loggedFoodName and ${reactionText.toLowerCase()}'
        : 'Observed food and symptom timing';
    final bodyText = pattern == null || observationCount == 0
        ? 'There is not enough logged evidence to describe a food and symptom pattern yet.'
        : 'Your logs contain $observationCount matched observations involving $loggedFoodName and ${reactionText.toLowerCase()}. This association does not establish cause; missing follow-ups are unknown.';

    return Scaffold(
      backgroundColor: theme.scaffold,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          GutSliverAppBar(title: 'FOOD & SYMPTOM DETAILS', centerTitle: true, showBrandingIcon: false, backgroundColor: theme.scaffold),

          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w, 24.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. HERO TRIGGER CARD
                _buildTriggerHeroCard(
                  context,
                  foodName: foodName,
                  title: title,
                  bodyText: bodyText,
                  pattern: pattern,
                  hasFoodName: loggedFoodName.isNotEmpty,
                  isSingleObservation: isSingleObservation,
                  observationCount: observationCount,
                  reactionText: reactionText,
                  delayText: delayText,
                  evidenceLabel: evidenceLabel,
                ),
                Gap.h10,

                // 2. LATEST OBSERVATION SECTION
                _buildLatestObservationSection(context, occurrences: occurrences),
                Gap.h10,

                // 3. WANT A DIFFERENT OPTION? (Better Swaps)
                if (loggedFoodName.isNotEmpty) _buildBetterSwapsOptionCard(context, foodName: loggedFoodName),
                Gap.h12,
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// 1. Hero Trigger Card ("Something to Watch") in Pattern Card Style
  Widget _buildTriggerHeroCard(
    BuildContext context, {
    required String foodName,
    required String title,
    required String bodyText,
    required BodyPattern? pattern,
    required bool hasFoodName,
    required bool isSingleObservation,
    required int observationCount,
    required String reactionText,
    required String delayText,
    required String evidenceLabel,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final firstOccWithImage = pattern?.occurrences.firstWhere(
      (o) => o.imageUrl != null && o.imageUrl!.isNotEmpty,
      orElse: () => const PatternOccurrence(date: '', mealName: '', reaction: '', timeAfter: ''),
    );

    final foodImageUrl = firstOccWithImage?.imageUrl;

    final cardBg = isDark ? const Color(0xFF231416) : const Color(0xFFFFF8F6);
    final cardBorder = isDark ? const Color(0xFFEF4444).withValues(alpha: 0.45) : const Color(0xFFFCA5A5);
    final pillBg = isDark ? const Color(0xFFEF4444).withValues(alpha: 0.18) : const Color(0xFFFEE2E2);
    final pillFg = isDark ? const Color(0xFFF87171) : const Color(0xFF991B1B);

    final frequencyText = observationCount > 0 ? '$observationCount observation${observationCount == 1 ? '' : 's'}' : 'Not available';

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: cardBorder, width: 1.w),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626)).withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 10.w,
            offset: Offset(0, 2.w),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Content Section with Side Image
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.w, 16.w, 14.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag Pill
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.5.w),
                        decoration: BoxDecoration(
                          color: pillBg,
                          borderRadius: BorderRadius.circular(16.w),
                          border: Border.all(color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.35) : const Color(0xFFFECACA), width: 0.8.w),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.triangleAlert, size: 10.w, color: pillFg),
                            Gap.w4,
                            Text(
                              pattern == null
                                  ? 'NO MATCHING PATTERN'
                                  : isSingleObservation
                                  ? 'POSSIBLE CONNECTION'
                                  : 'OBSERVED IN LOGS',
                              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: pillFg),
                            ),
                          ],
                        ),
                      ),
                      Gap.h8,

                      // Title
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: InsightTheme.fontFamily,
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                          color: context.insightColor(const Color(0xFF0F172A)),
                          height: 1.15,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Gap.h4,

                      // Subtitle / Body Description
                      Text(
                        bodyText,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w400, color: context.insightColor(const Color(0xFF475569)), height: 1.3),
                      ),
                      Gap.h14,

                      // Bottom message / Pill
                      if (isSingleObservation)
                        Text(
                          '“Keep logging to see if this happens again.”',
                          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: pillFg, fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),
                Gap.w12,

                // Right Side Food Image Preview
                Container(
                  width: 90.w,
                  height: 90.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18.w),
                    border: Border.all(color: cardBorder, width: 1.w),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8.w, offset: Offset(0, 2.w))],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: !hasFoodName
                      ? Icon(LucideIcons.utensils, size: 28.w, color: pillFg)
                      : InsightUiKit.foodImage(
                          foodName,
                          imageUrl: foodImageUrl,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          placeholder: Container(color: context.insightColor(const Color(0xFFF1F5F9))),
                          errorWidget: Container(
                            color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.20) : const Color(0xFFFEE2E2),
                            child: Icon(LucideIcons.utensils, size: 28.w, color: pillFg),
                          ),
                        ),
                ),
              ],
            ),
          ),

          // Bottom Stats Bar (4 columns)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _TriggerStatCol(
                    icon: LucideIcons.barChart2,
                    iconBg: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.18) : const Color(0xFFFEE2E2),
                    iconColor: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                    label: 'Observations',
                    value: frequencyText,
                    subtext: pattern == null ? 'No matching pattern' : (pattern.timeframeDays > 0 ? 'Last ${pattern.timeframeDays} days' : 'Period unavailable'),
                  ),
                ),
                Gap.w4,

                Expanded(
                  child: _TriggerStatCol(
                    icon: LucideIcons.activity,
                    iconBg: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.18) : const Color(0xFFFEE2E2),
                    iconColor: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                    label: 'Reaction',
                    value: reactionText,
                    subtext: pattern == null ? 'No matching pattern' : 'Observed symptom',
                  ),
                ),
                Gap.w4,

                Expanded(
                  child: _TriggerStatCol(
                    icon: LucideIcons.clock,
                    iconBg: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.18) : const Color(0xFFFEE2E2),
                    iconColor: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                    label: 'Typical Delay',
                    value: delayText,
                    subtext: observationCount < 2 ? 'More logs needed' : 'Across observations',
                  ),
                ),
                Gap.w4,

                Expanded(
                  child: _TriggerStatCol(
                    icon: LucideIcons.leaf,
                    iconBg: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.18) : const Color(0xFFFEE2E2),
                    iconColor: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                    label: 'Evidence tier',
                    value: evidenceLabel,
                    subtext: observationCount < 2 ? 'Early observation' : 'Repeated log entries',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Latest Observation Section
  Widget _buildLatestObservationSection(BuildContext context, {required List<PatternOccurrence> occurrences}) {
    if (occurrences.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = context.insightTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final latest = occurrences.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: BoxDecoration(color: isDark ? theme.cardSubtle : const Color(0xFFF1F5F9), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Icon(LucideIcons.fileText, size: 14.w, color: theme.textPrimary),
                ),
                Gap.w8,
                Text(
                  'Latest Observation',
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: theme.textPrimary),
                ),
              ],
            ),
          ],
        ),
        Gap.h10,
        if (occurrences.length > 1)
          for (final o in occurrences.take(3)) ...[OccurrenceTile(occurrence: o), Gap.h8]
        else
          OccurrenceTile(occurrence: latest),
      ],
    );
  }

  /// 3. Better Swaps Option Card ("Want a different option?")
  Widget _buildBetterSwapsOptionCard(BuildContext context, {required String foodName}) {
    final theme = context.insightTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final insight = _highlightInsightOf(context);
    FoodSwap? matchingSwap;
    final targetName = foodName.toLowerCase().trim();
    for (final s in insight?.foodSwaps ?? <FoodSwap>[]) {
      if (s.source.name.toLowerCase().trim() == targetName) {
        matchingSwap = s;
        break;
      }
    }
    final swapObj =
        matchingSwap ??
        (insight?.foodSwaps.isNotEmpty == true
            ? insight!.foodSwaps.first
            : FoodSwap(
                id: 'swap_${foodName.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '_')}',
                source: SwapSource(foodId: 'food_trigger', name: foodName),
                alternatives: const [],
              ));

    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => BetterSwapsScreen(swap: swapObj)));
      },
      borderRadius: BorderRadius.circular(18.w),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(18.w),
          border: Border.all(color: isDark ? const Color(0xFF6366F1).withValues(alpha: 0.3) : const Color(0xFFE0E7FF), width: 1.w),
        ),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(color: isDark ? const Color(0xFF6366F1).withValues(alpha: 0.2) : const Color(0xFFE0E7FF), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(LucideIcons.repeat, size: 16.w, color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5)),
            ),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Want a different option?',
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 13.sp, fontWeight: FontWeight.w800, color: theme.textPrimary),
                  ),
                  Gap.h2,
                  Text(
                    'Explore better swaps for this food and find options that may work better for you.',
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, color: theme.textSecondary),
                  ),
                ],
              ),
            ),
            Gap.w8,
            Icon(LucideIcons.chevronRight, size: 16.w, color: theme.textSecondary),
          ],
        ),
      ),
    );
  }
}
