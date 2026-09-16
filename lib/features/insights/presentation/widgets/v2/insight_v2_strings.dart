/// Copy for the v2 Insights screens (scoped to the feature, like the theme).
///
/// Sentences mirror `uploads/v2.html`; anything user-data-shaped is formatted
/// by the widgets, not stored here.
abstract final class InsightV2Strings {
  // Home header
  static const String brandEyebrow = 'GutGood';
  static const String insightsTitle = 'Insights';
  static const String insightsSubtitle = "Your gut's story, in real time.";
  static const String historyTooltip = 'Insight history';

  // Hero
  static const String gutScoreEyebrow = 'Gut Score';
  static const String highConfidence = 'High confidence';
  static const String moderateConfidence = 'Moderate confidence';
  static const String lowConfidence = 'Early signals';
  static const String trendImproving = 'Improving';
  static const String trendDeclining = 'Needs care';
  static const String trendSteady = 'Holding steady';

  // Top insight pager
  static const String topInsightBadge = 'Top Insight';
  static const String patternPill = 'Pattern';

  // What's Improving
  static const String improvingEyebrow = "What's Improving";
  static const String liveBadge = 'Live';
  static const String sevenDayTrend = '7-day trend';
  static const String currentStat = 'Current';
  static const String lastWeekPrefix = 'Last week ';
  static const String streakFlame = '🔥 Streak';
  static const String streakDaysSuffix = ' days';
  static const String keyFoodsLabel = 'Key foods driving this';

  // Something to Watch
  static const String watchEyebrow = 'Something to Watch';
  static const String detectedBadge = 'Detected';
  static const String reactionStat = '⏱ Reaction';
  static const String riskStat = 'Risk level';
  static const String windowStat = 'Window';
  static const String recentTimelineLabel = 'Recent timeline';
  static const String timelineLatest = 'Latest';
  static const String smartSwapPrefix = 'Smart swap';
  static const String triggerFoodSuffix = '• Trigger food';
  static const String beforeLabel = 'Before';
  static const String afterLabel = 'After';

  // Learning state (pre-threshold)
  static const String mappingEyebrow = 'Building your baseline';
  static const String mappingSub =
      'Log a few more meals and scans to unlock your gut story.';
  static const String noScorePlaceholder = '--';
  static const String learningChecklistLabel = 'What unlocks your insights';

  // What's Working screen
  static const String workingTitle = "What's Working";
  static const String workingSub =
      'These foods and habits are supporting your gut health.';
  static const String topFoodsTitle = 'Top Foods This Week';
  static const String topFoodsSub = 'Your most consistent gut-friendly foods.';
  static const String patternsNoticedTitle = 'Patterns We Noticed';
  static const String patternsNoticedSub =
      "Your gut has a pattern — here's what we found.";

  // Detail screens
  static const String gutHeroBadge = 'Your Gut Hero';
  static const String gutSaboteurBadge = 'Your Gut Saboteur';
  static const String whyItWorks = 'Why it works';
  static const String whyTrigger = "Why it's a trigger";
  static const String timeframeStat = '◷ Timeframe';
  static const String frequencyStat = '◷ Frequency';
  static const String seeAlternativesCta = 'See Better Alternatives';
  static const String backToInsightsCta = 'Back to Insights';
  static const String basedOnLogsFooter =
      'Based on your logs · insights improve as you log';
  static const String yourActionsLabel = 'Your Actions';
  static const String highlightsLabel = 'Highlights';
  static const String bestDayStat = '☆ Best Day';
  static const String foodsLoggedStat = '◍ Foods Logged';
  static const String viewFullReportCta = 'View Full Report';
  static const String nextStepsLabel = 'Your action plan';
  static const String evidenceLabel = 'The evidence';
  static const String relatedPatternsLabel = 'Related patterns';
  static const String frequencyLabel = '◍ Frequency';
  static const String confidenceLabel = '◍ Confidence';
  static const String timeWindowLabel = '◷ Time window';
  static const String commonFactorsLabel = 'Common factors';
  static const String occurrencesLabel = 'Recent occurrences';
  static const String observationLabel = 'What we observed';
}
