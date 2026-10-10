import 'package:flutter/material.dart';
import 'package:genz_insights/src/details/genz_detail_screens.dart';
import 'package:genz_insights/src/genz_theme.dart';
import 'package:genz_insights/src/states/genz_state_views.dart';
import 'package:genz_insights/src/tabs/genz_foods_tab.dart';
import 'package:genz_insights/src/tabs/genz_for_you_tab.dart';
import 'package:genz_insights/src/tabs/genz_patterns_tab.dart';
import 'package:genz_insights/src/tabs/genz_recap_tab.dart';
import 'package:genz_insights/src/widgets/genz_story_viewer.dart';
import 'package:genz_insights/src/widgets/genz_tile.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class InsightGenzScreen extends StatefulWidget {
  const InsightGenzScreen({super.key, this.initialState = GenzDataState.full, this.onBack, this.onOpenRoute, this.onLightModeChanged});

  /// Initial demo-data mode; users can also switch modes by long-pressing the title.
  final GenzDataState initialState;

  /// Called when the host app's back button is pressed from the root screen.
  final VoidCallback? onBack;

  /// Called for story CTAs that need a route owned by the host app.
  ///
  /// Route strings are passed through unchanged (for example, `/food-intelligence`).
  final ValueChanged<String>? onOpenRoute;

  /// Called when the light-mode control is changed in the settings sheet.
  /// The host app owns and persists the actual theme preference.
  final ValueChanged<bool>? onLightModeChanged;

  @override
  State<InsightGenzScreen> createState() => _InsightGenzScreenState();
}

class _InsightGenzScreenState extends State<InsightGenzScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _stack = [];
  final ScrollController _outerScrollController = ScrollController();
  ScrollController? _innerScrollController;
  late GenzDataState _currentState;
  final Set<String> _seenStories = <String>{};

  @override
  void initState() {
    super.initState();
    _currentState = widget.initialState;
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _outerScrollController.dispose();
    super.dispose();
  }

  void _resetScrollPositions() {
    final inner = _innerScrollController;
    if (inner != null && inner.hasClients) {
      for (final position in inner.positions.toList()) {
        if (position.pixels != 0) position.jumpTo(0);
      }
    }
    if (_outerScrollController.hasClients && _outerScrollController.offset != 0) {
      _outerScrollController.jumpTo(0);
    }
  }

  void _pushDetail(String id) {
    _resetScrollPositions();
    setState(() => _stack.add(id));
  }

  void _popDetail() {
    _resetScrollPositions();
    setState(() {
      if (_stack.isNotEmpty) _stack.removeLast();
    });
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
        body: DefaultTextStyle(
          style: TextStyle(fontFamily: GenzFonts.primary, fontFamilyFallback: GenzFonts.fallback, fontSize: 16, color: GenzColors.tx(context)),
          child: SafeArea(
            // The HTML phone mock reserves a 46px status strip. Preserve that
            // content start on Android while respecting larger iOS safe insets.
            minimum: const EdgeInsets.only(top: 46),
            child: Column(
              children: [
                _buildHeader(isDetail),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Offstage(offstage: isDetail, child: _buildInsightsContent()),
                      if (isDetail) GenzDetailScreenView(id: _stack.last, onNavigate: _pushDetail),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInsightsContent() {
    if (_currentState == GenzDataState.learn) {
      return _buildMainContent();
    }

    return NestedScrollView(
      controller: _outerScrollController,
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        if (_currentState == GenzDataState.full) SliverToBoxAdapter(child: _buildStoryRail()),
        SliverPersistentHeader(
          pinned: true,
          delegate: _GenzTabsHeader(backgroundColor: GenzColors.bg(context), child: _buildTabs()),
        ),
      ],
      body: Builder(
        builder: (context) {
          // NestedScrollView installs its coordinated inner controller here.
          _innerScrollController = PrimaryScrollController.maybeOf(context);
          return _buildMainContent();
        },
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
        physics: const NeverScrollableScrollPhysics(),
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
      physics: const NeverScrollableScrollPhysics(),
      children: [
        GenzForYouTab(onNavigate: _pushDetail),
        GenzPatternsTab(onNavigate: _pushDetail),
        GenzFoodsTab(onNavigate: _pushDetail),
        GenzRecapTab(onNavigate: _pushDetail, onPlayRecap: () => _openStory('week', _weekSlides)),
      ],
    );
  }

  Widget _buildHeader(bool isDetail) => Padding(
    padding: EdgeInsets.fromLTRB(isDetail ? 14 : 16, 6, isDetail ? 14 : 16, 8),
    child: Row(
      children: [
        if (isDetail) ...[
          GestureDetector(
            onTap: _popDetail,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: GenzColors.sf(context), shape: BoxShape.circle),
              child: Icon(LucideIcons.arrowLeft, color: GenzColors.tx(context), size: 20),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _getDetailTitle(_stack.last),
            style: TextStyle(fontFamily: GenzFonts.primary, fontFamilyFallback: GenzFonts.fallback, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -0.4, color: GenzColors.tx(context)),
          ),
        ] else ...[
          GestureDetector(
            onLongPress: _showStateSelector,
            child: Text(
              'insights',
              style: TextStyle(fontFamily: GenzFonts.primary, fontFamilyFallback: GenzFonts.fallback, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1.6, color: GenzColors.tx(context)),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _openStreakStory,
            child: Container(
              height: 38,
              padding: const EdgeInsets.only(left: 6, right: 12),
              decoration: BoxDecoration(color: GenzColors.sf(context), borderRadius: BorderRadius.circular(100)),
              child: Row(
                children: [
                  const GenzArt(asset: 'assets/images/a-flame.webp', width: 26, height: 26),
                  const SizedBox(width: 4),
                  Text(
                    '6/7',
                    style: TextStyle(fontFamily: GenzFonts.primary, fontFamilyFallback: GenzFonts.fallback, fontSize: 14, fontWeight: FontWeight.w800, color: GenzColors.tx(context)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _pushDetail('history'),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: GenzColors.sf(context), shape: BoxShape.circle),
              child: Icon(LucideIcons.history, color: GenzColors.tx(context), size: 19),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: 'insights settings',
            child: GestureDetector(
              onTap: _showInsightsSettings,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: GenzColors.sf(context), shape: BoxShape.circle),
                child: Icon(LucideIcons.settings, color: GenzColors.tx(context), size: 18),
              ),
            ),
          ),
        ],
      ],
    ),
  );

  void _showStateSelector() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: GenzColors.sf(context),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in const [(state: GenzDataState.full, label: 'with data'), (state: GenzDataState.early, label: 'just started'), (state: GenzDataState.learn, label: 'not enough data')])
              ListTile(
                title: Text(
                  option.label,
                  style: TextStyle(color: GenzColors.tx(sheetContext), fontFamily: GenzFonts.primary, fontFamilyFallback: GenzFonts.fallback, fontWeight: FontWeight.w800),
                ),
                trailing: _currentState == option.state ? const Icon(LucideIcons.check, color: GenzColors.lime) : null,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _resetScrollPositions();
                  setState(() {
                    _stack.clear();
                    _currentState = option.state;
                  });
                  _tabController.animateTo(0);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showInsightsSettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          decoration: BoxDecoration(
            color: GenzColors.sf(sheetContext),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(color: GenzColors.ln(sheetContext), borderRadius: BorderRadius.circular(99)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'insights settings',
                    style: TextStyle(color: GenzColors.tx(sheetContext), fontFamily: GenzFonts.primary, fontFamilyFallback: GenzFonts.fallback, fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              for (final option in const [(state: GenzDataState.full, label: 'with data'), (state: GenzDataState.early, label: 'just started'), (state: GenzDataState.learn, label: 'not enough data')])
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(
                    option.label,
                    style: TextStyle(color: GenzColors.tx(sheetContext), fontFamily: GenzFonts.primary, fontFamilyFallback: GenzFonts.fallback, fontWeight: FontWeight.w800),
                  ),
                  trailing: _currentState == option.state ? const Icon(LucideIcons.check, color: GenzColors.lime) : null,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _resetScrollPositions();
                    setState(() {
                      _stack.clear();
                      _currentState = option.state;
                    });
                    _tabController.animateTo(0);
                  },
                ),
              Divider(color: GenzColors.ln(sheetContext), height: 1),
              SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                secondary: Icon(LucideIcons.sun, color: GenzColors.tx(sheetContext)),
                title: Text(
                  'light mode',
                  style: TextStyle(color: GenzColors.tx(sheetContext), fontFamily: GenzFonts.primary, fontFamilyFallback: GenzFonts.fallback, fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  'use the light palette',
                  style: TextStyle(color: GenzColors.mu(sheetContext), fontFamily: GenzFonts.primary, fontFamilyFallback: GenzFonts.fallback, fontSize: 12),
                ),
                value: Theme.of(sheetContext).brightness == Brightness.light,
                activeThumbColor: GenzColors.ink,
                activeTrackColor: GenzColors.lime,
                onChanged: widget.onLightModeChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<GenzStorySlide> get _streakSlides => const [
    GenzStorySlide(
      label: 'logging streak',
      title: '6/7',
      subtitle: 'days logged this week. one more and it’s a perfect week.',
      artAsset: 'a-flame.webp',
      tone: GenzTone.orange,
      ctaText: 'log today',
      ctaRoute: '/scanner/food',
      toastText: 'opens the meal scanner in the app',
      isHugeNumber: true,
    ),
  ];

  void _openStory(String name, List<GenzStorySlide> slides) {
    setState(() => _seenStories.add(name));
    GenzStoryViewer.show(context, name, slides, onNavigate: _pushDetail, onOpenRoute: widget.onOpenRoute);
  }

  void _openStreakStory() => _openStory('streak', _streakSlides);

  List<GenzStorySlide> get _weekSlides => const [
    GenzStorySlide(
      label: 'week avg · sep 27 – oct 3',
      title: '74',
      subtitle: 'up 3 vs last week. main character energy.',
      artAsset: 'a-calendar.webp',
      tone: GenzTone.blue,
      ctaText: 'see the score',
      ctaRoute: '/smart-insight-detail',
      detailId: 'score',
      isHugeNumber: true,
    ),
    GenzStorySlide(
      label: 'best day',
      title: 'wednesday.',
      subtitle: 'score 84. oats and ginger tea carried.',
      artAsset: 'a-trophy.webp',
      tone: GenzTone.butter,
      ctaText: 'see oats',
      ctaRoute: '/food-intelligence',
      detailId: 'food-masala-oats',
    ),
    GenzStorySlide(
      label: 'top trigger',
      title: 'cold milk, 3×.',
      subtitle: 'the one repeat offender this week.',
      artAsset: 'a-alert.webp',
      tone: GenzTone.pink,
      ctaText: 'see cold milk',
      ctaRoute: '/food-intelligence',
      detailId: 'food-cold-milk',
    ),
    GenzStorySlide(
      label: 'weekly insight',
      title: 'light, warm breakfasts = best days.',
      subtitle: 'wednesday’s oats and ginger tea led your week at 84.',
      artAsset: 'a-quote.webp',
      tone: GenzTone.lilac,
      ctaText: 'plan next week',
      ctaRoute: '/insight-history',
      detailId: 'plan',
    ),
  ];

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
              boldSubtitle: 'slay',
              artAsset: 'a-gauge.webp',
              tone: GenzTone.lime,
              ctaText: 'break it down',
              ctaRoute: '/smart-insight-detail',
              detailId: 'score',
              isHugeNumber: true,
            ),
            GenzStorySlide(
              label: 'plot twist',
              title: 'dairy might be the bloating villain.',
              subtitle: 'bloating followed milk 3 out of the 4 days you logged it.',
              artAsset: 'a-bulb.webp',
              tone: GenzTone.ink,
              ctaText: 'see the receipts',
              ctaRoute: '/smart-insight-detail',
              detailId: 'obs-dairy',
            ),
            GenzStorySlide(
              label: 'watch list',
              title: 'cold milk.',
              subtitle: 'bloating within ~2 hrs, 3 times. it keeps showing up.',
              artAsset: 'a-alert.webp',
              tone: GenzTone.pink,
              ctaText: 'see cold milk',
              ctaRoute: '/food-intelligence',
              detailId: 'food-cold-milk',
            ),
          ],
        ),
        _buildStoryRing(
          'patterns',
          'a-digestion.webp',
          GenzColors.lilac,
          slides: const [
            GenzStorySlide(
              label: 'pattern · bloating',
              title: 'bloating.',
              subtitle: 'cold milk → bloating, seen 4× in the last 14 days.',
              artAsset: 'a-bloating.webp',
              tone: GenzTone.orange,
              ctaText: 'open pattern',
              ctaRoute: '/pattern-detail',
              detailId: 'pattern-bloating',
            ),
            GenzStorySlide(
              label: 'pattern · steady energy',
              title: 'energy.',
              subtitle: 'ginger tea → steady energy, seen 5× in the last 14 days.',
              artAsset: 'a-energy.webp',
              tone: GenzTone.butter,
              ctaText: 'open pattern',
              ctaRoute: '/pattern-detail',
              detailId: 'pattern-energy',
            ),
            GenzStorySlide(
              label: 'pattern · stays full',
              title: 'fullness.',
              subtitle: 'masala oats → stays full, seen 3× in the last 14 days.',
              artAsset: 'a-fullness.webp',
              tone: GenzTone.blue,
              ctaText: 'open pattern',
              ctaRoute: '/pattern-detail',
              detailId: 'pattern-fullness',
            ),
            GenzStorySlide(
              label: 'pattern · easy digestion',
              title: 'digestion.',
              subtitle: 'dal khichdi → easy digestion, seen 4× in the last 14 days.',
              artAsset: 'a-digestion.webp',
              tone: GenzTone.lime,
              ctaText: 'open pattern',
              ctaRoute: '/pattern-detail',
              detailId: 'pattern-digestion',
            ),
            GenzStorySlide(
              label: 'pattern · poor sleep',
              title: 'sleep.',
              subtitle: 'late tea → poor sleep, seen 2× in the last 14 days.',
              artAsset: 'a-sleep.webp',
              tone: GenzTone.lilac,
              ctaText: 'open pattern',
              ctaRoute: '/pattern-detail',
              detailId: 'pattern-sleep',
            ),
            GenzStorySlide(
              label: 'pattern · headache',
              title: 'headache.',
              subtitle: 'skipped lunch → headache, seen 2× in the last 14 days.',
              artAsset: 'a-headache.webp',
              tone: GenzTone.pink,
              ctaText: 'open pattern',
              ctaRoute: '/pattern-detail',
              detailId: 'pattern-headache',
            ),
          ],
        ),
        _buildStoryRing(
          'foods',
          'a-bowl.webp',
          GenzColors.orange,
          slides: const [
            GenzStorySlide(
              label: 'vibe check · 14 days',
              title: '55%',
              subtitle: 'of your foods agreed with your gut. 11 of 20 foods.',
              artAsset: 'a-bowl.webp',
              tone: GenzTone.blue,
              ctaText: 'see all foods',
              ctaRoute: '/food-intelligence',
              detailId: 'food-intel',
              isHugeNumber: true,
            ),
            GenzStorySlide(
              label: 'swap alert',
              title: 'swap cold milk for ginger tea.',
              subtitle: 'ginger tea → steadier energy. cold milk → bloating. easy swap.',
              artAsset: 'a-alert.webp',
              tone: GenzTone.orange,
              ctaText: 'see the swap',
              ctaRoute: '/swap-detail',
              detailId: 'swap-cold-milk',
            ),
            GenzStorySlide(
              label: 'helps',
              title: 'ginger tea + masala oats.',
              subtitle: 'steadier energy and easier digestion. keep them on rotation.',
              artAsset: 'a-trophy.webp',
              tone: GenzTone.lime,
              ctaText: 'see ginger tea',
              ctaRoute: '/food-intelligence',
              detailId: 'food-ginger-tea',
            ),
          ],
        ),
        _buildStoryRing('week', 'a-calendar.webp', GenzColors.blue, slides: _weekSlides),
        _buildStoryRing('streak', 'a-flame.webp', GenzColors.orange, slides: _streakSlides),
      ],
    ),
  );

  Widget _buildStoryRing(String label, String asset, Color themeColor, {required List<GenzStorySlide> slides}) => Padding(
    padding: const EdgeInsets.only(right: 14),
    child: GestureDetector(
      onTap: () => _openStory(label, slides),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            padding: const EdgeInsets.all(3),
            decoration: _seenStories.contains(label)
                ? BoxDecoration(shape: BoxShape.circle, color: GenzColors.ln(context))
                : const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [GenzColors.pink, GenzColors.orange, GenzColors.lime, GenzColors.blue, GenzColors.pink],
                      transform: GradientRotation(3.49), // ~200 deg
                    ),
                  ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: GenzColors.bg(context), width: 3),
                color: themeColor,
              ),
              child: Center(child: GenzArt(asset: 'assets/images/$asset', width: 42, height: 42)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontFamily: GenzFonts.primary, fontFamilyFallback: GenzFonts.fallback, fontSize: 11.5, fontWeight: FontWeight.w800, color: GenzColors.tx(context)),
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
      onTap: () {
        _resetScrollPositions();
        _tabController.animateTo(index);
      },
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: isSelected ? GenzColors.lime : GenzColors.sf(context), borderRadius: BorderRadius.circular(100)),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: GenzFonts.primary,
            fontFamilyFallback: GenzFonts.fallback,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: isSelected ? GenzColors.ink : GenzColors.tx(context),
          ),
        ),
      ),
    );
  }
}

class _GenzTabsHeader extends SliverPersistentHeaderDelegate {
  const _GenzTabsHeader({required this.backgroundColor, required this.child});

  static const double _height = 54;
  final Color backgroundColor;
  final Widget child;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => ColoredBox(color: backgroundColor, child: child);

  @override
  bool shouldRebuild(covariant _GenzTabsHeader oldDelegate) => backgroundColor != oldDelegate.backgroundColor || child != oldDelegate.child;
}
