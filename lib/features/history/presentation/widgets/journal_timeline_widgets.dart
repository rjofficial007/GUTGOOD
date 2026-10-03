import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/journal/journal_entry.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/theme/insight_theme.dart';
import 'package:gutgood/core/utils/date_formatter.dart';
import 'package:gutgood/core/utils/gut_score_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/history/presentation/providers/history_notifier.dart';

class JournalFilterBar extends StatelessWidget {
  const JournalFilterBar({super.key, required this.selectedFilter, required this.onFilterChanged});

  final HistoryFilter selectedFilter;
  final ValueChanged<HistoryFilter> onFilterChanged;

  String _filterLabel(HistoryFilter filter) {
    switch (filter) {
      case HistoryFilter.all:
        return 'All';
      case HistoryFilter.scans:
        return 'Scans';
      case HistoryFilter.body:
        return 'Body & Symptoms';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedBg = isDark ? Colors.white : const Color(0xFF171717);
    final selectedFg = isDark ? Colors.black : Colors.white;
    final unselectedFg = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final unselectedBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 0.w, 16.w, 4.w),
      clipBehavior: Clip.none,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < HistoryFilter.values.length; i++) ...[
            if (i > 0) Gap.w8,
            GestureDetector(
              onTap: () => onFilterChanged(HistoryFilter.values[i]),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
                decoration: BoxDecoration(
                  color: selectedFilter == HistoryFilter.values[i] ? selectedBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(100.w),
                  border: Border.all(color: selectedFilter == HistoryFilter.values[i] ? selectedBg : unselectedBorder, width: 1.w),
                  boxShadow: selectedFilter == HistoryFilter.values[i] && !isDark ? [BoxShadow(color: const Color(0xFF17171B).withValues(alpha: 0.15), blurRadius: 4.w, offset: Offset(0, 2.w))] : null,
                ),
                child: Text(
                  _filterLabel(HistoryFilter.values[i]),
                  style: TextStyle(
                    fontFamily: InsightTheme.fontFamily,
                    fontSize: 12.sp,
                    fontWeight: selectedFilter == HistoryFilter.values[i] ? FontWeight.w800 : FontWeight.w600,
                    color: selectedFilter == HistoryFilter.values[i] ? selectedFg : unselectedFg,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class JournalTimelineEntry extends StatelessWidget {
  const JournalTimelineEntry({super.key, required this.entry, required this.isFirst, required this.isLast, this.onTap});

  final JournalEntry entry;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Timeline Column
        SizedBox(
          width: 60,
          child: Column(
            children: [
              Text(DateFormatter.formatTime(entry.createdAt), style: context.captionBold.copyWith(color: context.appColorScheme.textSecondary)),
              Gap.h14,
              Expanded(
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    if (!isLast) Container(width: 2, margin: const EdgeInsets.only(top: 36), color: context.appColorScheme.borderSubtle),
                    _buildIcon(context),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Card Column
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: AppSizes.p16, right: AppSizes.p16),
            child: _buildCard(context),
          ),
        ),
      ],
    ),
  );

  Widget _buildIcon(BuildContext context) {
    IconData icon;
    Color color;
    Color bgColor;

    switch (entry.type) {
      case JournalEntryType.scan:
        final scan = entry.scan!;
        final category = scan.category?.toLowerCase() ?? '';
        final source = scan.source?.toLowerCase() ?? '';

        if (category == 'label' || source == 'label') {
          icon = AppIcons.fileText;
          color = AppPalette.blue;
        } else if (category == 'menu' || source == 'menu') {
          icon = AppIcons.bookOpen;
          color = AppPalette.orange;
        } else {
          final isBarcode = source == 'barcode';
          icon = isBarcode ? AppIcons.barcode : AppIcons.scan;
          color = isBarcode ? AppPalette.purple : AppPalette.green500;
        }
        bgColor = color.withAlpha(26);
        break;
      case JournalEntryType.meal:
        icon = AppIcons.utensils;
        color = AppPalette.orange;
        bgColor = color.withAlpha(26);
        break;
      case JournalEntryType.symptom:
        icon = AppIcons.heartPulse;
        color = AppPalette.pink;
        bgColor = color.withAlpha(26);
        break;
    }

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 18),
    );
  }

  Widget _buildCard(BuildContext context) {
    var title = '';
    var subtitle = '';
    String? type;
    String? source;
    String? imageUrl;
    Widget? trailing;
    Color? typeColor;

    var fallbackIcon = AppIcons.salad;

    switch (entry.type) {
      case JournalEntryType.scan:
        final scan = entry.scan!;
        final category = scan.category?.toLowerCase() ?? '';
        final scanSource = scan.source?.toLowerCase() ?? '';

        title = scan.productName;
        subtitle = scan.brand;
        imageUrl = scan.userImageUrl ?? scan.imageUrl;

        if (category == 'label' || scanSource == 'label') {
          type = AppStrings.labelAudit;
          typeColor = AppPalette.blue;
          trailing = null; // No score for labels usually
          fallbackIcon = AppIcons.fileText;
        } else if (category == 'menu' || scanSource == 'menu') {
          type = AppStrings.menuGuide;
          typeColor = AppPalette.orange;
          trailing = null;
          fallbackIcon = AppIcons.bookOpen;
        } else {
          type = scan.source == 'barcode' ? AppStrings.barcodeScan : AppStrings.foodScan;
          typeColor = scan.source == 'barcode' ? AppPalette.purple : AppPalette.green500;
          trailing = _ScoreBadge(score: scan.score);
          fallbackIcon = scan.source == 'barcode' ? AppIcons.barcode : AppIcons.scan;
        }
        source = null;
        break;
      case JournalEntryType.meal:
        final meal = entry.meal!;
        title = meal.items.isNotEmpty ? meal.items.first : (meal.mealType ?? AppStrings.meal);
        subtitle = [if (meal.items.length > 1) meal.items.skip(1).join(', '), if (meal.notes != null && meal.notes!.isNotEmpty) meal.notes!].join(' • ');
        type = AppStrings.meal;
        source = meal.source?.toUpperCase() ?? AppStrings.labelLog;
        imageUrl = meal.photoUrl;
        typeColor = AppPalette.orange;
        fallbackIcon = AppIcons.utensils;
        break;
      case JournalEntryType.symptom:
        final symptom = entry.symptom!;
        title = 'Felt ${symptom.symptom.toLowerCase()}';
        type = AppStrings.bodySignal;
        subtitle = [
          if (symptom.notes != null && symptom.notes!.isNotEmpty) symptom.notes!,
          if (symptom.energyLevel != null) AppStrings.energyCount(symptom.energyLevel!),
          if ((symptom.notes == null || symptom.notes!.isEmpty) && symptom.energyLevel == null) '${AppStrings.severity}: ${symptom.severity}/10',
        ].join(' • ');
        typeColor = AppPalette.pink;
        trailing = null; // Removed chevron until detail screen is implemented
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSizes.p12),
        decoration: BoxDecoration(
          color: context.appColorScheme.cardBackground,
          borderRadius: BorderRadius.circular(AppSizes.r16),
          border: Border.all(color: context.appColorScheme.borderSubtle),
          boxShadow: [BoxShadow(color: AppPalette.black.withAlpha(3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            // Image/Emoji placeholder
            if (entry.type == JournalEntryType.symptom)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: context.appColorScheme.errorSubtle, borderRadius: BorderRadius.circular(AppSizes.r12)),
                child: Center(child: Text(_getSymptomEmoji(entry.symptom?.symptom), style: const TextStyle(fontSize: 24))),
              )
            else if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.r12),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: context.appColorScheme.borderSubtle),
                  errorWidget: (context, url, error) => Container(
                    color: context.appColorScheme.borderSubtle,
                    child: Icon(fallbackIcon, color: context.appColorScheme.textPrimary, size: 20),
                  ),
                ),
              )
            else
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: context.appColorScheme.borderSubtle, borderRadius: BorderRadius.circular(AppSizes.r12)),
                child: Icon(fallbackIcon, color: context.appColorScheme.textPrimary, size: 20),
              ),
            Gap.w12,

            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.bodyBold.copyWith(fontSize: AppSizes.s15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Text(
                        type,
                        style: context.caption.copyWith(color: typeColor, fontWeight: FontWeight.w700),
                      ),
                      if (source != null) Text(' • $source', style: context.caption.copyWith(color: context.appColorScheme.textMuted)),
                    ],
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: context.caption.copyWith(color: context.appColorScheme.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Trailing Section
            if (trailing != null) ...[Gap.w8, trailing],
          ],
        ),
      ),
    );
  }

  String _getSymptomEmoji(String? symptom) {
    if (symptom == null) return '😐';
    final s = symptom.toLowerCase();

    // Key Pattern Symptoms
    if (s.contains('bloat')) return '😫';
    if (s.contains('energ')) return '⚡';
    if (s.contains('headache')) return '🤕';
    if (s.contains('digest')) return '🔄';
    if (s.contains('full')) return '🫃';
    if (s.contains('sleep')) return '😴';

    // Additional Triggers & Symptoms
    if (s.contains('gas')) return '💨';
    if (s.contains('fatigue')) return '🪫';
    if (s.contains('pain') || s.contains('cramp')) return '😣';
    if (s.contains('skin')) return '✨';
    if (s.contains('mood')) return '😊';

    return '😐';
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    final band = GutScoreBand.fromScore(score);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p4),
      decoration: BoxDecoration(color: band.color.withAlpha(26), borderRadius: BorderRadius.circular(AppSizes.r8)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(score.toString(), style: context.bodyBold.copyWith(color: band.color)),
          Text(band.label, style: context.captionBold.copyWith(color: band.color)),
        ],
      ),
    );
  }
}
