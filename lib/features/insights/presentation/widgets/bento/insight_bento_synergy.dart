part of 'insight_bento_screens.dart';

/// Synergy presentation component.

class InsightBentoSynergy extends StatelessWidget {
  const InsightBentoSynergy({super.key, required this.summary, this.patterns = const []});
  final InsightSummary summary;
  final List<BodyPattern> patterns;

  static const Color _coral = Color(0xFFE11D48);
  static const Color _coralDeep = Color(0xFF9F1239);
  static const Color _coralTone = Color(0xFFFFF1F2);
  static const Color _teal = Color(0xFF14A38F);
  static const Color _tealTone = Color(0xFFE9F6F3);

  @override
  Widget build(BuildContext context) {
    final drivers = patterns.take(3).toList();
    final episodes = drivers.fold<int>(0, (sum, p) => sum + p.frequency);
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16.w, 8.w, 16.w, 24.w),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // The multiplier hero at hero scale: coral wash, ⚠️ tile, filled
          // "N× RISK" pill, headline + description, spike chart, episode count.
          PatternHeroCard(
            accent: _coral,
            deep: _coralDeep,
            tone: _coralTone,
            emoji: '⚠️',
            title: AppStrings.bentoMultiplier,
            sub: summary.type.isNotEmpty ? summary.type : null,
            pill: AppStrings.bentoRiskPill(drivers.length),
            headline: summary.title,
            description: summary.description,
            chart: SizedBox(
              height: 44.w,
              width: double.infinity,
              child: CustomPaint(
                size: Size.infinite,
                painter: TriggerSpikePainter(color: _coral),
              ),
            ),
            footLeft: AppStrings.bentoBasedOnEpisodes(episodes),
            showChevron: false,
          ),
          Gap.h12,
          BentoGrid(
            children: [
              // Ranked drivers wear their pattern identity (accent/tone/icon)
              // and chart their real per-day episode counts when available.
              for (var i = 0; i < drivers.length; i++)
                BentoTile(
                  InsightHighlightCard(
                    accentColor: patternAccent(drivers[i].type),
                    backgroundColor: patternTone(drivers[i].type),
                    icon: patternIcon(drivers[i].type),
                    tag: patternName(drivers[i].type),
                    meta: drivers[i].evidenceRatio > 0 ? '${(drivers[i].evidenceRatio.clamp(0.0, 1.0) * 100).round()}%' : null,
                    title: drivers[i].trigger,
                    body: drivers[i].description,
                    chartPainter: patternSeries(drivers[i]).length >= 2 ? WorkingBarsPainter(color: patternAccent(drivers[i].type), values: patternSeries(drivers[i])) : null,
                    footLeft: '${AppStrings.bentoDriver} ${i + 1}',
                    onTap: () => context.push(AppRoutes.patternDetail, extra: drivers[i]),
                  ),
                ),
              if ((summary.observation ?? '').isNotEmpty)
                BentoTile(
                  spanTwo: true,
                  InsightHighlightCard(accentColor: _teal, backgroundColor: _tealTone, icon: AppIcons.zap, tag: AppStrings.bentoRescueProtocol, title: summary.observation!, body: summary.strength),
                ),
            ],
          ),
        ]),
      ),
    );
  }
}

