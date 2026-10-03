part of 'synergy_detail_screen.dart';

/// Synergy detail sections and evidence presentation.

extension SynergyDetailSections on SynergyDetailScreen {
  /// 1. Top Hero Pattern Card (Ultra-Polished Bento Style)
  Widget _buildHeroCard(BuildContext context, BodyPattern? pattern, AIInsight? activeInsight) {
    final frequencyCount = pattern?.frequency ?? activeInsight?.topInsight?.frequency ?? 0;
    final foodName = pattern?.involvedFoods.isNotEmpty == true
        ? pattern!.involvedFoods.first
        : (activeInsight?.topInsight?.involvedFoods.firstOrNull ?? '');
    final imageUrl = foodName.isEmpty ? null : InsightUiKit.foodImageUrl(foodName);
    final style = PatternCardStyle.forType(pattern?.type ?? 'digestion');

    final trigger = pattern?.trigger.trim() ?? '';
    final reaction = pattern?.reaction.trim() ?? '';
    final title = (trigger.isNotEmpty || reaction.isNotEmpty)
        ? ((trigger.isNotEmpty && reaction.isNotEmpty) ? '$trigger → $reaction' : (trigger.isNotEmpty ? trigger : reaction))
        : (activeInsight?.topInsight?.title.isNotEmpty == true ? activeInsight!.topInsight!.title : 'Gut Pattern Detail');

    final sub = pattern?.description.isNotEmpty == true
        ? pattern!.description
        : (activeInsight?.topInsight?.description.isNotEmpty == true
              ? activeInsight!.topInsight!.description
              : 'There is not enough evidence yet to describe a repeated pattern.');

    final theme = context.insightTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? theme.card : style.cardBg,
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(color: isDark ? theme.border : style.borderColor, width: 1.w),
        boxShadow: [BoxShadow(color: style.accentColor.withValues(alpha: 0.06), blurRadius: 10.w, offset: const Offset(0, 3))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Content Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag Row
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.5.w),
                      decoration: BoxDecoration(color: style.tagBg, borderRadius: BorderRadius.circular(14.w)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(style.icon, size: 10.w, color: style.tagFg),
                          Gap.w4,
                          Text(
                            pattern == null ? 'INSIGHT' : style.label,
                            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w700, color: style.tagFg),
                          ),
                        ],
                      ),
                    ),
                    Gap.w6,
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.5.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10.w),
                        border: Border.all(color: style.borderColor),
                      ),
                      child: Text(
                        pattern?.confidence ?? activeInsight?.topInsight?.strength ?? 'Early observation',
                        style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w700, color: style.tagFg),
                      ),
                    ),
                  ],
                ),
                Gap.h8,

                // Title
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: InsightTheme.fontFamily,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: context.insightColor(const Color(0xFF0F172A)),
                    height: 1.15,
                    letterSpacing: -0.3,
                  ),
                ),
                Gap.h4,

                // Description
                Text(
                  sub,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w500, color: context.insightColor(const Color(0xFF334155)), height: 1.3),
                ),
                Gap.h10,

                // Verified Shield Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.w),
                  decoration: BoxDecoration(
                    color: style.accentColor,
                    borderRadius: BorderRadius.circular(16.w),
                    boxShadow: [BoxShadow(color: style.accentColor.withValues(alpha: 0.25), blurRadius: 6.w, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.shieldCheck, size: 11.w, color: Colors.white),
                      Gap.w4,
                      Text(
                        pattern == null ? 'Insight summary' : 'Observed pattern',
                        style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Gap.w12,

          // Right Floating Food Photo Card
          if (foodName.isNotEmpty && imageUrl != null) Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 96.w,
                height: 106.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.w),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8.w, offset: const Offset(0, 3))],
                ),
                clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  placeholder: (_, _) => Container(color: style.tagBg),
                  errorWidget: (_, _, _) => Container(
                    color: style.tagBg,
                    child: Icon(style.icon, color: style.tagFg, size: 28),
                  ),
                ),
              ),
              if (frequencyCount > 0)
                Positioned(
                  right: -4.w,
                  bottom: -4.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.w),
                    decoration: BoxDecoration(
                      color: context.insightColor(const Color(0xFF0F172A)),
                      borderRadius: BorderRadius.circular(10.w),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4.w)],
                    ),
                    child: Text(
                      '${frequencyCount}x seen',
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 2. "What We Observed" Section
  Widget _buildWhatWeObservedCard(BuildContext context, BodyPattern? pattern, AIInsight? activeInsight) {
    final style = PatternCardStyle.forType(pattern?.type ?? 'digestion');
    final observationText = activeInsight?.topInsight?.description ??
        pattern?.description ??
        'There is not enough evidence yet to describe a repeated pattern.';

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.insightColor(Colors.white),
        borderRadius: BorderRadius.circular(18.w),
        border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0)), width: 1.w),
        boxShadow: [BoxShadow(color: const Color(0xFF17171B).withValues(alpha: 0.03), blurRadius: 6.w, offset: Offset(0, 2.w))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(color: style.tagBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(style.icon, size: 16.w, color: style.tagFg),
          ),
          Gap.w10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What We Observed',
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                ),
                Gap.h3,
                Text(
                  observationText,
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w500, color: context.insightColor(const Color(0xFF475569)), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3. "The Evidence" Metric Dashboard Card
  Widget _buildTheEvidenceCard(BuildContext context, {required String patternType, required int? evidenceRatio, required int? frequency, required int? positive, required int? negative}) {
    final style = PatternCardStyle.forType(patternType);

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.insightColor(Colors.white),
        borderRadius: BorderRadius.circular(18.w),
        border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0)), width: 1.w),
        boxShadow: [BoxShadow(color: const Color(0xFF17171B).withValues(alpha: 0.03), blurRadius: 6.w, offset: Offset(0, 2.w))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(color: style.tagBg, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(LucideIcons.barChart2, size: 14.w, color: style.tagFg),
              ),
              Gap.w8,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'The Evidence',
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                    ),
                    Text(
                      'Based on the evidence saved with this insight.',
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, color: context.insightColor(const Color(0xFF64748B))),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap.h12,

          // 4 Stat Cards Row
          Row(
            children: [
              _buildMetricTile(context, title: evidenceRatio == null ? '—' : '$evidenceRatio%', label: 'Evidence Ratio', icon: LucideIcons.pieChart, color: style.accentColor, bg: style.tagBg),
              Gap.w6,
              _buildMetricTile(context, title: frequency == null ? '—' : '$frequency×', label: 'Times Logged', icon: LucideIcons.history, color: style.accentColor, bg: style.tagBg),
              Gap.w6,
              _buildMetricTile(
                context,
                title: positive == null ? '—' : '$positive',
                label: 'Positive Logs',
                icon: LucideIcons.thumbsUp,
                color: const Color(0xFF15803D),
                bg: context.insightColor(const Color(0xFFF0FDF4)),
              ),
              Gap.w6,
              _buildMetricTile(
                context,
                title: negative == null ? '—' : '$negative',
                label: 'Symptom Logs',
                icon: LucideIcons.thumbsDown,
                color: const Color(0xFFDC2626),
                bg: context.insightColor(const Color(0xFFFEF2F2)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(BuildContext context, {required String title, required String label, required IconData icon, required Color color, required Color bg}) => Expanded(
    child: Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: context.insightColor(bg),
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(color: context.insightColor(color).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(color: context.insightColor(color).withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(icon, size: 10.w, color: context.insightColor(color)),
              ),
            ],
          ),
          Gap.h6,
          Text(
            title,
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
          ),
          Gap.h2,
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w600, color: context.insightColor(const Color(0xFF64748B))),
          ),
        ],
      ),
    ),
  );

  /// 4. "Involved Foods" Horizontal Grid Section
  Widget _buildInvolvedFoodsSection(BuildContext context, BodyPattern? pattern, AIInsight? insight) {
    final foods = (pattern?.involvedFoods.isNotEmpty == true
        ? pattern!.involvedFoods.map((f) => _FoodCardData(name: f, imageKeyword: f)).toList()
        : <_FoodCardData>[]);

    if (foods.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(color: context.insightColor(const Color(0xFFFEF3C7)), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(LucideIcons.utensils, size: 14.w, color: context.insightColor(const Color(0xFFB45309))),
            ),
            Gap.w8,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Involved Foods',
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                  ),
                  Text(
                    'Foods included in this observed pattern.',
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, color: context.insightColor(const Color(0xFF64748B))),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.push(AppRoutes.foodIntelligence),
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: context.insightColor(const Color(0xFF0F172A))),
                  ),
                  Gap.w2,
                  Icon(Icons.arrow_forward_rounded, size: 11.w, color: context.insightColor(const Color(0xFF0F172A))),
                ],
              ),
            ),
          ],
        ),
        Gap.h8,

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final food in foods) ...[_InvolvedFoodCard(food: food), Gap.w8],
            ],
          ),
        ),
      ],
    );
  }

  /// 5. Split Grid Section ("Your Next Steps" & "Supporting Evidence")
  Widget _buildSplitGridSection(BuildContext context, AIInsight? insight) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Column: Your Next Steps
        Expanded(child: _buildYourNextStepsCard(context, insight)),
        Gap.w10,

        // Right Column: Supporting Evidence
        Expanded(child: _buildSupportingEvidenceCard(context, insight)),
      ],
    ),
  );

  Widget _buildYourNextStepsCard(BuildContext context, AIInsight? insight) => Container(
    padding: EdgeInsets.all(10.w),
    decoration: BoxDecoration(
      color: context.insightColor(const Color(0xFFF4FAF5)),
      borderRadius: BorderRadius.circular(16.w),
      border: Border.all(color: context.insightColor(const Color(0xFFDCFCE7)), width: 1.w),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(color: context.insightColor(const Color(0xFFDCFCE7)), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Icon(LucideIcons.leaf, size: 12.w, color: context.insightColor(const Color(0xFF15803D))),
                ),
                Gap.w6,
                Expanded(
                  child: Text(
                    'Your Next Steps',
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                  ),
                ),
              ],
            ),
            Gap.h3,
            Text(
              insight?.actionsList.isNotEmpty == true || insight?.topInsight?.nextSteps.isNotEmpty == true
                  ? 'Suggestions based on this insight.'
                  : 'No personalized next steps are available yet.',
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, color: context.insightColor(const Color(0xFF475569)), height: 1.2),
            ),
            Gap.h10,

            if (insight?.actionsList.isNotEmpty == true) ...[
              for (var i = 0; i < insight!.actionsList.take(2).length; i++) ...[
                if (i > 0) Gap.h8,
                InsightNextStepCheckRow(
                  title: insight.actionsList[i].title,
                  subtitle: insight.actionsList[i].description,
                  accentColor: context.insightColor(const Color(0xFF16A34A)),
                  titleColor: context.insightColor(const Color(0xFF0F172A)),
                  subtitleColor: context.insightColor(const Color(0xFF475569)),
                ),
              ],
            ] else if (insight?.topInsight?.nextSteps.isNotEmpty == true) ...[
              InsightNextStepCheckRow(
                title: insight!.topInsight!.nextSteps.first,
                subtitle: '',
                accentColor: context.insightColor(const Color(0xFF16A34A)),
                titleColor: context.insightColor(const Color(0xFF0F172A)),
                subtitleColor: context.insightColor(const Color(0xFF475569)),
              ),
            ] else ...[
              Text('No personalized next step is available yet.', style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, color: context.insightColor(const Color(0xFF64748B)))),
            ],
          ],
        ),
      ],
    ),
  );

  Widget _buildSupportingEvidenceCard(BuildContext context, AIInsight? insight) {
    final mealsCount = insight?.evidence?.sampleSizes.meals;
    final symptomsCount = insight?.evidence?.sampleSizes.symptoms;
    final scansCount = insight?.evidence?.sampleSizes.scans;

    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: context.insightColor(const Color(0xFFF0F7FF)),
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: context.insightColor(const Color(0xFFE2E8F0)), width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(color: context.insightColor(const Color(0xFFDBEAFE)), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(LucideIcons.fileText, size: 12.w, color: context.insightColor(const Color(0xFF1D4ED8))),
              ),
              Gap.w4,
              Expanded(
                child: Text(
                  'Supporting Evidence',
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: context.insightColor(const Color(0xFF0F172A))),
                ),
              ),
              Icon(LucideIcons.info, size: 13.w, color: context.insightColor(const Color(0xFF94A3B8))),
            ],
          ),
          Gap.h2,
          Text(
            'Based on your logged data.',
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, color: context.insightColor(const Color(0xFF475569))),
          ),
          Gap.h10,

          // Metric Rows
          InsightEvidenceMetricRow(
            icon: LucideIcons.utensils,
            title: 'Meals',
            subtitle: 'Total meals analyzed',
            value: mealsCount?.toString() ?? '—',
            iconBackground: context.insightColor(const Color(0xFFDBEAFE)),
            iconColor: context.insightColor(const Color(0xFF1D4ED8)),
            titleColor: context.insightColor(const Color(0xFF0F172A)),
            subtitleColor: context.insightColor(const Color(0xFF64748B)),
            valueColor: context.insightColor(const Color(0xFF0F172A)),
          ),
          Gap.h8,

          InsightEvidenceMetricRow(
            icon: LucideIcons.clipboardList,
            title: 'Symptoms',
            subtitle: 'Symptom logs',
            value: symptomsCount?.toString() ?? '—',
            iconBackground: context.insightColor(const Color(0xFFDBEAFE)),
            iconColor: context.insightColor(const Color(0xFF1D4ED8)),
            titleColor: context.insightColor(const Color(0xFF0F172A)),
            subtitleColor: context.insightColor(const Color(0xFF64748B)),
            valueColor: context.insightColor(const Color(0xFF0F172A)),
          ),
          Gap.h8,

          InsightEvidenceMetricRow(
            icon: LucideIcons.fileText,
            title: 'Scans',
            subtitle: 'Total gut scans',
            value: scansCount?.toString() ?? '—',
            iconBackground: context.insightColor(const Color(0xFFDBEAFE)),
            iconColor: context.insightColor(const Color(0xFF1D4ED8)),
            titleColor: context.insightColor(const Color(0xFF0F172A)),
            subtitleColor: context.insightColor(const Color(0xFF64748B)),
            valueColor: context.insightColor(const Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }
}
