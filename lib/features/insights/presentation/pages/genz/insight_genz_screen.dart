import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/utils/bottom_sheet_helper.dart';
import 'package:gutgood/features/insights/presentation/pages/genz/details/genz_detail_screens.dart';
import 'package:gutgood/features/insights/presentation/pages/genz/genz_theme.dart';
import 'package:gutgood/features/insights/presentation/pages/genz/states/genz_state_views.dart';
import 'package:gutgood/features/insights/presentation/pages/genz/tabs/genz_foods_tab.dart';
import 'package:gutgood/features/insights/presentation/pages/genz/tabs/genz_for_you_tab.dart';
import 'package:gutgood/features/insights/presentation/pages/genz/tabs/genz_patterns_tab.dart';
import 'package:gutgood/features/insights/presentation/pages/genz/tabs/genz_recap_tab.dart';
import 'package:gutgood/features/insights/presentation/pages/genz/widgets/genz_story_viewer.dart';
import 'package:gutgood/features/insights/presentation/pages/genz/widgets/genz_tile.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class InsightGenzScreen extends StatefulWidget {
  const InsightGenzScreen({super.key});

  @override
  State<InsightGenzScreen> createState() => _InsightGenzScreenState();
}

class _InsightGenzScreenState extends State<InsightGenzScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _stack = [];
  GenzDataState _currentState = GenzDataState.full;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _pushDetail(String id) {
    setState(() {
      _stack.add(id);
    });
  }

  void _popDetail() {
    setState(() {
      if (_stack.isNotEmpty) _stack.removeLast();
    });
  }

  String _getStateLabel(GenzDataState state) {
    switch (state) {
      case GenzDataState.full:
        return 'with data';
      case GenzDataState.early:
        return 'just started';
      case GenzDataState.learn:
        return 'not enough data';
    }
  }

  void _showStateSelectorSheet(BuildContext context) {
    BottomSheetHelper.showGutBottomSheet(
      context: context,
      title: 'select data state',
      children: [
        _buildStateOption('with data', 'full insights with scores, trends & patterns', GenzDataState.full),
        const SizedBox(height: 8),
        _buildStateOption('just started', 'early baseline reading & loading progress', GenzDataState.early),
        const SizedBox(height: 8),
        _buildStateOption('not enough data', 'learning mode with setup quests', GenzDataState.learn),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStateOption(String title, String desc, GenzDataState state) {
    final isSelected = _currentState == state;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentState = state;
          _stack.clear();
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? GenzColors.lime : GenzColors.sf(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'InterTight',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? GenzColors.ink : GenzColors.tx(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: TextStyle(
                      fontFamily: 'InterTight',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? GenzColors.ink.withOpacity(0.7) : GenzColors.mu(context),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(LucideIcons.check, color: GenzColors.ink, size: 20),
          ],
        ),
      ),
    );
  }

  String _getDetailTitle(String id) {
    if (id == 'score') return 'score';
    if (id == 'swaps') return 'swaps';
    if (id == 'plan') return 'next week';
    if (id == 'food-intel') return 'food intel';
    if (id == 'history') return 'history';
    if (id == 'hist-detail') return 'oct 3';
    if (id == 'synergy') return 'insight';
    if (id.startsWith('obs-')) return 'observation';
    if (id.startsWith('pattern-')) return 'pattern';
    if (id.startsWith('swap-')) return 'swap';
    if (id.startsWith('food-')) return 'food';
    if (id.startsWith('meal-')) return 'meal';
    return 'detail';
  }

  @override
  Widget build(BuildContext context) {
    final isDetail = _stack.isNotEmpty;

    return PopScope(
      canPop: !isDetail,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isDetail) {
          _popDetail();
        }
      },
      child: Scaffold(
        backgroundColor: GenzColors.scaffoldBg(context),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDetail),
              if (!isDetail) ...[
                if (_currentState != GenzDataState.learn) _buildStoryRail(),
                if (_currentState != GenzDataState.learn) _buildTabs(),
                Expanded(
                  child: _buildMainContent(),
                ),
              ] else ...[
                Expanded(
                  child: GenzDetailScreenView(
                    id: _stack.last,
                    onNavigate: _pushDetail,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_currentState == GenzDataState.learn) {
      return const GenzEmptyStateCardView(
        eyebrow: 'insights',
        titleText: 'let’s build your',
        highlightWord: 'baseline',
        tone: GenzTone.lilac,
        asset: 'a-bulb.webp',
        cardTitle: 'unlock your insights',
        cardDesc: 'scan 3 food meals and log 1 symptom. then we can calculate your gut score and spot your first patterns.',
        questTitle: 'quests to unlock',
        quest1: 'scan food meals (1/3)',
        quest2: 'log a symptom (0/1)',
      );
    }

    if (_currentState == GenzDataState.early) {
      return TabBarView(
        controller: _tabController,
        children: [
          GenzEarlyForYouView(onNavigate: _pushDetail),
          const GenzEmptyStateCardView(
            eyebrow: 'patterns',
            titleText: 'none yet.',
            highlightWord: 'soon.',
            tone: GenzTone.lilac,
            asset: 'a-digestion.webp',
            cardTitle: 'no patterns yet',
            cardDesc: 'keep logging. repeat triggers show up after a few days.',
            questTitle: 'unlock your first pattern',
            quest1: 'log meals (1/3)',
            quest2: 'log a symptom (0/1)',
          ),
          const GenzEmptyStateCardView(
            eyebrow: 'food impact',
            titleText: 'no food data',
            highlightWord: 'yet',
            tone: GenzTone.blue,
            asset: 'a-bowl.webp',
            cardTitle: 'nothing to rank yet',
            cardDesc: 'scan foods and log how you feel. we’ll show what helps and what to watch.',
            questTitle: 'unlock food impacts',
            quest1: 'scan food (1/3)',
            quest2: 'log a symptom (0/1)',
          ),
          const GenzEmptyStateCardView(
            eyebrow: 'weekly recap',
            titleText: 'first recap',
            highlightWord: 'loading',
            tone: GenzTone.butter,
            asset: 'a-calendar.webp',
            cardTitle: 'your first recap is on its way',
            cardDesc: 'your sunday to saturday recap shows up once a full week is logged.',
            questTitle: 'unlock your weekly recap',
            quest1: 'log on 3 different days (1/3)',
            quest2: 'log a symptom (0/1)',
          ),
        ],
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        GenzForYouTab(onNavigate: _pushDetail),
        GenzPatternsTab(onNavigate: _pushDetail),
        GenzFoodsTab(onNavigate: _pushDetail),
        GenzRecapTab(onNavigate: _pushDetail),
      ],
    );
  }

  Widget _buildHeader(bool isDetail) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(LucideIcons.arrowLeft, color: GenzColors.tx(context)),
                onPressed: () {
                  if (isDetail) {
                    _popDetail();
                  } else if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Text(
                isDetail ? _getDetailTitle(_stack.last) : 'insights',
                style: TextStyle(
                  fontFamily: 'InterTight',
                  fontSize: isDetail ? 24 : 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: isDetail ? -0.8 : -1.6,
                  color: GenzColors.tx(context),
                ),
              ),
            ],
          ),
          if (!isDetail)
            Row(
              children: [
                GestureDetector(
                  onTap: () => _showStateSelectorSheet(context),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: GenzColors.lime,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.slidersHorizontal, size: 16, color: GenzColors.ink),
                        const SizedBox(width: 6),
                        Text(
                          _getStateLabel(_currentState),
                          style: const TextStyle(
                            fontFamily: 'InterTight',
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: GenzColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 38,
                  padding: const EdgeInsets.only(left: 6, right: 12),
                  decoration: BoxDecoration(
                    color: GenzColors.sf(context),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/a-flame.webp',
                        width: 26,
                        height: 26,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '6/7',
                        style: TextStyle(
                          fontFamily: 'InterTight',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: GenzColors.tx(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _pushDetail('history'),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: GenzColors.sf(context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.history,
                      color: GenzColors.tx(context),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );

  Widget _buildStoryRail() => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          _buildStoryRing(
            'today',
            'a-gauge.webp',
            GenzColors.lime,
            slides: const [
              GenzStorySlide(
                label: 'gut score · today',
                title: '78',
                subtitle: 'up 4 from yesterday. your gut said slay.',
                artAsset: 'a-gauge.webp',
                tone: GenzTone.lime,
                ctaText: 'break it down',
                ctaRoute: AppRoutes.smartInsightDetail,
                isHugeNumber: true,
              ),
              GenzStorySlide(
                label: 'plot twist',
                title: 'dairy might be the bloating villain.',
                subtitle: 'bloating followed milk 3 out of the 4 days you logged it.',
                artAsset: 'a-bulb.webp',
                tone: GenzTone.ink,
                ctaText: 'see the receipts',
                ctaRoute: AppRoutes.smartInsightDetail,
              ),
              GenzStorySlide(
                label: 'watch list',
                title: 'cold milk.',
                subtitle: 'bloating within ~2 hrs, 3 times. it keeps showing up.',
                artAsset: 'a-alert.webp',
                tone: GenzTone.pink,
                ctaText: 'see cold milk',
                ctaRoute: AppRoutes.swapDetail,
              ),
            ],
          ),
          _buildStoryRing(
            'patterns',
            'a-digestion.webp',
            GenzColors.lilac,
            slides: const [
              GenzStorySlide(
                label: 'patterns unlocked',
                title: '6 patterns found',
                subtitle: '3 watchouts, 3 helpful. your body is dropping hints.',
                artAsset: 'a-digestion.webp',
                tone: GenzTone.lilac,
                ctaText: 'open pattern',
                ctaRoute: AppRoutes.patternDetail,
              ),
            ],
          ),
          _buildStoryRing(
            'foods',
            'a-bowl.webp',
            GenzColors.orange,
            slides: const [
              GenzStorySlide(
                label: 'food vibe check',
                title: '55% helpful',
                subtitle: '11 of 20 foods agreed with your gut.',
                artAsset: 'a-bowl.webp',
                tone: GenzTone.orange,
                ctaText: 'see all foods',
                ctaRoute: AppRoutes.foodIntelligence,
              ),
            ],
          ),
          _buildStoryRing(
            'week',
            'a-calendar.webp',
            GenzColors.blue,
            slides: const [
              GenzStorySlide(
                label: 'weekly recap',
                title: 'score 74',
                subtitle: 'your gut had a main character week.',
                artAsset: 'a-calendar.webp',
                tone: GenzTone.blue,
                ctaText: 'see the score',
                ctaRoute: AppRoutes.smartInsightDetail,
              ),
            ],
          ),
          _buildStoryRing(
            'streak',
            'a-flame.webp',
            GenzColors.orange,
            slides: const [
              GenzStorySlide(
                label: 'streak on fire',
                title: '6 days logged',
                subtitle: "you're 1 day away from a full week streak!",
                artAsset: 'a-flame.webp',
                tone: GenzTone.butter,
                ctaText: 'plan next week',
                ctaRoute: AppRoutes.insightHistory,
              ),
            ],
          ),
        ],
      ),
    );

  Widget _buildStoryRing(
    String label,
    String asset,
    Color themeColor, {
    required List<GenzStorySlide> slides,
  }) =>
      Padding(
        padding: const EdgeInsets.only(right: 14),
        child: GestureDetector(
          onTap: () => GenzStoryViewer.show(context, label, slides),
          child: Column(
            children: [
              Container(
                width: 68,
                height: 68,
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      GenzColors.pink,
                      GenzColors.orange,
                      GenzColors.lime,
                      GenzColors.blue,
                      GenzColors.pink,
                    ],
                    transform: GradientRotation(3.49), // ~200 deg
                  ),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: GenzColors.bg(context), width: 3),
                    color: themeColor,
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/$asset',
                      width: 40,
                      height: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'InterTight',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: GenzColors.tx(context),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildTabs() => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        children: [
          _buildTabButton(0, 'for you'),
          const SizedBox(width: 8),
          _buildTabButton(1, 'patterns'),
          const SizedBox(width: 8),
          _buildTabButton(2, 'foods'),
          const SizedBox(width: 8),
          _buildTabButton(3, 'recap'),
        ],
      ),
    );

  Widget _buildTabButton(int index, String label) {
    final isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () => _tabController.animateTo(index),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? GenzColors.lime : GenzColors.sf(context),
          borderRadius: BorderRadius.circular(100),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'InterTight',
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: isSelected ? GenzColors.ink : GenzColors.tx(context),
          ),
        ),
      ),
    );
  }
}
