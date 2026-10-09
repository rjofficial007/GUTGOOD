import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/ai/protocol/ai_constants.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/di/di_instance.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/theme/insight_theme.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/core/widgets/journal_event_sheet.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_feed/insight_ui_kit.dart';
import 'package:gutgood/infrastructure/firebase/firestore/history_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/notification_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Swap Details screen matching the exact UI/UX mockup.
class SwapDetailScreen extends StatefulWidget {
  const SwapDetailScreen({super.key, required this.alternative, this.sourceFoodName = ''});

  final SwapAlternative alternative;
  final String sourceFoodName;

  @override
  State<SwapDetailScreen> createState() => _SwapDetailScreenState();
}

class _SwapDetailScreenState extends State<SwapDetailScreen> {
  @override
  void initState() {
    super.initState();
    AppLogger.data('SwapDetailScreen', {'sourceFoodName': widget.sourceFoodName, 'alternative': widget.alternative.toMap()});
  }

  @override
  Widget build(BuildContext context) {
    final alternative = widget.alternative;
    final sourceFoodName = widget.sourceFoodName;
    final theme = context.insightTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = alternative.imageUrl;

    final benefits = alternative.benefits.isNotEmpty ? alternative.benefits : alternative.benefitTags.map((tag) => SwapBenefit(title: tag, description: '', icon: 'leaf')).toList();

    final whyBetter = alternative.whyBetterOption?.trim().isNotEmpty == true
        ? alternative.whyBetterOption!
        : alternative.reason?.trim().isNotEmpty == true
        ? alternative.reason!
        : sourceFoodName.trim().isNotEmpty
        ? 'No specific comparison details are available for ${alternative.name} and $sourceFoodName.'
        : 'No specific comparison details are available for this alternative yet.';

    final nutrition = alternative.nutrition;

    final scaffoldBg = theme.scaffold;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          GutSliverAppBar(title: 'SWAP DETAILS', centerTitle: true, showBrandingIcon: false, backgroundColor: scaffoldBg),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w, 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Hero Image Container (Compact 160.w height)
                  Container(
                    height: 160.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.w),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                          blurRadius: 10.w,
                          offset: Offset(0, 3.w),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InsightUiKit.foodImage(
                      alternative.name,
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: Container(color: theme.cardSubtle),
                      errorWidget: Container(
                        color: theme.cardSubtle,
                        child: Icon(LucideIcons.utensils, color: theme.textSecondary),
                      ),
                    ),
                  ),
                  Gap.h12,

                  // 2. Title & Subtitle
                  Text(
                    alternative.name,
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 20.sp, fontWeight: FontWeight.w900, color: theme.textPrimary, height: 1.15),
                  ),
                  Gap.h2,
                  Text(
                    'Suggested alternative',
                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w500, color: theme.textSecondary),
                  ),
                  Gap.h12,

                  // 3. 3 Feature Highlight Pills Row (Compact)
                  if (benefits.isNotEmpty)
                    Row(
                      children: [
                        for (final b in benefits.take(3))
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.only(right: b == benefits.take(3).last ? 0 : 6.w),
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 10.w),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF102319) : const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(14.w),
                                border: Border.all(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.3) : const Color(0xFFBBF7D0)),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 30.w,
                                    height: 30.w,
                                    decoration: BoxDecoration(color: isDark ? const Color(0xFF22C55E).withValues(alpha: 0.2) : const Color(0xFFDCFCE7), shape: BoxShape.circle),
                                    alignment: Alignment.center,
                                    child: Icon(_getBenefitIcon(b.icon), size: 15.w, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
                                  ),
                                  Gap.h6,
                                  Text(
                                    b.title,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.5.sp, fontWeight: FontWeight.w800, color: theme.textPrimary, height: 1.15),
                                  ),
                                  Gap.h2,
                                  Text(
                                    b.description,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 8.5.sp, fontWeight: FontWeight.w400, color: theme.textSecondary, height: 1.2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  Gap.h12,

                  // 4. "Why this may be a better option" Card
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: theme.card,
                      borderRadius: BorderRadius.circular(16.w),
                      border: Border.all(color: theme.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28.w,
                          height: 28.w,
                          decoration: BoxDecoration(color: isDark ? const Color(0xFFD97706).withValues(alpha: 0.20) : const Color(0xFFFEF3C7), shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Icon(LucideIcons.lightbulb, size: 14.w, color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)),
                        ),
                        Gap.w10,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Why this may be a better option',
                                style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: theme.textPrimary),
                              ),
                              Gap.h4,
                              Text(
                                whyBetter,
                                style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 11.sp, fontWeight: FontWeight.w400, color: theme.textSecondary, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Gap.h12,

                  // 5. Only show nutrition when values were supplied.
                  if (nutrition.hasData)
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: theme.card,
                        borderRadius: BorderRadius.circular(16.w),
                        border: Border.all(color: theme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nutrition Highlights',
                            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 12.sp, fontWeight: FontWeight.w800, color: theme.textPrimary),
                          ),
                          Gap.h10,
                          Text(
                            nutrition.basis ?? 'Portion basis not recorded; values may be estimates.',
                            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, color: theme.textSecondary),
                          ),
                          Gap.h8,
                          Row(
                            children: [
                              Expanded(child: _nutritionItem(context, nutrition.calories?.toString() ?? '—', 'Calories', valueColor: theme.textPrimary)),
                              _nutritionDivider(context),
                              Expanded(child: _nutritionItem(context, nutrition.protein ?? '—', 'Protein', valueColor: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))),
                              _nutritionDivider(context),
                              Expanded(child: _nutritionItem(context, nutrition.totalFat ?? '—', 'Total Fat', valueColor: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706))),
                              _nutritionDivider(context),
                              Expanded(child: _nutritionItem(context, nutrition.fiber ?? '—', 'Fiber', valueColor: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  Gap.h16,

                  // 6. Log This Meal Button & Footer
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          final choice = await showJournalEventSheet(context, title: 'When did you eat this?');
                          if (choice == null) return;
                          final logId = await sl<HistoryFirestoreService>().logMeal(
                            MealLog(
                              items: [alternative.name],
                              notes: alternative.reason ?? 'Better food swap selection',
                              mealType: _currentMealType(),
                              source: 'swap',
                              createdAt: DateTime.now(),
                              occurredAt: choice.occurredAt,
                              occurredAtProvenance: OccurrenceProvenance.user,
                            ),
                          );
                          if (logId == null) throw StateError('Meal log was not persisted');
                          sl<AppStateService>().notifyChatUpdated();
                          unawaited(sl<NotificationService>().scheduleNoMealLoggedReminder());
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logged ${alternative.name} to journal successfully!'), behavior: SnackBarBehavior.floating));
                            context.pop();
                          }
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't log this meal — try again."), behavior: SnackBarBehavior.floating));
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                        foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.w),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100.w)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.utensils, size: 16.w),
                          Gap.w8,
                          Text(
                            'Log This Meal',
                            style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 13.5.sp, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Gap.h8,
                  Center(
                    child: Text(
                      'Only log if you actually eat it.',
                      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, color: theme.textSecondary, fontWeight: FontWeight.w500),
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

IconData _getBenefitIcon(String iconStr) {
  switch (iconStr.toLowerCase()) {
    case 'dumbbell':
    case 'muscle':
      return LucideIcons.dumbbell;
    case 'arrow_down':
    case 'trending_down':
      return LucideIcons.trendingDown;
    case 'leaf':
      return LucideIcons.leaf;
    case 'flame':
      return LucideIcons.flame;
    default:
      return LucideIcons.checkCircle;
  }
}

Widget _nutritionDivider(BuildContext context) => Container(width: 1.w, height: 26.w, color: context.insightTheme.border);

Widget _nutritionItem(BuildContext context, String value, String label, {Color? valueColor}) => Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    Text(
      value,
      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 15.sp, fontWeight: FontWeight.w900, color: valueColor ?? context.insightTheme.textPrimary),
    ),
    Gap.h2,
    Text(
      label,
      style: TextStyle(fontFamily: InsightTheme.fontFamily, fontSize: 10.sp, fontWeight: FontWeight.w500, color: context.insightTheme.textSecondary),
    ),
  ],
);

String _currentMealType() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 11) return 'breakfast';
  if (hour >= 11 && hour < 16) return 'lunch';
  if (hour >= 16 && hour < 21) return 'dinner';
  return 'snack';
}
