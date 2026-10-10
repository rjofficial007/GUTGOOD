import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/insight_theme.dart';
import 'package:gutgood/core/utils/date_formatter.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MealDetailScreen extends StatelessWidget {
  const MealDetailScreen({super.key, required this.meal});

  final MealLog meal;

  @override
  Widget build(BuildContext context) {
    final theme = context.insightTheme;
    final title = meal.items.isNotEmpty ? meal.items.first : (meal.mealType ?? 'Meal');
    final otherItems = meal.items.length > 1 ? meal.items.skip(1).toList() : const <String>[];
    final tags = meal.foodTags.where((tag) => tag.trim().isNotEmpty).toList();
    final photoUrl = meal.photoUrl?.trim();

    return Scaffold(
      backgroundColor: theme.scaffold,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          GutSliverAppBar(title: 'MEAL DETAILS', centerTitle: true, showBrandingIcon: false, backgroundColor: theme.scaffold),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w, 28.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (photoUrl?.isNotEmpty == true) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20.w),
                    child: CachedNetworkImage(
                      imageUrl: photoUrl!,
                      height: 190.w,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(height: 190.w, color: theme.cardSubtle),
                      errorWidget: (context, url, error) => _imageFallback(theme, height: 190.w),
                    ),
                  ),
                  Gap.h16,
                ],
                Text(title, style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 22.sp, fontWeight: FontWeight.w900, height: 1.15, color: theme.textPrimary)),
                Gap.h8,
                Row(
                  children: [
                    Icon(LucideIcons.circleCheck, size: 15.w, color: AppPalette.green500),
                    Gap.w5,
                    Text('Meal logged', style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w700, color: AppPalette.green500)),
                    Gap.w8,
                    Text('•', style: TextStyle(color: theme.textTertiary)),
                    Gap.w8,
                    Flexible(child: Text(DateFormatter.formatFull(meal.eventTime), style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, color: theme.textSecondary))),
                  ],
                ),
                Gap.h16,
                _MealDetailCard(
                  title: 'Meal details',
                  icon: LucideIcons.utensils,
                  children: [
                    _DetailRow(icon: LucideIcons.clock3, label: 'Logged', value: DateFormatter.formatFull(meal.createdAt)),
                    if (meal.mealType?.trim().isNotEmpty == true)
                      _DetailRow(icon: LucideIcons.sun, label: 'Meal type', value: _titleCase(meal.mealType!)),
                    if (meal.source?.trim().isNotEmpty == true)
                      _DetailRow(icon: LucideIcons.bookOpen, label: 'Source', value: meal.source!.toLowerCase() == 'swap' ? 'Food swap' : _titleCase(meal.source!)),
                  ],
                ),
                if (otherItems.isNotEmpty) ...[
                  Gap.h12,
                  _MealDetailCard(
                    title: 'Also in this meal',
                    icon: LucideIcons.list,
                    children: [for (final item in otherItems) _DetailRow(icon: LucideIcons.dot, label: '', value: item)],
                  ),
                ],
                if (meal.notes?.trim().isNotEmpty == true) ...[
                  Gap.h12,
                  _MealDetailCard(
                    title: 'Notes',
                    icon: LucideIcons.notebookPen,
                    children: [Text(meal.notes!, style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.sp, height: 1.4, color: theme.textSecondary))],
                  ),
                ],
                if (tags.isNotEmpty) ...[
                  Gap.h12,
                  _MealDetailCard(
                    title: 'Food tags',
                    icon: LucideIcons.tags,
                    children: [
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.w,
                        children: [
                          for (final tag in tags)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.w),
                              decoration: BoxDecoration(color: theme.cardSubtle, borderRadius: BorderRadius.circular(20.w)),
                              child: Text(_titleCase(tag.replaceAll('_', ' ')), style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w600, color: theme.textSecondary)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _imageFallback(InsightTheme theme, {required double height}) => Container(
    height: height,
    width: double.infinity,
    color: theme.cardSubtle,
    alignment: Alignment.center,
    child: Icon(LucideIcons.utensils, size: 32, color: theme.textTertiary),
  );

  static String _titleCase(String value) => value
      .split(RegExp(r'[_\s]+'))
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

class _MealDetailCard extends StatelessWidget {
  const _MealDetailCard({required this.title, required this.icon, required this.children});

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = context.insightTheme;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(color: theme.card, borderRadius: BorderRadius.circular(18.w), border: Border.all(color: theme.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16.w, color: theme.textSecondary),
              Gap.w8,
              Text(title, style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 13.sp, fontWeight: FontWeight.w800, color: theme.textPrimary)),
            ],
          ),
          Gap.h10,
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = context.insightTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: 8.w),
      child: Row(
        children: [
          Icon(icon, size: 14.w, color: theme.textTertiary),
          Gap.w8,
          if (label.isNotEmpty) ...[
            SizedBox(width: 74.w, child: Text(label, style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, color: theme.textSecondary))),
            Gap.w8,
          ],
          Expanded(child: Text(value, style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w600, color: theme.textPrimary))),
        ],
      ),
    );
  }
}
