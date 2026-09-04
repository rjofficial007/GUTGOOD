import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';

class SmartInsightDetailScreen extends StatelessWidget {
  const SmartInsightDetailScreen({super.key, required this.insight});
  final InsightSummary insight;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    return Scaffold(
      backgroundColor: scheme.cardBackground,
      body: CustomScrollView(
        slivers: [
          const GutSliverAppBar(title: 'SMART INSIGHT', centerTitle: true),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Super Smart Insight Hero (Mirrors SuperGutScoreCard style)
                  DashboardEntrance(delay: 50, child: SuperSmartInsightHero(insight: insight)),
                  Gap.h16,

                  // 3. WHAT IS CONTRIBUTING (Involved Foods & Observation)
                  DashboardEntrance(
                    delay: 150,
                    child: SuperPhysicalGoalCard(
                      title: AppStrings.whatWeNoticed.toUpperCase(),
                      subtitle: 'WHAT IS HAPPENING',
                      label: insight.observation ?? insight.description,
                      icon: AppIcons.brain,
                      color: AppPalette.purple,
                      onTap: () {},
                    ),
                  ),
                  Gap.h16,

                  // CONTRIBUTING FACTORS (SuperFoodGaugeCard)
                  if (insight.involvedFoods.isNotEmpty) ...[
                    DashboardEntrance(
                      delay: 180,
                      child: SuperFoodGaugeCard(
                        title: 'CONTRIBUTING FACTORS',
                        label: 'IDENTIFIED BY GUTGOOD',
                        score: (insight.evidenceRatio != null) ? (insight.evidenceRatio! * 100).toInt() : 75,
                        statusColor: insight.type.toLowerCase().contains('healing') || insight.type.toLowerCase().contains('positive') ? const Color(0xFF27F15B) : const Color(0xFFE9579A),
                        foods: insight.involvedFoods.map((f) => SuperCyclerItemData(name: f, effect: AppStrings.linkedToInsight)).toList(),
                      ),
                    ),
                    Gap.h16,
                  ],

                  // 4. WHAT TO DO NEXT (Action Strategy)
                  DashboardEntrance(
                    delay: 210,
                    child: SuperPhysicalGoalCard(
                      title: AppStrings.actionPlan.toUpperCase(),
                      subtitle: 'WHAT TO DO NEXT',
                      label: insight.nextSteps.isNotEmpty ? insight.nextSteps.first : 'Keep monitoring how you feel after meals.',
                      icon: AppIcons.lightbulb,
                      color: AppPalette.green,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SuperSmartInsightHero extends StatelessWidget {
  const SuperSmartInsightHero({super.key, required this.insight});
  final InsightSummary insight;

  @override
  Widget build(BuildContext context) {
    final ratio = insight.evidenceRatio ?? 0.0;
    final score = (ratio * 100).toInt();
    final accentColor = _getAccentColor(insight.type);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF202126), Color(0xFF141414)]),
        border: Border.all(color: Colors.white.withAlpha(7)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 28, 18, 20),
        child: Column(
          children: [
            SizedBox(
              height: 160,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: GutTickGaugePainter(progress: ratio.clamp(0.0, 1.0))),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: const Alignment(0.0, 0.8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            insight.frequency != null ? '${insight.frequency}' : '-',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFFF4F4F4), fontSize: 60, height: 0.95, fontWeight: FontWeight.w300, letterSpacing: -2),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                (insight.strength ?? 'MODERATE').toUpperCase(),
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white.withAlpha(184), fontSize: 12, fontWeight: FontWeight.w400),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              insight.type.toUpperCase(),
              style: TextStyle(color: Colors.white.withAlpha(210), fontSize: 11, letterSpacing: 1.8, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Text(
              insight.title.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                insight.description,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 20),
            Container(height: 1, color: Colors.white.withAlpha(14)),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SuperMetric(title: 'Frequency', value: '${insight.frequency ?? 1} times'),
                ),
                Expanded(
                  child: SuperMetric(title: 'Strength', value: (insight.strength ?? 'MOD').toUpperCase()),
                ),
                Expanded(
                  child: SuperMetric(title: 'Evidence', value: '$score%'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getAccentColor(String type) {
    final t = type.toLowerCase();
    if (t.contains('healing') || t.contains('positive')) return const Color(0xFF27F15B);
    if (t.contains('trigger') || t.contains('negative')) return const Color(0xFFE9579A);
    return const Color(0xFF0759E8);
  }
}
