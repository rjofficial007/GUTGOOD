import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/services/firestore/insight_firestore_service.dart';
import 'package:gutgood/core/utils/date_formatter.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/insight_v2_theme.dart';
import 'package:gutgood/features/insights/presentation/widgets/v2/v2_kit.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

enum RecentInsightType { productScan, pattern, triggerAlert, weeklyRecap, foodImpact }

/// Every past insight timeline — displays generated historical AI insights and deep-dives into them.
class InsightsHistoryScreen extends StatefulWidget {
  const InsightsHistoryScreen({super.key});

  @override
  State<InsightsHistoryScreen> createState() => _InsightsHistoryScreenState();
}

class _InsightsHistoryScreenState extends State<InsightsHistoryScreen> {
  String _selectedFilter = 'All';
  late Future<List<AIInsight>> _future = _fetch();

  Future<List<AIInsight>> _fetch() => sl<InsightFirestoreService>().getInsightsHistory();

  Future<void> _reload() async {
    setState(() => _future = _fetch());
    try {
      await _future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final v2 = context.v2Theme;

    return Scaffold(
      backgroundColor: v2.scaffold,
      body: FutureBuilder<List<AIInsight>>(
        future: _future,
        builder: (context, snapshot) {
          final history = snapshot.data ?? _getHistoryFromNotifier(context);
          final cards = _buildRecentInsightCards(history);

          final filteredCards = switch (_selectedFilter) {
            'Patterns' => cards.where((c) => c.type == RecentInsightType.pattern).toList(),
            'Scans' => cards.where((c) => c.type == RecentInsightType.productScan).toList(),
            'Weekly' => cards.where((c) => c.type == RecentInsightType.weeklyRecap).toList(),
            _ => cards,
          };

          return RefreshIndicator(
            onRefresh: _reload,
            color: v2.textPrimary,
            backgroundColor: v2.card,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                // App Bar matching other screens
                GutSliverAppBar(title: 'RECENT INSIGHTS', centerTitle: true, showBrandingIcon: false, backgroundColor: v2.scaffold),

                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w, 24.w),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Gap.h10,

                      // 1. BANNER: Stay on top of your gut story
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4FAF5),
                          borderRadius: BorderRadius.circular(20.w),
                          border: Border.all(color: const Color(0xFFDCFCE7), width: 1.w),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 32.w,
                                    height: 32.w,
                                    decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                                    alignment: Alignment.center,
                                    child: Icon(LucideIcons.barChart2, size: 16.w, color: const Color(0xFF15803D)),
                                  ),
                                  Gap.w10,
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Stay on top of your gut story',
                                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                                        ),
                                        Gap.h3,
                                        Text(
                                          'Explore your latest insights, from food scans to patterns and progress.',
                                          style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: const Color(0xFF475569), height: 1.25),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Gap.w10,

                            // Right Count Badge Card
                            Container(
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(color: const Color(0xFFE7F6E7), borderRadius: BorderRadius.circular(16.w)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${cards.length}',
                                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 20.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), height: 1.0),
                                  ),
                                  Gap.h2,
                                  Text(
                                    'Total Insights\nThis month',
                                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.sp, color: const Color(0xFF334155), height: 1.15),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Gap.h10,

                      // 2. FILTER CATEGORY CHIPS
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _FilterChip(label: 'All', isSelected: _selectedFilter == 'All', onTap: () => setState(() => _selectedFilter = 'All')),
                            Gap.w6,
                            _FilterChip(label: 'Patterns', isSelected: _selectedFilter == 'Patterns', onTap: () => setState(() => _selectedFilter = 'Patterns')),
                            Gap.w6,
                            _FilterChip(label: 'Scans', isSelected: _selectedFilter == 'Scans', onTap: () => setState(() => _selectedFilter = 'Scans')),
                            Gap.w6,
                            _FilterChip(label: 'Weekly', isSelected: _selectedFilter == 'Weekly', onTap: () => setState(() => _selectedFilter = 'Weekly')),
                          ],
                        ),
                      ),
                      Gap.h10,

                      // 3. RECENT INSIGHT CARDS LIST
                      if (filteredCards.isEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.w),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Center(
                            child: Text(
                              'No insight history records found.',
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.5.sp, color: const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                      ] else ...[
                        for (final card in filteredCards) ...[_RecentInsightTile(card: card), Gap.h10],
                      ],
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static List<AIInsight> _getHistoryFromNotifier(BuildContext context) {
    try {
      return context.read<InsightsNotifier>().insightHistory;
    } on ProviderNotFoundException {
      return const [];
    }
  }

  static List<_RecentInsightCardData> _buildRecentInsightCards(List<AIInsight> history) {
    final list = <_RecentInsightCardData>[];

    // Sort newest first
    final sorted = [...history]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    for (final insight in sorted) {
      final dateStr = DateFormatter.formatDate(insight.updatedAt);
      final hasPatterns = insight.detectedPatterns.isNotEmpty;
      final hasTrigger = insight.topTrigger != null;
      final hasWeekly = insight.weeklyRecap != null;

      RecentInsightType cardType;
      String tagLabel;
      IconData tagIcon;
      Color tagBg;
      Color tagFg;

      if (hasTrigger) {
        cardType = RecentInsightType.triggerAlert;
        tagLabel = 'Trigger Alert';
        tagIcon = LucideIcons.alertTriangle;
        tagBg = const Color(0xFFFEE2E2);
        tagFg = const Color(0xFF991B1B);
      } else if (hasPatterns) {
        cardType = RecentInsightType.pattern;
        tagLabel = 'Pattern';
        tagIcon = LucideIcons.leaf;
        tagBg = const Color(0xFFFDE6D8);
        tagFg = const Color(0xFF7C2D12);
      } else if (hasWeekly) {
        cardType = RecentInsightType.weeklyRecap;
        tagLabel = 'Weekly Recap';
        tagIcon = LucideIcons.calendar;
        tagBg = const Color(0xFFDCFCE7);
        tagFg = const Color(0xFF15803D);
      } else {
        cardType = RecentInsightType.productScan;
        tagLabel = 'Product Scan';
        tagIcon = LucideIcons.package;
        tagBg = const Color(0xFFDCFCE7);
        tagFg = const Color(0xFF15803D);
      }

      final title = insight.topInsight?.title ?? insight.healingGoal ?? 'Gut Score: ${insight.gutScore} pts';
      final description = insight.topInsight?.description ?? insight.triggerSymptom ?? 'Gut health analysis snapshot for $dateStr.';

      final imgKeyword = insight.healingFoods.firstOrNull?.name ?? insight.topInsight?.involvedFoods.firstOrNull ?? 'Greek Yogurt Berry Bowl';

      list.add(
        _RecentInsightCardData(
          id: insight.id?.toString() ?? insight.firestoreId ?? insight.updatedAt.toIso8601String(),
          type: cardType,
          dateText: dateStr,
          title: title,
          description: description,
          tagLabel: tagLabel,
          tagIcon: tagIcon,
          tagBg: tagBg,
          tagFg: tagFg,
          footerLeftItems: [
            if (insight.healingFoods.isNotEmpty) (icon: LucideIcons.leaf, text: insight.healingFoods.first.name) else (icon: LucideIcons.barChart2, text: '${insight.gutScore} pts'),
            if (insight.triggerSymptom != null && insight.triggerSymptom!.isNotEmpty)
              (icon: LucideIcons.activity, text: insight.triggerSymptom!)
            else
              (icon: LucideIcons.clock, text: DateFormat('h:mm a').format(insight.updatedAt)),
          ],
          scoreText: '${insight.gutScore}/100',
          badgeText: insight.gutScore >= 70 ? 'Positive Impact' : 'Watch',
          badgeIcon: insight.gutScore >= 70 ? LucideIcons.leaf : LucideIcons.alertTriangle,
          badgeBg: insight.gutScore >= 70 ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
          badgeFg: insight.gutScore >= 70 ? const Color(0xFF15803D) : const Color(0xFFDC2626),
          imageKeyword: cardType == RecentInsightType.weeklyRecap ? null : imgKeyword,
          insight: insight,
        ),
      );
    }

    return list;
  }
}

class _RecentInsightCardData {
  const _RecentInsightCardData({
    required this.id,
    required this.type,
    required this.dateText,
    required this.title,
    required this.description,
    required this.tagLabel,
    required this.tagIcon,
    required this.tagBg,
    required this.tagFg,
    required this.footerLeftItems,
    this.badgeText,
    this.badgeIcon,
    this.badgeBg,
    this.badgeFg,
    this.scoreText,
    this.imageKeyword,
    this.userImageUrl,
    this.insight,
  });

  final String id;
  final RecentInsightType type;
  final String dateText;
  final String title;
  final String description;
  final String tagLabel;
  final IconData tagIcon;
  final Color tagBg;
  final Color tagFg;
  final List<({IconData icon, String text})> footerLeftItems;
  final String? badgeText;
  final IconData? badgeIcon;
  final Color? badgeBg;
  final Color? badgeFg;
  final String? scoreText;
  final String? imageKeyword;
  final String? userImageUrl;
  final AIInsight? insight;
}

class _RecentInsightTile extends StatelessWidget {
  const _RecentInsightTile({required this.card});

  final _RecentInsightCardData card;

  void _handleTap(BuildContext context) {
    if (card.insight != null) {
      context.push(AppRoutes.insightDetail, extra: card.insight);
      return;
    }

    switch (card.type) {
      case RecentInsightType.productScan:
      case RecentInsightType.foodImpact:
        context.push(
          AppRoutes.highlightDetail,
          extra: HighlightDetailArgs(tag: card.tagLabel, emoji: '🌱', title: card.title, body: card.description, accentColor: 0xFF1F7A3D, backgroundColor: 0xFFE7F6E7, chartType: 'healing'),
        );
        break;
      case RecentInsightType.pattern:
        context.push(AppRoutes.fiberSynergyDetail);
        break;
      case RecentInsightType.triggerAlert:
        context.push(
          AppRoutes.highlightDetail,
          extra: HighlightDetailArgs(tag: 'Something to Watch', emoji: '⚠️', title: card.title, body: card.description, accentColor: 0xFFC4302B, backgroundColor: 0xFFFFF1F0, chartType: 'trigger'),
        );
        break;
      case RecentInsightType.weeklyRecap:
        context.push(AppRoutes.weeklyRecap);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.w),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
          boxShadow: [BoxShadow(color: const Color(0xFF17171B).withValues(alpha: 0.03), blurRadius: 6.w, offset: Offset(0, 2.w))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Image / Graphic Tile
            _buildLeftMedia(card),
            Gap.w10,

            // Right Content Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Tag Pill + Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.w),
                        decoration: BoxDecoration(color: card.tagBg, borderRadius: BorderRadius.circular(14.w)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(card.tagIcon, size: 10.w, color: card.tagFg),
                            Gap.w4,
                            Text(
                              card.tagLabel,
                              style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w700, color: card.tagFg),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        card.dateText,
                        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.sp, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  Gap.h6,

                  // Title
                  Text(
                    card.title,
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 14.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), height: 1.2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap.h3,

                  // Description
                  Text(
                    card.description,
                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, color: const Color(0xFF475569), height: 1.25),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gap.h8,

                  // Footer Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left Footer Items
                      Expanded(
                        child: Row(
                          children: [
                            for (final item in card.footerLeftItems) ...[
                              Icon(item.icon, size: 10.w, color: const Color(0xFF64748B)),
                              Gap.w3,
                              Flexible(
                                child: Text(
                                  item.text,
                                  style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, color: const Color(0xFF64748B)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Gap.w6,
                            ],
                          ],
                        ),
                      ),

                      // Right Badge / Score
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (card.scoreText != null) ...[
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: card.scoreText!.split('/').first,
                                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 16.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                                  ),
                                  TextSpan(
                                    text: '/100',
                                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            Gap.w6,
                          ],
                          if (card.badgeText != null)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.w),
                              decoration: BoxDecoration(color: card.badgeBg ?? const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12.w)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (card.badgeIcon != null) ...[Icon(card.badgeIcon, size: 10.w, color: card.badgeFg ?? const Color(0xFF15803D)), Gap.w3],
                                  Text(
                                    card.badgeText!,
                                    style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 9.5.sp, fontWeight: FontWeight.w700, color: card.badgeFg ?? const Color(0xFF15803D)),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftMedia(_RecentInsightCardData card) {
    if (card.imageKeyword != null) {
      final imgUrl = V2Kit.foodImageUrl(card.imageKeyword!);
      return ClipRRect(
        borderRadius: BorderRadius.circular(12.w),
        child: CachedNetworkImage(
          imageUrl: imgUrl,
          width: 88.w,
          height: 96.w,
          fit: BoxFit.cover,
          placeholder: (_, _) => Container(color: const Color(0xFFF1F5F9)),
          errorWidget: (_, _, _) => Container(color: const Color(0xFFDCFCE7)),
        ),
      );
    } else {
      return Container(
        width: 88.w,
        height: 96.w,
        decoration: BoxDecoration(
          color: const Color(0xFFF4FAF5),
          borderRadius: BorderRadius.circular(12.w),
          border: Border.all(color: const Color(0xFFDCFCE7), width: 1.w),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              right: -6.w,
              bottom: -6.w,
              child: SizedBox(
                width: 36.w,
                height: 36.w,
                child: const CustomPaint(painter: _LeafBranchPainter()),
              ),
            ),
            Container(
              width: 32.w,
              height: 32.w,
              decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(LucideIcons.barChart2, size: 16.w, color: const Color(0xFF15803D)),
            ),
          ],
        ),
      );
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.w),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: TextStyle(fontFamily: InsightV2Theme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : const Color(0xFF0F172A)),
      ),
    ),
  );
}

class _LeafBranchPainter extends CustomPainter {
  const _LeafBranchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = const Color(0xFF86EFAC).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final stemPaint = Paint()
      ..color = const Color(0xFF22C55E).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.2, size.height)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.5, size.width * 0.7, 0);
    canvas.drawPath(path, stemPaint);

    void drawLeaf(Offset center, double angle, double scale) {
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..rotate(angle);
      final leafPath = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(12 * scale, -8 * scale, 22 * scale, 0)
        ..quadraticBezierTo(12 * scale, 8 * scale, 0, 0);
      canvas
        ..drawPath(leafPath, fillPaint)
        ..restore();
    }

    drawLeaf(Offset(size.width * 0.7, size.height * 0.1), -0.5, 0.9);
    drawLeaf(Offset(size.width * 0.5, size.height * 0.4), 0.6, 1.0);
    drawLeaf(Offset(size.width * 0.3, size.height * 0.7), -0.4, 0.8);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
