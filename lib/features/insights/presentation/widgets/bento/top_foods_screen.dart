part of 'insight_bento_screens.dart';

/// The full list opened from the Your Top Foods card.
class TopFoodsScreen extends StatefulWidget {
  const TopFoodsScreen({super.key, this.insight});

  final AIInsight? insight;

  @override
  State<TopFoodsScreen> createState() => _TopFoodsScreenState();
}

class _TopFoodsScreenState extends State<TopFoodsScreen> {
  static const _filters = ['All', 'Most Positive', 'Most Logged', 'Recent'];
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = context.insightTheme;
    final items = _buildFoodItems(widget.insight ?? _getLatestInsight(context));
    _sortItems(items);

    return Scaffold(
      backgroundColor: theme.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            _TopFoodsPageHeader(
              title: 'Your Top Foods',
              subtitle: 'Foods that appear to work well for you based on your logs.',
              onInfo: () => _showInfo(context),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  for (final filter in _filters) ...[
                    if (filter != _filters.first) SizedBox(width: 6.w),
                    Expanded(
                      child: _TopFoodsFilterChip(label: filter, selected: filter == _selectedFilter, onTap: () => setState(() => _selectedFilter = filter)),
                    ),
                  ],
                ],
              ),
            ),
            Gap.h12,
            Expanded(
              child: items.isEmpty
                  ? const _EmptyTopFoodsState()
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => SizedBox(height: 12.h),
                      itemBuilder: (context, index) => _TopFoodInsightCard(item: items[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static AIInsight? _getLatestInsight(BuildContext context) {
    try {
      return context.read<InsightsNotifier>().latestInsight;
    } on ProviderNotFoundException {
      return null;
    }
  }

  List<_TopFoodInsight> _buildFoodItems(AIInsight? insight) {
    if (insight == null) return [];
    final byFood = <String, _TopFoodInsight>{};

    _TopFoodInsight ensure(String name, {String? imageUrl, String? effect, bool isTopFood = false}) {
      final key = name.toLowerCase().trim();
      return byFood.putIfAbsent(key, () => _TopFoodInsight(name: name.trim(), imageUrl: imageUrl, effect: effect, isTopFood: isTopFood))
        ..isTopFood |= isTopFood
        ..imageUrl ??= imageUrl
        ..effect ??= effect;
    }

    for (var i = 0; i < insight.foodImpacts.length; i++) {
      final impact = insight.foodImpacts[i];
      final type = impact.impactType.toLowerCase();
      final positive = const {'positive', 'healing', 'good', 'supportive'}.contains(type);
      final negative = const {'negative', 'trigger', 'watch', 'bad'}.contains(type);
      final item = ensure(impact.food, imageUrl: impact.userImageUrl ?? impact.imageUrl, effect: positive ? impact.effect : null, isTopFood: positive);
      item.observations++;
      item.impacts.add(impact);
      if (positive) {
        item.positiveObservations++;
        item.addEffect(impact.effect);
      }
      if (negative) item.negativeObservations++;
      if (i < item.latestImpactIndex) {
        item
          ..latestImpactIndex = i
          ..imageUrl ??= impact.userImageUrl ?? impact.imageUrl;
      }
    }

    // Keep foods already classified as supportive in the insight payload, even
    // when there are not yet enough individual responses to show a rating.
    for (final food in insight.healingSummary?.foods ?? const <InsightFood>[]) {
      final item = ensure(food.name, imageUrl: food.imageUrl, effect: food.effect, isTopFood: true);
      if (item.effects.isEmpty) item.addEffect(food.effect);
    }
    for (final food in insight.healingFoods) {
      final item = ensure(food.name, imageUrl: food.userImageUrl ?? food.imageUrl, effect: food.effect, isTopFood: true);
      if (item.effects.isEmpty) item.addEffect(food.effect);
    }

    return byFood.values.where((item) => item.isTopFood && item.name.isNotEmpty).toList();
  }

  void _sortItems(List<_TopFoodInsight> items) {
    int recent(_TopFoodInsight item) => item.latestImpactIndex;
    switch (_selectedFilter) {
      case 'Most Positive':
        items.sort((a, b) {
          final byConfirmed = (b.isConfirmedPositive ? 1 : 0).compareTo(a.isConfirmedPositive ? 1 : 0);
          if (byConfirmed != 0) return byConfirmed;
          final byNet = (b.positiveObservations - b.negativeObservations).compareTo(a.positiveObservations - a.negativeObservations);
          if (byNet != 0) return byNet;
          final byPositive = b.positiveObservations.compareTo(a.positiveObservations);
          if (byPositive != 0) return byPositive;
          final byNegative = a.negativeObservations.compareTo(b.negativeObservations);
          return byNegative != 0 ? byNegative : a.name.compareTo(b.name);
        });
      case 'Most Logged':
        items.sort((a, b) {
          final byCount = b.observations.compareTo(a.observations);
          return byCount != 0 ? byCount : a.name.compareTo(b.name);
        });
      case 'Recent':
        items.sort((a, b) {
          final byRecency = recent(a).compareTo(recent(b));
          return byRecency != 0 ? byRecency : a.name.compareTo(b.name);
        });
      default:
        items.sort((a, b) {
          final byStatus = (b.isConfirmedPositive ? 1 : 0).compareTo(a.isConfirmedPositive ? 1 : 0);
          if (byStatus != 0) return byStatus;
          final byCount = b.observations.compareTo(a.observations);
          return byCount != 0 ? byCount : a.name.compareTo(b.name);
        });
    }
  }

  void _showInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About your top foods'),
        content: const Text(
          'These foods come from positive meal-response observations and supportive foods in your insights. “Most Logged” counts recorded responses, and “Recent” follows the newest response in your insight history. A food stays “Still learning” until there are at least two positive observations. These are associations in your logs, not medical conclusions.',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))],
      ),
    );
  }
}

class _TopFoodsPageHeader extends StatelessWidget {
  const _TopFoodsPageHeader({required this.title, required this.subtitle, required this.onInfo});

  final String title;
  final String subtitle;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final theme = context.insightTheme;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 0),
          child: Row(
            children: [
              _CircleHeaderButton(icon: Icons.arrow_back_rounded, label: 'Back', onPressed: () => context.pop()),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 18.sp, fontWeight: FontWeight.w800, color: theme.textPrimary, letterSpacing: -0.3),
                ),
              ),
              _CircleHeaderButton(icon: Icons.info_outline_rounded, label: 'About food insights', onPressed: onInfo),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 16.h),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.sp, height: 1.3, color: theme.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _TopFoodInsight {
  _TopFoodInsight({required this.name, this.imageUrl, this.effect, this.statusLabel, this.isTopFood = false});

  final String name;
  String? imageUrl;
  String? effect;
  String? statusLabel;
  bool isTopFood;
  int observations = 0;
  int positiveObservations = 0;
  int negativeObservations = 0;
  int latestImpactIndex = 1 << 30;
  final List<String> effects = [];
  final List<FoodImpact> impacts = [];

  void addEffect(String? value) {
    final text = value?.trim().replaceFirst(RegExp(r'^reported\s+', caseSensitive: false), '').trim() ?? '';
    if (text.isEmpty || effects.any((effect) => effect.toLowerCase() == text.toLowerCase())) return;
    effects.add('${text[0].toUpperCase()}${text.substring(1)}');
  }

  bool get isConfirmedPositive => positiveObservations >= 2 && positiveObservations > negativeObservations;
}

class _CircleHeaderButton extends StatelessWidget {
  const _CircleHeaderButton({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Material(
      color: context.insightTheme.card,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 40.w,
          height: 40.w,
          child: Icon(icon, size: 21.w, color: context.insightTheme.textPrimary),
        ),
      ),
    ),
  );
}

class _TopFoodsFilterChip extends StatelessWidget {
  const _TopFoodsFilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.insightTheme;
    return Material(
      color: selected ? theme.textPrimary : theme.cardSubtle,
      borderRadius: BorderRadius.circular(100.w),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100.w),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 9.h),
          child: Text(
            label,
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: selected ? theme.card : theme.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _TopFoodInsightCard extends StatelessWidget {
  const _TopFoodInsightCard({required this.item, this.statusLabel});

  final _TopFoodInsight item;
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.insightTheme;
    final positive = item.isConfirmedPositive;
    final evidence = item.observations == 1 ? '1 observation' : '${item.observations} observations';
    final detail = item.negativeObservations > 0
        ? item.negativeObservations.toString() + (item.negativeObservations == 1 ? ' negative response reported' : ' negative responses reported')
        : item.observations >= 2
        ? 'No negative responses recorded.'
        : 'Not enough data yet to confirm impact.';
    final effectSummary = item.effect?.trim().replaceFirst(RegExp(r'^reported\s+', caseSensitive: false), '').trim() ?? '';
    final subtitle = effectSummary.isEmpty ? null : '${effectSummary[0].toUpperCase()}${effectSummary.substring(1)}';

    return Container(
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(22.w),
        border: Border.all(color: theme.borderSubtle),
        boxShadow: [BoxShadow(color: theme.textPrimary.withValues(alpha: 0.045), blurRadius: 16.w, offset: Offset(0, 5.h))],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _TopFoodDetailScreen(item: item, statusLabel: statusLabel))),
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(17.w),
              child: DynamicFoodImage(
                keyword: item.name,
                imageUrl: item.imageUrl,
                width: 120.w,
                height: 120.w,
                fit: BoxFit.cover,
                placeholder: Container(color: const Color(0xFFE9F5EE)),
                errorWidget: Container(
                  color: const Color(0xFFE9F5EE),
                  alignment: Alignment.center,
                  child: Icon(Icons.eco_outlined, size: 28.w, color: const Color(0xFF078449)),
                ),
              ),
            ),
            Gap.w10,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 15.sp, fontWeight: FontWeight.w800, color: theme.textPrimary),
                            ),
                            if (subtitle?.isNotEmpty == true) ...[
                              Gap.h2,
                              Text(
                                subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, color: theme.textSecondary),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Gap.w4,
                      Expanded(flex: 11, child: _TopFoodStatusBadge(positive: statusLabel == null ? positive : statusLabel!.toLowerCase() != 'watch', label: statusLabel)),
                      Icon(Icons.chevron_right_rounded, size: 16.w, color: theme.textTertiary),
                    ],
                  ),
                  Gap.h10,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final effect in item.effects.take(3)) ...[_TopFoodEffectLine(effect: effect), Gap.h4],
                          ],
                        ),
                      ),
                      Container(width: 1.w, height: 58.w, color: theme.borderSubtle),
                      Gap.w8,
                      Expanded(
                        flex: 11,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              evidence,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: theme.textPrimary),
                            ),
                            Gap.h8,
                            Text(
                              detail,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, height: 1.25, color: theme.textSecondary),
                            ),
                          ],
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
}

class _TopFoodDetailScreen extends StatelessWidget {
  const _TopFoodDetailScreen({required this.item, this.statusLabel});

  final _TopFoodInsight item;
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.insightTheme;
    final image = DynamicFoodImage(
      keyword: item.name,
      imageUrl: item.imageUrl,
      width: double.infinity,
      height: 200.w,
      fit: BoxFit.cover,
      placeholder: Container(color: const Color(0xFFE9F5EE)),
      errorWidget: Container(color: const Color(0xFFE9F5EE), child: Icon(Icons.eco_outlined, color: const Color(0xFF078449), size: 40.w)),
    );

    return Scaffold(
      backgroundColor: theme.scaffold,
      appBar: AppBar(title: Text(item.name), backgroundColor: theme.scaffold),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(20.w), child: image),
          Gap.h16,
        Row(
            children: [
              Expanded(child: Text(item.name, style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 22.sp, fontWeight: FontWeight.w800, color: theme.textPrimary))),
              _TopFoodStatusBadge(positive: statusLabel == null ? item.isConfirmedPositive : statusLabel!.toLowerCase() != 'watch', label: statusLabel),
            ],
          ),
          Gap.h8,
          Text(
            item.observations == 1 ? '1 recorded meal-response observation' : '${item.observations} recorded meal-response observations',
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.sp, color: theme.textSecondary),
          ),
          if (item.observations > 0) ...[
            Gap.h4,
            Text(
              '${item.positiveObservations} positive · ${item.negativeObservations} negative',
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.sp, color: theme.textSecondary),
            ),
          ],
          if (item.effects.isNotEmpty) ...[
            Gap.h24,
            Text('Noted effects', style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 15.sp, fontWeight: FontWeight.w800, color: theme.textPrimary)),
            Gap.h10,
            for (final effect in item.effects) ...[_TopFoodEffectLine(effect: effect), Gap.h8],
          ],
          Gap.h24,
          Text('Your observations', style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 15.sp, fontWeight: FontWeight.w800, color: theme.textPrimary)),
          Gap.h10,
          if (item.impacts.isEmpty)
            Text('No individual meal-response observations are available for this food yet.', style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.sp, color: theme.textSecondary))
          else
            for (final impact in item.impacts) ...[
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(color: theme.card, borderRadius: BorderRadius.circular(14.w), border: Border.all(color: theme.borderSubtle)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [impact.dateLabel, impact.timeframeLabel].where((part) => part.trim().isNotEmpty).join(' · '),
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, color: theme.textSecondary),
                    ),
                    Gap.h6,
                    Text(impact.effect.trim().isEmpty ? 'Response recorded' : impact.effect.trim(), style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 13.sp, fontWeight: FontWeight.w700, color: theme.textPrimary)),
                    Gap.h4,
                    Text(
                      const {'positive', 'healing', 'good', 'supportive'}.contains(impact.impactType.toLowerCase())
                          ? 'Positive observation'
                          : const {'negative', 'trigger', 'watch', 'bad'}.contains(impact.impactType.toLowerCase())
                          ? 'Negative observation'
                          : 'Observation',
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, color: theme.textSecondary),
                    ),
                  ],
                ),
              ),
              Gap.h8,
            ],
          Gap.h16,
          Text('These are associations in your logs, not proof that this food caused a response.', style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, color: theme.textSecondary)),
        ],
      ),
    );
  }
}

class _TopFoodStatusBadge extends StatelessWidget {
  const _TopFoodStatusBadge({required this.positive, this.label});

  final bool positive;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final color = positive ? const Color(0xFF008451) : const Color(0xFF64748B);
    final background = positive ? const Color(0xFFE2F8ED) : const Color(0xFFEEF1F7);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 5.h),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(100.w)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 17.w,
              height: 17.w,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(positive ? Icons.arrow_upward_rounded : Icons.bar_chart_rounded, size: 12.w, color: Colors.white),
            ),
            Gap.w5,
            Text(
              label ?? (positive ? 'Positive' : 'Still learning'),
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopFoodEffectLine extends StatelessWidget {
  const _TopFoodEffectLine({required this.effect});

  final String effect;

  @override
  Widget build(BuildContext context) {
    final lower = effect.toLowerCase();
    final icon = lower.contains('energ') || lower.contains('alert')
        ? Icons.bolt_rounded
        : lower.contains('digest') || lower.contains('bloat') || lower.contains('gut')
        ? Icons.spa_outlined
        : lower.contains('full') || lower.contains('satisf')
        ? Icons.favorite_border_rounded
        : lower.contains('mood') || lower.contains('happy')
        ? Icons.sentiment_satisfied_outlined
        : Icons.eco_outlined;
    return Row(
      children: [
        Container(
          width: 17.w,
          height: 17.w,
          decoration: const BoxDecoration(color: Color(0xFFE4F9EE), shape: BoxShape.circle),
          child: Icon(icon, size: 12.w, color: const Color(0xFF08A665)),
        ),
        Gap.w5,
        Expanded(
          child: Text(
            effect,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, color: context.insightTheme.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _EmptyTopFoodsState extends StatelessWidget {
  const _EmptyTopFoodsState();

  @override
  Widget build(BuildContext context) {
    final theme = context.insightTheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(28.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.eco_outlined, size: 36.w, color: theme.textTertiary),
            Gap.h12,
            Text(
              'Your top foods will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 15.sp, fontWeight: FontWeight.w700, color: theme.textPrimary),
            ),
            Gap.h6,
            Text(
              'Keep logging meals and how you feel afterward to build your personal food history.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.sp, color: theme.textSecondary, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}
