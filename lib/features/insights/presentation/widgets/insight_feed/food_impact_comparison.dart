part of 'insights_feed.dart';

/// Improving and watch food-impact presentation components.

class _SideBySideImprovingAndWatch extends StatelessWidget {
  const _SideBySideImprovingAndWatch({required this.improvingData, required this.series, this.observationCount, this.watchData, this.onImprovingTap, this.onWatchTap});

  final InsightImprovingData improvingData;
  final List<double> series;
  final int? observationCount;
  final InsightWatchData? watchData;
  final VoidCallback? onImprovingTap;
  final VoidCallback? onWatchTap;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _ImprovingCardWidget(data: improvingData, series: series, onTap: onImprovingTap),
        ),
        Gap.w8,
        Expanded(
          child: _WatchCardWidget(data: watchData, observationCount: observationCount, onTap: onWatchTap),
        ),
      ],
    ),
  );
}

class _ImprovingCardWidget extends StatelessWidget {
  const _ImprovingCardWidget({required this.data, required this.series, this.onTap});

  final InsightImprovingData data;
  final List<double> series;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scoredCount = InsightValues.scores(series).where((score) => score > 0).length;
    final isBaseline = scoredCount < 2;
    final sectionLabel = isBaseline ? 'BUILDING BASELINE' : 'YOUR PROGRESS';
    final headline = isBaseline ? 'No repeated pattern yet' : (data.headline.isNotEmpty ? data.headline : 'Your score is moving');
    final description = isBaseline ? 'Log another day to compare changes.' : (data.description.isNotEmpty ? data.description : 'Keep logging to understand your progress.');
    final cardBackground = isDark ? const Color(0xFF102319) : const Color(0xFFF4FAF2);
    final primary = isDark ? const Color(0xFF4ADE80) : const Color(0xFF14532D);
    final secondary = isDark ? const Color(0xFFBBF7D0) : const Color(0xFF334155);

    return _InsightSideCard(
      background: cardBackground,
      borderColor: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.28) : const Color(0xFFDCFCE7),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SideCardHeader(
            icon: isBaseline ? LucideIcons.calendar : Icons.show_chart_rounded,
            label: sectionLabel,
            iconBackground: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.18) : const Color(0xFF16A34A),
            iconColor: isDark ? const Color(0xFF4ADE80) : Colors.white,
            labelColor: primary,
          ),
          Gap.h10,
          Text(
            headline,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 13.sp, fontWeight: FontWeight.w800, color: primary, height: 1.15),
          ),
          Gap.h4,
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, color: secondary, height: 1.3),
          ),
          Gap.h10,
          Row(
            children: [
              Expanded(
                child: _BaselineFactTile(
                  label: 'LOGGED',
                  value: '$scoredCount day${scoredCount == 1 ? '' : 's'}',
                  background: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.78),
                  valueColor: primary,
                  labelColor: secondary,
                ),
              ),
              Gap.w6,
              Expanded(
                child: _BaselineFactTile(
                  label: 'STATUS',
                  value: isBaseline ? 'No trend yet' : 'Tracking',
                  background: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.78),
                  valueColor: primary,
                  labelColor: secondary,
                ),
              ),
            ],
          ),
          if (onTap != null) ...[Gap.h10, _SideCardAction(label: 'Details', color: primary)],
        ],
      ),
    );
  }
}

class _WatchCardWidget extends StatelessWidget {
  const _WatchCardWidget({this.data, this.observationCount, this.onTap});

  final InsightWatchData? data;
  final int? observationCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasTrigger = data != null && data!.pattern != null && data!.title.isNotEmpty && data!.title != 'No Triggers Detected';
    final title = hasTrigger ? data!.title : 'No confirmed trigger yet';
    final description = hasTrigger && data!.description.isNotEmpty ? data!.description : 'One observation is not enough to identify a pattern.';
    final background = hasTrigger ? (isDark ? const Color(0xFF231416) : const Color(0xFFFFF5F5)) : (isDark ? const Color(0xFF111E2E) : const Color(0xFFF8FAFC));
    final border = hasTrigger
        ? (isDark ? const Color(0xFFEF4444).withValues(alpha: 0.45) : const Color(0xFFFCA5A5))
        : (isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.28) : const Color(0xFFE2E8F0));
    final primary = hasTrigger ? (isDark ? const Color(0xFFF87171) : const Color(0xFF881337)) : (isDark ? const Color(0xFF7DD3FC) : const Color(0xFF334155));
    final body = isDark ? Colors.white.withValues(alpha: 0.86) : const Color(0xFF334155);
    final iconBackground = hasTrigger ? const Color(0xFFDC2626) : (isDark ? const Color(0xFF0369A1) : const Color(0xFF64748B));
    final observed = observationCount ?? 0;
    final observationText = hasTrigger
        ? '${data?.pattern?.frequency ?? data?.timeline.length ?? 0} observations'
        : observed > 0
        ? '$observed observation${observed == 1 ? '' : 's'} · needs more logs'
        : 'NEEDS MORE LOGS';

    final effectiveOnTap = hasTrigger
        ? (onTap ??
              () {
                final swapObj = FoodSwap(
                  id: 'swap_watch',
                  source: SwapSource(foodId: 'food_trigger', name: title),
                  alternatives: [SwapAlternative(foodId: 'food_alt_01', name: data?.swapAfter ?? 'Gentle Gut Alternative', reason: data?.swapTip ?? 'Lower digestive burden and easier to process.')],
                );
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => BetterSwapsScreen(swap: swapObj)));
              })
        : null;

    return _InsightSideCard(
      background: background,
      borderColor: border,
      onTap: effectiveOnTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SideCardHeader(
            icon: hasTrigger ? LucideIcons.triangleAlert : LucideIcons.info,
            label: hasTrigger ? 'SOMETHING TO WATCH' : 'PATTERN CHECK',
            iconBackground: iconBackground,
            iconColor: Colors.white,
            labelColor: primary,
          ),
          Gap.h10,
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 13.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A), height: 1.15),
          ),
          Gap.h4,
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, color: body, height: 1.3),
          ),
          Gap.h10,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.w),
            decoration: BoxDecoration(
              color: hasTrigger
                  ? (isDark ? const Color(0xFFEF4444).withValues(alpha: 0.18) : const Color(0xFFFEE2E2))
                  : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.72)),
              borderRadius: BorderRadius.circular(100.w),
            ),
            child: Text(
              observationText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.sp, fontWeight: FontWeight.w800, color: primary, letterSpacing: 0.25),
            ),
          ),
          if (effectiveOnTap != null) ...[Gap.h10, _SideCardAction(label: 'Review', color: primary)],
        ],
      ),
    );
  }
}

class _InsightSideCard extends StatelessWidget {
  const _InsightSideCard({required this.background, required this.borderColor, required this.child, this.onTap});

  final Color background;
  final Color borderColor;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18.w),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: borderColor.withValues(alpha: 0.22), blurRadius: 8.w, offset: Offset(0, 2.w))],
      ),
      child: child,
    );
    return Material(
      type: MaterialType.transparency,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18.w), child: card),
    );
  }
}

class _SideCardHeader extends StatelessWidget {
  const _SideCardHeader({required this.icon, required this.label, required this.iconBackground, required this.iconColor, required this.labelColor});

  final IconData icon;
  final String label;
  final Color iconBackground;
  final Color iconColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 24.w,
        height: 24.w,
        decoration: BoxDecoration(color: iconBackground, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(icon, size: 13.w, color: iconColor),
      ),
      Gap.w6,
      Expanded(
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w800, color: labelColor, letterSpacing: 0.45, height: 1.1),
        ),
      ),
    ],
  );
}

class _BaselineFactTile extends StatelessWidget {
  const _BaselineFactTile({required this.label, required this.value, required this.background, required this.valueColor, required this.labelColor});

  final String label;
  final String value;
  final Color background;
  final Color valueColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.w),
    decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(8.w)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 7.5.sp, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: labelColor),
        ),
        Gap.h2,
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.sp, fontWeight: FontWeight.w800, color: valueColor, height: 1.1),
        ),
      ],
    ),
  );
}

class _SideCardAction extends StatelessWidget {
  const _SideCardAction({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w800, color: color),
      ),
      Gap.w4,
      Icon(Icons.arrow_forward_rounded, size: 13.w, color: color),
    ],
  );
}

// =============================================================================
// HERO 4: TOP FOODS THIS WEEK CARD
// =============================================================================
